#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Samba File Server — Automated Setup Script
#
# Purpose: Install and configure Samba as a file sharing server on
#          Ubuntu 24.04/22.04 LTS with multiple shares, user management,
#          security hardening, and firewall configuration.
#
# Usage:   ./samba-setup.sh [OPTIONS]
#          ./samba-setup.sh --shares "shared,department" --users "user1,user2"
#          ./samba-setup.sh --dry-run --shares "shared"
#
# Requirements:
#   - Ubuntu 24.04 or 22.04 LTS
#   - Root privileges (sudo)
#   - Port 445 available
#   - Sufficient disk space for share directories
#
# Safety notes:
#   - Dry-run mode (--dry-run) prints all actions without executing
#   - Creates timestamped backup of existing smb.conf before changes
#   - Validates config syntax before applying (testparm)
#   - Does NOT modify firewall rules automatically -- use --firewall flag
#
# Tested on: Ubuntu 24.04 LTS, Ubuntu 22.04 LTS
# =============================================================================

DRY_RUN=false
FIREWALL=false
SHARES=""
USERS=""
WORKGROUP="WORKGROUP"
SHARE_BASE="/srv/samba"
SMB_GROUP="smbgroup"
MIN_PROTOCOL="SMB2"
MAX_PROTOCOL="SMB3"
LOG_LEVEL="2"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

usage() {
    cat << 'USAGE'
Usage: samba-setup.sh [OPTIONS]

Required:
  --shares "name1,name2"          Comma-separated share names

Options:
  --users "user1,user2"           Comma-separated Samba users to create
  --workgroup NAME                SMB workgroup (default: WORKGROUP)
  --share-base DIR                Base directory for shares (default: /srv/samba)
  --min-protocol PROTO            Minimum SMB protocol: SMB2|SMB3 (default: SMB2)
  --max-protocol PROTO            Maximum SMB protocol: SMB2|SMB3 (default: SMB3)
  --log-level LEVEL               Samba log level (default: 2)
  --firewall                      Configure ufw rules automatically
  --dry-run                       Print actions without executing
  --help                          Show this help message
USAGE
    exit 0
}

run_or_dry() {
    if [ "$DRY_RUN" = true ]; then
        echo "[dry-run] $*"
    else
        eval "$@"
    fi
}

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --shares)       SHARES="$2"; shift 2 ;;
        --users)        USERS="$2"; shift 2 ;;
        --workgroup)    WORKGROUP="$2"; shift 2 ;;
        --share-base)   SHARE_BASE="$2"; shift 2 ;;
        --min-protocol) MIN_PROTOCOL="$2"; shift 2 ;;
        --max-protocol) MAX_PROTOCOL="$2"; shift 2 ;;
        --log-level)    LOG_LEVEL="$2"; shift 2 ;;
        --firewall)     FIREWALL=true; shift ;;
        --dry-run)      DRY_RUN=true; shift ;;
        --help)         usage ;;
        *)              log_error "Unknown option: $1"; usage ;;
    esac
done

# --- Validation ---
if [ -z "$SHARES" ]; then
    log_error "--shares is required"
    usage
fi

if [ "$(id -u)" -ne 0 ] && [ "$DRY_RUN" = false ]; then
    log_error "This script must be run as root (or use --dry-run)"
    exit 1
fi

# --- Binary checks ---
for cmd in apt-get systemctl; do
    command -v "$cmd" >/dev/null 2>&1 || { log_error "$cmd not found"; exit 1; }
done

# --- Pre-flight ---
log_info "=== Samba File Server Setup ==="
log_info "Shares: $SHARES"
log_info "Users: ${USERS:-none}"
log_info "Workgroup: $WORKGROUP"
log_info "Share base: $SHARE_BASE"
log_info "Protocol: $MIN_PROTOCOL - $MAX_PROTOCOL"
log_info "Dry-run: $DRY_RUN"

# --- Step 1: Install Samba ---
log_info "Step 1/8: Installing Samba..."
command -v smbd >/dev/null 2>&1 && log_info "Samba already installed: $(smbd --version 2>&1 | head -1)" || run_or_dry "apt-get update && apt-get install -y samba samba-common-bin smbclient"

# --- Step 2: Backup existing config ---
log_info "Step 2/8: Backing up existing configuration..."
if [ -f /etc/samba/smb.conf ]; then
    BACKUP="/etc/samba/smb.conf.bak.$(date +%Y%m%d%H%M%S)"
    run_or_dry "cp /etc/samba/smb.conf '$BACKUP'"
    log_info "Backup created: $BACKUP"
fi

# --- Step 3: Create share directories and groups ---
log_info "Step 3/8: Creating share directories..."
run_or_dry "groupadd -f '$SMB_GROUP'"

IFS=',' read -ra SHARE_ARRAY <<< "$SHARES"
for share in "${SHARE_ARRAY[@]}"; do
    share=$(echo "$share" | xargs)
    SHARE_DIR="${SHARE_BASE}/${share}"

    if [ "$DRY_RUN" = true ]; then
        echo "[dry-run] mkdir -p '$SHARE_DIR'"
        echo "[dry-run] chown root:'$SMB_GROUP' '$SHARE_DIR'"
        echo "[dry-run] chmod 2770 '$SHARE_DIR'"
    else
        mkdir -p "$SHARE_DIR"
        chown root:"$SMB_GROUP" "$SHARE_DIR"
        chmod 2770 "$SHARE_DIR"
        log_info "Created share directory: $SHARE_DIR"
    fi
done

# --- Step 4: Generate smb.conf ---
log_info "Step 4/8: Generating Samba configuration..."

SHARE_CONFIGS=""
for share in "${SHARE_ARRAY[@]}"; do
    share=$(echo "$share" | xargs)
    SHARE_DIR="${SHARE_BASE}/${share}"

    SHARE_CONFIGS="${SHARE_CONFIGS}
[${share}]
   path = ${SHARE_DIR}
   browseable = yes
   read only = no
   valid users = @${SMB_GROUP}
   force group = ${SMB_GROUP}
   create mask = 0660
   directory mask = 2770
   force create mode = 0660
   force directory mode = 2770
"
done

CONFIG=$(cat << SMBCONF
[global]
   workgroup = ${WORKGROUP}
   server string = Samba Server %v
   server role = standalone server
   security = user
   map to guest = never
   log file = /var/log/samba/log.%m
   max log size = 5000
   log level = ${LOG_LEVEL}
   server min protocol = ${MIN_PROTOCOL}
   server max protocol = ${MAX_PROTOCOL}
   smb encrypt = desired
   socket options = TCP_NODELAY IPTOS_LOWDELAY
   read raw = yes
   write raw = yes
   max xmit = 65535
   dead time = 15
   restrict anonymous = 2
   disable netbios = yes
   smb ports = 445
   load printers = no
   printing = bsd
   printcap name = /dev/null
${SHARE_CONFIGS}
SMBCONF
)

if [ "$DRY_RUN" = true ]; then
    echo "[dry-run] Would write /etc/samba/smb.conf:"
    echo "$CONFIG"
else
    echo "$CONFIG" > /etc/samba/smb.conf
fi

# --- Step 5: Create users ---
log_info "Step 5/8: Creating Samba users..."
if [ -n "$USERS" ]; then
    IFS=',' read -ra USER_ARRAY <<< "$USERS"
    for user in "${USER_ARRAY[@]}"; do
        user=$(echo "$user" | xargs)

        if [ "$DRY_RUN" = true ]; then
            echo "[dry-run] useradd -M -s /usr/sbin/nologin '$user'"
            echo "[dry-run] usermod -aG '$SMB_GROUP' '$user'"
            echo "[dry-run] smbpasswd -a '$user'"
        else
            useradd -M -s /usr/sbin/nologin "$user" 2>/dev/null || true
            usermod -aG "$SMB_GROUP" "$user"

            PASS=$(openssl rand -base64 12)
            echo "$user:$PASS" | chpasswd
            echo "$PASS" | smbpasswd -a "$user" -s
            smbpasswd -e "$user"

            log_info "Created user: $user (password: $PASS)"
            log_warn "Save this password — it will not be shown again"
        fi
    done
else
    log_info "No users specified — skipping user creation"
fi

# --- Step 6: Validate configuration ---
log_info "Step 6/8: Validating Samba configuration..."
if [ "$DRY_RUN" = true ]; then
    echo "[dry-run] Would run: testparm -s /etc/samba/smb.conf"
else
    testparm -s /etc/samba/smb.conf 2>&1 | head -5 || { log_error "Configuration validation failed"; exit 1; }
    log_info "Configuration is valid"
fi

# --- Step 7: Restart services ---
log_info "Step 7/8: Restarting Samba services..."
if [ "$DRY_RUN" = true ]; then
    echo "[dry-run] Would run: systemctl restart smbd nmbd"
    echo "[dry-run] Would run: systemctl enable smbd nmbd"
else
    systemctl restart smbd nmbd
    systemctl enable smbd nmbd
    log_info "Samba services started and enabled"
fi

# --- Step 8: Firewall (optional) ---
log_info "Step 8/8: Firewall configuration..."
if [ "$FIREWALL" = true ]; then
    command -v ufw >/dev/null 2>&1 || { log_warn "ufw not found, skipping firewall"; }
    run_or_dry "ufw allow Samba comment 'Samba file sharing'"
    run_or_dry "ufw reload"
    log_info "Firewall rules applied"
else
    log_info "Skipping firewall — add rules manually: ufw allow Samba"
fi

# --- Summary ---
SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "<server-ip>")
log_info "=== Setup Complete ==="
log_info "Server: $SERVER_IP"
log_info "Shares:"
for share in "${SHARE_ARRAY[@]}"; do
    share=$(echo "$share" | xargs)
    log_info "  \\\\\\\\${SERVER_IP}\\\\${share}  (${SHARE_BASE}/${share})"
done
log_info ""
log_info "Test:  smbclient //${SERVER_IP}/${SHARE_ARRAY[0]} -U <username>"
log_info "Linux: mount -t cifs //${SERVER_IP}/${SHARE_ARRAY[0]} /mnt/share -o username=<user>"
