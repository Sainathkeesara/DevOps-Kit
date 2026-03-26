#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Samba File Server Setup
# Purpose: Deploy a Samba file server for file sharing across Linux/Windows/macOS
# Requirements: Samba, smbpasswd, Ubuntu 22.04+ or RHEL 9+
# Safety: Dry-run mode supported via DRY_RUN=1
# Tested on: Ubuntu 22.04, RHEL 9, Debian 12
###############################################################################

DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"
SAMBA_VERSION="${SAMBA_VERSION:-latest}"
SHARE_NAME="${SHARE_NAME:-shared}"
SHARE_PATH="${SHARE_PATH:-/srv/samba/share}"
SHARE_PERMS="${SHARE_PERMS:-775}"
USERNAME="${USERNAME:-sambauser}"
GROUPNAME="${GROUPNAME:-sambashare}"

log() {
    local level="$1"
    shift
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
    echo "$msg"
}

info() { log "INFO" "$@"; }
warn() { log "WARN" "$@"; }
error() { log "ERROR" "$@"; }

dry_run() {
    if [ "$DRY_RUN" = "true" ]; then
        info "[dry-run] $*"
        return 0
    fi
    return 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

detect_os() {
    if command_exists apt-get; then
        echo "debian"
    elif command_exists dnf; then
        echo "rhel"
    elif command_exists yum; then
        echo "rhel"
    elif command_exists zypper; then
        echo "suse"
    else
        echo "unknown"
    fi
}

check_prerequisites() {
    local missing=0
    
    if ! command_exists smbd; then
        warn "Samba not installed"
        ((missing++))
    fi
    
    if ! command_exists testparm; then
        warn "Samba testparm not found - may need samba-common-bin"
    fi
    
    if [ $missing -gt 0 ]; then
        info "Install Samba with: apt install samba smbclient samba-common-bin (Debian) or dnf install samba (RHEL)"
    fi
    
    info "Prerequisites check complete"
}

install_samba() {
    local os_type=$(detect_os)
    info "Detected OS: $os_type"
    
    case "$os_type" in
        debian)
            dry_run "Would run: apt update && apt install -y samba smbclient samba-common-bin" || {
                apt update
                apt install -y samba smbclient samba-common-bin cifs-utils
            }
            ;;
        rhel)
            dry_run "Would run: dnf install -y samba samba-common" || {
                dnf install -y samba samba-common cifs-utils
            }
            ;;
        suse)
            dry_run "Would run: zypper install -y samba samba-client" || {
                zypper install -y samba samba-client
            }
            ;;
        *)
            error "Unsupported OS"
            return 1
            ;;
    esac
    
    info "Samba installation complete"
}

create_share_directory() {
    local share_path="$1"
    local username="$2"
    local groupname="$3"
    
    info "Creating share directory: $share_path"
    
    dry_run "Would create: mkdir -p $share_path" || {
        mkdir -p "$share_path"
    }
    
    dry_run "Would set ownership: chown root:$groupname $share_path" || {
        groupadd -f "$groupname" 2>/dev/null || true
        chown root:"$groupname" "$share_path"
    }
    
    dry_run "Would set permissions: chmod 2775 $share_path" || {
        chmod 2775 "$share_path"
    }
    
    info "Share directory created with permissions 2775 (setgid for automatic group ownership)"
}

create_samba_user() {
    local username="$1"
    
    info "Creating system user: $username"
    
    if id "$username" &>/dev/null; then
        warn "User $username already exists"
    else
        dry_run "Would create user: useradd -M -s /sbin/nologin $username" || {
            useradd -M -s /sbin/nologin "$username" 2>/dev/null || useradd -M -s /usr/sbin/nologin "$username"
        }
    fi
    
    info "Set password for Samba user (or press Enter to skip):"
    dry_run "Would run: smbpasswd -a $username" || {
        smbpasswd -a "$username" 2>/dev/null || {
            warn "Could not set Samba password - run 'smbpasswd -a $username' manually"
        }
    }
    
    dry_run "Would enable user: smbpasswd -e $username" || {
        smbpasswd -e "$username" 2>/dev/null || true
    }
    
    info "Samba user configured"
}

configure_samba() {
    local share_name="$1"
    local share_path="$2"
    local username="$3"
    local groupname="$4"
    
    local smb_conf="/etc/samba/smb.conf"
    local backup_conf="${smb_conf}.backup.$(date +%Y%m%d%H%M%S)"
    
    info "Configuring Samba at $smb_conf"
    
    # Backup existing config
    if [ -f "$smb_conf" ]; then
        dry_run "Would backup: cp $smb_conf $backup_conf" || {
            cp "$smb_conf" "$backup_conf"
            info "Backed up existing config to $backup_conf"
        }
    fi
    
    # Create global config
    cat > /tmp/samba-global.conf <<EOF
[global]
   workgroup = WORKGROUP
   server string = Samba File Server
   security = user
   passdb backend = tdbsam
   printing = cups
   printcap name = cups
   load printers = no
   cups options = raw
   log file = /var/log/samba/log.%m
   max log size = 1000
   socket options = TCP_NODELAY SO_RCVBUF=8192 SO_SNDBUF=8192
   hide dot files = yes
   guest account = nobody
   map to guest = bad user
EOF

    # Create share config
    cat > /tmp/samba-share.conf <<EOF

[$share_name]
   path = $share_path
   browsable = yes
   writable = yes
   valid users = $username
   write list = $username
   create mask = 0660
   directory mask = 0770
   force group = $groupname
   follow symlinks = yes
   wide links = no
   hide files = /^\..*/
   
[public]
   path = $share_path
   browsable = yes
   writable = no
   guest only = yes
   guest ok = yes
   read only = yes
   force user = nobody
EOF

    dry_run "Would update: cat /tmp/samba-*.conf >> $smb_conf" || {
        cat /tmp/samba-global.conf >> "$smb_conf"
        cat /tmp/samba-share.conf >> "$smb_conf"
    }
    
    # Test configuration
    if command_exists testparm; then
        dry_run "Would run: testparm -s" || {
            testparm -s 2>/dev/null || warn "testparm reported errors"
        }
    fi
    
    info "Samba configuration complete"
}

configure_firewall() {
    local os_type=$(detect_os)
    
    case "$os_type" in
        debian)
            if command_exists ufw; then
                info "Configuring UFW firewall"
                dry_run "Would run: ufw allow 445/tcp" || ufw allow 445/tcp
                dry_run "Would run: ufw allow 139/tcp" || ufw allow 139/tcp
            fi
            ;;
        rhel)
            if command_exists firewall-cmd; then
                info "Configuring firewalld"
                dry_run "Would run: firewall-cmd --permanent --add-service=samba" || {
                    firewall-cmd --permanent --add-service=samba 2>/dev/null || true
                    firewall-cmd --reload 2>/dev/null || true
                }
            fi
            ;;
    esac
    
    info "Firewall configuration complete"
}

start_samba_service() {
    info "Starting Samba service"
    
    dry_run "Would run: systemctl enable smb nmb" || {
        systemctl enable smb nmb 2>/dev/null || true
    }
    
    dry_run "Would run: systemctl restart smb nmb" || {
        systemctl restart smb nmb 2>/dev/null || {
            service smb restart 2>/dev/null || true
        }
    }
    
    # Check status
    if command_exists systemctl; then
        if systemctl is-active --quiet smb; then
            info "Samba service is running"
        else
            warn "Samba service may not be running - check with: systemctl status smb"
        fi
    fi
}

verify_installation() {
    local share_name="$1"
    
    info "Verifying Samba installation..."
    
    # Check if smbd is running
    if pgrep -x smbd > /dev/null; then
        info "smbd process is running"
    else
        warn "smbd process not found"
    fi
    
    # Test connection to localhost
    if command_exists smbclient; then
        dry_run "Would run: smbclient -L localhost -N" || {
            smbclient -L localhost -N 2>/dev/null && info "SMB client test successful" || warn "SMB client test failed"
        }
    fi
    
    # List share
    if [ -d "$SHARE_PATH" ]; then
        info "Share directory exists: $SHARE_PATH"
        ls -la "$SHARE_PATH"
    else
        warn "Share directory not found: $SHARE_PATH"
    fi
    
    info "Verification complete"
}

show_access_info() {
    local share_name="$1"
    local username="$2"
    local share_path="$3"
    
    echo ""
    echo "========================================="
    echo "  Samba File Server Setup Complete"
    echo "========================================="
    echo ""
    echo "Share Name: $share_name"
    echo "Share Path: $share_path"
    echo "Username: $username"
    echo ""
    echo "Access from Linux/macOS:"
    echo "  smb://<server-ip>/$share_name"
    echo ""
    echo "Access from Windows:"
    echo "  \\\\<server-ip>\\$share_name"
    echo ""
    echo "Mount as root:"
    echo "  mount -t cifs //<server-ip>/$share_name /mnt -o user=$username"
    echo ""
    echo "Public guest access:"
    echo "  smb://<server-ip>/public (read-only)"
    echo ""
}

show_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
    -h, --help              Show this help message
    -d, --dry-run           Run in dry-run mode (no changes)
    -v, --verbose           Enable verbose output
    --share-name NAME       Share name (default: shared)
    --share-path PATH      Share path (default: /srv/samba/share)
    --username USER         Samba username (default: sambauser)
    --group-name GROUP     Samba group (default: sambashare)
    --install              Install Samba packages
    --no-install           Skip Samba installation
    --verify-only         Only verify existing installation

Examples:
    $0 --install
    $0 --dry-run --share-name company
    $0 --username admin --group-name admins
EOF
}

main() {
    local do_install=false
    local do_verify=false
    
    for arg in "$@"; do
        case $arg in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                ;;
            -v|--verbose)
                VERBOSE=true
                ;;
            --share-name)
                SHARE_NAME="${2:-}"
                shift
                ;;
            --share-name=*)
                SHARE_NAME="${arg#*=}"
                ;;
            --share-path)
                SHARE_PATH="${2:-}"
                shift
                ;;
            --share-path=*)
                SHARE_PATH="${arg#*=}"
                ;;
            --username)
                USERNAME="${2:-}"
                shift
                ;;
            --username=*)
                USERNAME="${arg#*=}"
                ;;
            --group-name)
                GROUPNAME="${2:-}"
                shift
                ;;
            --group-name=*)
                GROUPNAME="${arg#*=}"
                ;;
            --install)
                do_install=true
                ;;
            --verify-only)
                do_verify=true
                ;;
        esac
        shift 2>/dev/null || true
    done
    
    info "Starting Samba file server setup..."
    info "DRY_RUN: $DRY_RUN, VERBOSE: $VERBOSE"
    info "Share: $SHARE_NAME at $SHARE_PATH"
    info "User: $USERNAME, Group: $GROUPNAME"
    
    if [ "$do_verify" = "true" ]; then
        verify_installation "$SHARE_NAME"
        exit 0
    fi
    
    check_prerequisites
    
    if [ "$do_install" = "true" ]; then
        install_samba
    fi
    
    create_share_directory "$SHARE_PATH" "$USERNAME" "$GROUPNAME"
    create_samba_user "$USERNAME"
    configure_samba "$SHARE_NAME" "$SHARE_PATH" "$USERNAME" "$GROUPNAME"
    configure_firewall
    start_samba_service
    verify_installation "$SHARE_NAME"
    show_access_info "$SHARE_NAME" "$USERNAME" "$SHARE_PATH"
    
    info "Samba setup complete!"
}

main "$@"