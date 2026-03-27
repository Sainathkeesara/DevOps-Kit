# Project: Enterprise Samba File Sharing Platform

## Purpose

Walk through building a production-grade enterprise file sharing platform on Linux using Samba. This project covers departmental shares, home directories, guest access, Active Directory integration, automated backups, monitoring, and security hardening — all on a single Ubuntu 24.04 server.

## When to Use

Use this project when you need to:
- Replace a Windows file server with a Linux-based Samba solution
- Provide departmental file shares with ACL-based access control
- Integrate Linux file sharing into an existing Active Directory domain
- Set up automated backup and monitoring for a production file server
- Harden a Samba deployment against common attack vectors

## Prerequisites

### System Requirements
- **OS**: Ubuntu 24.04 LTS (primary) or RHEL 9+ (adapt commands)
- **CPU**: 2+ cores
- **RAM**: 4GB minimum, 8GB recommended
- **Disk**: 100GB+ for shares, separate disk for backups
- **Network**: Static IP, DNS resolution working

### Software Requirements
- Samba 4.19+ (`smbd`, `nmbd`, `winbindd`)
- `smbclient`, `cifs-utils`, `acl`, `attr`
- `rsync` for backups
- `prometheus-node-exporter` for monitoring
- `realmd` and `sssd` for AD integration (Phase 5 only)

### Knowledge Prerequisites
- Linux system administration (users, groups, permissions, systemd)
- Basic networking (DNS, firewall, ports)
- Understanding of SMB/CIFS protocol basics
- Active Directory basics (for Phase 5 only)

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                  Samba Server (Ubuntu 24.04)         │
│                                                     │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │ Departmental │  │   Home       │  │   Guest    │ │
│  │   Shares     │  │  Directories │  │  Public    │ │
│  │  /srv/samba/ │  │  /home/      │  │  /srv/pub/ │ │
│  │  dept/       │  │  %U/         │  │            │ │
│  └──────┬───────┘  └──────┬───────┘  └─────┬──────┘ │
│         │                 │                 │        │
│  ┌──────┴─────────────────┴─────────────────┴──────┐ │
│  │              Samba (smbd) + Winbind              │ │
│  │              Security: user + AD auth            │ │
│  └──────────────────────┬──────────────────────────┘ │
│                         │                            │
│  ┌──────────────────────┴──────────────────────────┐ │
│  │  Backup (rsync + cron) | Monitor (node-exporter)│ │
│  │  ACL (setfacl/getfacl) | Firewall (ufw)         │ │
│  └──────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
        │              │              │
   ┌────┴───┐    ┌────┴───┐    ┌────┴───┐
   │ Linux  │    │Windows │    │ macOS  │
   │Clients │    │Clients │    │Clients │
   └────────┘    └────────┘    └────────┘
```

## Phases

| Phase | Description | Time |
|-------|-------------|------|
| 1 | Base Samba server with departmental shares | 45 min |
| 2 | Home directory automation and user management | 30 min |
| 3 | Guest and public share with read-only access | 20 min |
| 4 | ACL-based fine-grained access control | 40 min |
| 5 | Active Directory integration (optional) | 60 min |
| 6 | Automated backups with rsync | 30 min |
| 7 | Monitoring and alerting | 30 min |
| 8 | Security hardening | 30 min |
| 9 | Client connection testing | 20 min |
| 10 | Disaster recovery drill | 20 min |

---

## Phase 1: Base Samba Server with Departmental Shares

### Step 1.1: Install Samba packages

```bash
sudo apt update
sudo apt install -y samba smbclient samba-common-bin cifs-utils acl attr winbind
```

Verify:
```bash
smbd --version
# Expected: Version 4.19.x or later
```

### Step 1.2: Create departmental directory structure

```bash
# Create base share directories
sudo mkdir -p /srv/samba/dept/{engineering,marketing,finance,hr,shared}

# Set ownership — each department gets its own group
sudo groupadd -f sgrp-engineering
sudo groupadd -f sgrp-marketing
sudo groupadd -f sgrp-finance
sudo groupadd -f sgrp-hr
sudo groupadd -f sgrp-shared

sudo chown root:sgrp-engineering /srv/samba/dept/engineering
sudo chown root:sgrp-marketing   /srv/samba/dept/marketing
sudo chown root:sgrp-finance     /srv/samba/dept/finance
sudo chown root:sgrp-hr          /srv/samba/dept/hr
sudo chown root:sgrp-shared      /srv/samba/dept/shared

# Set permissions: group read/write, setgid for inheritance
sudo chmod 2770 /srv/samba/dept/{engineering,marketing,finance,hr}
sudo chmod 2775 /srv/samba/dept/shared
```

### Step 1.3: Backup existing smb.conf and create new configuration

```bash
# Backup
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.backup.$(date +%Y%m%d%H%M%S)

# Write new global configuration
sudo tee /etc/samba/smb.conf > /dev/null <<'CONF'
[global]
   workgroup = COMPANY
   server string = Enterprise File Server
   security = user
   passdb backend = tdbsam

   # Logging
   log file = /var/log/samba/log.%m
   max log size = 5000
   log level = 1

   # Performance
   socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=524288 SO_SNDBUF=524288
   read raw = yes
   write raw = yes
   max xmit = 65535
   dead time = 15
   getwd cache = yes

   # Security
   server min protocol = SMB2
   smb encrypt = desired
   restrict anonymous = 2
   map to guest = never
   guest account = nobody

   # Printing disabled
   load printers = no
   printing = cups
   printcap name = cups

   # VFS modules
   vfs objects = acl_xattr
   map acl inherit = yes
   store dos attributes = yes

[engineering]
   path = /srv/samba/dept/engineering
   browsable = yes
   writable = yes
   valid users = @sgrp-engineering
   write list = @sgrp-engineering
   read list = @sgrp-shared
   create mask = 0660
   directory mask = 2770
   force group = sgrp-engineering
   inherit permissions = yes
   veto files = /*.exe/*.bat/*.cmd/

[marketing]
   path = /srv/samba/dept/marketing
   browsable = yes
   writable = yes
   valid users = @sgrp-marketing
   write list = @sgrp-marketing
   create mask = 0660
   directory mask = 2770
   force group = sgrp-marketing
   inherit permissions = yes

[finance]
   path = /srv/samba/dept/finance
   browsable = yes
   writable = yes
   valid users = @sgrp-finance
   write list = @sgrp-finance
   create mask = 0660
   directory mask = 2770
   force group = sgrp-finance
   inherit permissions = yes
   # Extra security for financial data
   hide unreadable = yes

[hr]
   path = /srv/samba/dept/hr
   browsable = yes
   writable = yes
   valid users = @sgrp-hr
   write list = @sgrp-hr
   create mask = 0660
   directory mask = 2770
   force group = sgrp-hr
   inherit permissions = yes
   hide unreadable = yes

[shared]
   path = /srv/samba/dept/shared
   browsable = yes
   writable = yes
   valid users = @sgrp-shared @sgrp-engineering @sgrp-marketing @sgrp-finance @sgrp-hr
   create mask = 0664
   directory mask = 2775
   force group = sgrp-shared
   inherit permissions = yes
CONF
```

### Step 1.4: Validate and start

```bash
# Test configuration syntax
testparm -s

# Start services
sudo systemctl enable smbd nmbd
sudo systemctl restart smbd nmbd

# Verify
sudo systemctl status smbd
sudo smbclient -L localhost -N
```

---

## Phase 2: Home Directory Automation

### Step 2.1: Enable Samba home directory shares

Append to `/etc/samba/smb.conf`:

```bash
sudo tee -a /etc/samba/smb.conf > /dev/null <<'CONF'

[homes]
   comment = Home Directories
   browsable = no
   writable = yes
   valid users = %S
   create mask = 0600
   directory mask = 0700
   root preexec = /usr/local/bin/samba-mkhome.sh %U
CONF
```

### Step 2.2: Create home directory auto-creation script

```bash
sudo tee /usr/local/bin/samba-mkhome.sh > /dev/null <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

# Purpose: Auto-create Samba home directory on first login
# Usage: Called by Samba root preexec — samba-mkhome.sh <username>

SAMBA_HOME_BASE="/srv/samba/homes"
USERNAME="$1"

if [ -z "$USERNAME" ]; then
    echo "Usage: $0 <username>" >&2
    exit 1
fi

USER_HOME="${SAMBA_HOME_BASE}/${USERNAME}"

if [ ! -d "$USER_HOME" ]; then
    mkdir -p "$USER_HOME"
    chown "$USERNAME":"$USERNAME" "$USER_HOME"
    chmod 0700 "$USER_HOME"
    logger -t samba-mkhome "Created home directory for $USERNAME"
fi
SCRIPT

sudo chmod +x /usr/local/bin/samba-mkhome.sh
```

### Step 2.3: Create sample users

```bash
# Create users with no shell access
for user in alice bob charlie diana; do
    sudo useradd -M -s /sbin/nologin "$user" 2>/dev/null || true
    echo -e "ChangeMe123!\nChangeMe123!" | sudo smbpasswd -a -s "$user"
    echo "Created Samba user: $user"
done

# Assign to departments
sudo usermod -aG sgrp-engineering alice
sudo usermod -aG sgrp-engineering bob
sudo usermod -aG sgrp-marketing charlie
sudo usermod -aG sgrp-finance diana
sudo usermod -aG sgrp-shared alice bob charlie diana
```

### Step 2.4: Test home directory access

```bash
# From the server itself
smbclient //localhost/alice -U alice%ChangeMe123! -c 'ls'
```

---

## Phase 3: Guest and Public Share

### Step 3.1: Create public share directory

```bash
sudo mkdir -p /srv/samba/public
sudo chown nobody:nogroup /srv/samba/public
sudo chmod 0755 /srv/samba/public
```

### Step 3.2: Add public share to smb.conf

Append before the `[homes]` section:

```bash
# Insert public share block (edit /etc/samba/smb.conf manually)
# Or use this approach to insert before [homes]:
sudo sed -i '/^\[homes\]/i \
[public]\
   comment = Public Share\
   path = /srv/samba/public\
   browsable = yes\
   writable = no\
   guest ok = yes\
   guest only = yes\
   read only = yes\
   force user = nobody\
   create mask = 0644\
   directory mask = 0755\
' /etc/samba/smb.conf
```

### Step 3.3: Enable guest access in global section

```bash
sudo sed -i 's/^   map to guest = never/   map to guest = bad user/' /etc/samba/smb.conf
sudo sed -i 's/^   guest account = nobody/#   guest account = nobody/' /etc/samba/smb.conf
```

### Step 3.4: Validate and restart

```bash
testparm -s
sudo systemctl restart smbd
smbclient -L localhost -N
```

---

## Phase 4: ACL-Based Fine-Grained Access Control

### Step 4.1: Install and verify ACL support

```bash
sudo apt install -y acl

# Verify filesystem supports ACLs
mount | grep -o 'acl' || {
    echo "ACL not mounted — adding to fstab"
    # For ext4: add 'acl' to mount options in /etc/fstab
    # For XFS: ACLs are enabled by default
}
```

### Step 4.2: Set up cross-department read access

```bash
# Engineering lead can read finance reports
sudo setfacl -m g:sgrp-engineering:rx /srv/samba/dept/finance/reports
sudo setfacl -m d:g:sgrp-engineering:rx /srv/samba/dept/finance/reports

# HR can read all department directories (audit access)
for dept in engineering marketing finance; do
    sudo setfacl -m g:sgrp-hr:rx /srv/samba/dept/$dept
    sudo setfacl -m d:g:sgrp-hr:rx /srv/samba/dept/$dept
done
```

### Step 4.3: Create restricted subdirectories

```bash
# Finance confidential — only finance manager
sudo mkdir -p /srv/samba/dept/finance/confidential
sudo chown root:sgrp-finance /srv/samba/dept/finance/confidential
sudo chmod 0770 /srv/samba/dept/finance/confidential

# Remove inherited ACLs and set specific access
sudo setfacl -b /srv/samba/dept/finance/confidential
sudo setfacl -m g:sgrp-finance:rwx /srv/samba/dept/finance/confidential
sudo setfacl -m d:g:sgrp-finance:rwx /srv/samba/dept/finance/confidential
```

### Step 4.4: Verify ACLs

```bash
# Check ACLs on a directory
getfacl /srv/samba/dept/finance

# Expected output includes:
# group:sgrp-finance:rwx
# group:sgrp-hr:r-x (if set)
# default:group:sgrp-finance:rwx
```

---

## Phase 5: Active Directory Integration (Optional)

> **Skip this phase if you do not have an Active Directory domain controller.**

### Step 5.1: Join the domain

```bash
sudo apt install -y realmd sssd sssd-tools libnss-sss libpam-sss adcli packagekit

# Discover the domain
sudo realm discover company.local

# Join (requires domain admin credentials)
sudo realm join --user=admin company.local

# Verify
sudo realm list
```

### Step 5.2: Configure Samba for AD authentication

Add to `/etc/samba/smb.conf` `[global]` section:

```
   security = ADS
   realm = COMPANY.LOCAL
   workgroup = COMPANY

   idmap config COMPANY : backend = rid
   idmap config COMPANY : range = 10000-999999
   idmap config * : backend = tdb
   idmap config * : range = 3000-7999

   winbind use default domain = yes
   winbind enum users = yes
   winbind enum groups = yes
   template shell = /sbin/nologin
   template homedir = /srv/samba/homes/%U
```

### Step 5.3: Update NSS and PAM

```bash
# Enable winbind in NSS
sudo sed -i 's/^passwd:.*/passwd:         compat systemd sss/' /etc/nsswitch.conf
sudo sed -i 's/^group:.*/group:          compat systemd sss/' /etc/nsswitch.conf

# Restart services
sudo systemctl restart smbd winbind sssd
```

### Step 5.4: Test AD user access

```bash
# List AD users
wbinfo -u

# List AD groups
wbinfo -g

# Test authentication
wbinfo -a COMPANY\\aduser
```

---

## Phase 6: Automated Backups

### Step 6.1: Create backup script

```bash
sudo tee /usr/local/bin/samba-backup.sh > /dev/null <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Samba Share Backup
# Purpose: Incremental backup of all Samba shares using rsync
# Requirements: rsync, /backup/samba mounted or available
# Safety: Dry-run mode via DRY_RUN=true
# Tested on: Ubuntu 24.04
###############################################################################

DRY_RUN="${DRY_RUN:-false}"
BACKUP_BASE="/backup/samba"
SHARE_BASE="/srv/samba"
RETENTION_DAYS=30
LOG_FILE="/var/log/samba/backup.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

# Binary checks
command -v rsync >/dev/null 2>&1 || { log "ERROR: rsync not found"; exit 1; }

# Ensure backup directory exists
mkdir -p "$BACKUP_BASE"/{dept,homes,public}

# Rsync options
RSYNC_OPTS=(-a --delete --stats --human-readable)

backup_share() {
    local src="$1"
    local dst="$2"
    local name="$3"

    if [ ! -d "$src" ]; then
        log "WARN: Source $src does not exist — skipping"
        return 0
    fi

    if [ "$DRY_RUN" = "true" ]; then
        log "[dry-run] rsync ${RSYNC_OPTS[*]} $src/ $dst/"
        rsync "${RSYNC_OPTS[@]}" --dry-run "$src/" "$dst/" >> "$LOG_FILE" 2>&1
    else
        log "Backing up $name: $src -> $dst"
        rsync "${RSYNC_OPTS[@]}" "$src/" "$dst/" >> "$LOG_FILE" 2>&1
        log "Completed: $name"
    fi
}

log "=== Samba backup started ==="

# Backup departmental shares
for dept_dir in "$SHARE_BASE"/dept/*/; do
    dept_name=$(basename "$dept_dir")
    backup_share "$dept_dir" "$BACKUP_BASE/dept/$dept_name" "dept/$dept_name"
done

# Backup home directories
backup_share "$SHARE_BASE/homes" "$BACKUP_BASE/homes" "homes"

# Backup public share
backup_share "$SHARE_BASE/public" "$BACKUP_BASE/public" "public"

# Cleanup old backups (retention)
if [ "$DRY_RUN" = "false" ]; then
    find "$BACKUP_BASE" -type f -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
    log "Cleaned backups older than $RETENTION_DAYS days"
fi

log "=== Samba backup completed ==="
SCRIPT

sudo chmod +x /usr/local/bin/samba-backup.sh
```

### Step 6.2: Schedule with cron

```bash
# Add cron job — run daily at 2 AM
echo '0 2 * * * root /usr/local/bin/samba-backup.sh >> /var/log/samba/backup.log 2>&1' | \
    sudo tee /etc/cron.d/samba-backup

sudo chmod 0644 /etc/cron.d/samba-backup
```

### Step 6.3: Test backup

```bash
# Dry-run first
sudo DRY_RUN=true /usr/local/bin/samba-backup.sh

# Actual run
sudo /usr/local/bin/samba-backup.sh

# Verify
ls -la /backup/samba/dept/
```

---

## Phase 7: Monitoring and Alerting

### Step 7.1: Create Samba metrics exporter script

```bash
sudo tee /usr/local/bin/samba-metrics.sh > /dev/null <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

# Purpose: Export Samba metrics for Prometheus node-exporter textfile collector
# Output: /var/lib/node_exporter/textfile_collector/samba.prom

OUTPUT="/var/lib/node_exporter/textfile_collector/samba.prom"
TMP="${OUTPUT}.tmp"

mkdir -p "$(dirname "$OUTPUT")"

{
    echo "# HELP samba_active_sessions Number of active Samba sessions"
    echo "# TYPE samba_active_sessions gauge"
    SESSIONS=$(smbstatus -b 2>/dev/null | grep -c "^[0-9]" || echo 0)
    echo "samba_active_sessions ${SESSIONS}"

    echo "# HELP samba_active_shares Number of active share connections"
    echo "# TYPE samba_active_shares gauge"
    SHARES=$(smbstatus -S 2>/dev/null | grep -c "^[0-9]" || echo 0)
    echo "samba_active_shares ${SHARES}"

    echo "# HELP samba_smbd_up Whether smbd is running"
    echo "# TYPE samba_smbd_up gauge"
    if pgrep -x smbd > /dev/null; then
        echo "samba_smbd_up 1"
    else
        echo "samba_smbd_up 0"
    fi

    echo "# HELP samba_share_disk_bytes Disk usage per share"
    echo "# TYPE samba_share_disk_bytes gauge"
    for share_dir in /srv/samba/dept/*/ /srv/samba/homes /srv/samba/public; do
        [ -d "$share_dir" ] || continue
        SHARE_NAME=$(basename "$share_dir")
        BYTES=$(du -sb "$share_dir" 2>/dev/null | awk '{print $1}')
        echo "samba_share_disk_bytes{share=\"${SHARE_NAME}\"} ${BYTES:-0}"
    done
} > "$TMP"

mv "$TMP" "$OUTPUT"
SCRIPT

sudo chmod +x /usr/local/bin/samba-metrics.sh
```

### Step 7.2: Schedule metrics collection

```bash
# Run every minute via cron
echo '* * * * * root /usr/local/bin/samba-metrics.sh 2>/dev/null' | \
    sudo tee /etc/cron.d/samba-metrics
```

### Step 7.3: Create Samba health check script

```bash
sudo tee /usr/local/bin/samba-healthcheck.sh > /dev/null <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

# Purpose: Samba service health check — exit 0 healthy, exit 1 unhealthy
# Usage: /usr/local/bin/samba-healthcheck.sh

ERRORS=0

# Check smbd process
if ! pgrep -x smbd > /dev/null; then
    echo "CRITICAL: smbd not running"
    ((ERRORS++))
fi

# Check config validity
if ! testparm -s > /dev/null 2>&1; then
    echo "CRITICAL: smb.conf has errors"
    ((ERRORS++))
fi

# Check share directories exist
for share_dir in /srv/samba/dept/*/; do
    [ -d "$share_dir" ] || { echo "WARN: Missing $share_dir"; ((ERRORS++)); }
done

# Check disk space (warn at 90%)
USAGE=$(df /srv/samba --output=pcent | tail -1 | tr -d '% ')
if [ "$USAGE" -ge 90 ]; then
    echo "WARN: Disk usage at ${USAGE}%"
    ((ERRORS++))
fi

if [ "$ERRORS" -gt 0 ]; then
    echo "UNHEALTHY: $ERRORS error(s)"
    exit 1
fi

echo "HEALTHY"
exit 0
SCRIPT

sudo chmod +x /usr/local/bin/samba-healthcheck.sh
```

### Step 7.4: Test monitoring

```bash
# Run metrics
sudo /usr/local/bin/samba-metrics.sh
cat /var/lib/node_exporter/textfile_collector/samba.prom

# Run health check
/usr/local/bin/samba-healthcheck.sh
echo "Exit code: $?"
```

---

## Phase 8: Security Hardening

### Step 8.1: Firewall configuration

```bash
# UFW rules
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.1.0/24 to any port 445 proto tcp comment "SMB"
sudo ufw allow from 192.168.1.0/24 to any port 139 proto tcp comment "NetBIOS"
sudo ufw allow ssh
sudo ufw --force enable

# Verify
sudo ufw status verbose
```

### Step 8.2: Samba security settings

Add to `[global]` in `/etc/samba/smb.conf`:

```
   # Prevent known attack vectors
   server min protocol = SMB2
   smb encrypt = required
   restrict anonymous = 2
   ntlm auth = ntlmv2-only
   client NTLMv2 auth = yes

   # Logging for audit
   log level = 2
   vfs objects = full_audit
   full_audit:prefix = %u|%I|%S
   full_audit:success = mkdir rmdir open close read write rename unlink
   full_audit:failure = none
   full_audit:facility = local5
   full_audit:priority = notice
```

### Step 8.3: File integrity monitoring

```bash
sudo tee /usr/local/bin/samba-integrity-check.sh > /dev/null <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

# Purpose: Check smb.conf for unauthorized changes
# Compares current config hash against known-good baseline

CONF="/etc/samba/smb.conf"
BASELINE="/etc/samba/smb.conf.sha256"

if [ ! -f "$BASELINE" ]; then
    sha256sum "$CONF" > "$BASELINE"
    echo "Baseline created"
    exit 0
fi

CURRENT=$(sha256sum "$CONF" | awk '{print $1}')
KNOWN=$(awk '{print $1}' "$BASELINE")

if [ "$CURRENT" != "$KNOWN" ]; then
    echo "ALERT: smb.conf has been modified!"
    diff <(cat "$BASELINE") <(sha256sum "$CONF") || true
    logger -t samba-integrity "ALERT: smb.conf modified — hash mismatch"
    exit 1
fi

echo "OK: smb.conf unchanged"
exit 0
SCRIPT

sudo chmod +x /usr/local/bin/samba-integrity-check.sh

# Create baseline
sudo /usr/local/bin/samba-integrity-check.sh
```

### Step 8.4: AppArmor profile for Samba

```bash
# Check if AppArmor profile exists
sudo aa-status | grep smbd || echo "No custom AppArmor profile — using default"

# If custom profile needed:
sudo tee /etc/apparmor.d/usr.sbin.smbd > /dev/null <<'PROFILE'
#include <tunables/global>

/usr/sbin/smbd {
    #include <abstractions/base>
    #include <abstractions/nameservice>
    #include <abstractions/samba>

    /srv/samba/** rw,
    /etc/samba/smb.conf r,
    /var/log/samba/** rw,
    /var/run/samba/** rw,
    /var/lib/samba/** rw,
    /usr/local/bin/samba-mkhome.sh rix,
}
PROFILE

sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.smbd 2>/dev/null || echo "AppArmor reload skipped"
```

---

## Phase 9: Client Connection Testing

### Step 9.1: Test from Linux client

```bash
# Install client tools
sudo apt install -y smbclient cifs-utils

# List shares
smbclient -L //192.168.1.100 -U alice

# Connect to department share
smbclient //192.168.1.100/engineering -U alice -c 'ls'

# Mount permanently (add to /etc/fstab)
sudo mkdir -p /mnt/samba/engineering
echo "//192.168.1.100/engineering /mnt/samba/engineering cifs credentials=/root/.smbcredentials,uid=1000,gid=1000 0 0" | \
    sudo tee -a /etc/fstab

# Create credentials file
sudo tee /root/.smbcredentials > /dev/null <<'EOF'
username=alice
password=ChangeMe123!
domain=COMPANY
EOF
sudo chmod 0600 /root/.smbcredentials

# Mount
sudo mount -a
ls /mnt/samba/engineering
```

### Step 9.2: Test from Windows client

```powershell
# In PowerShell
net use Z: \\192.168.1.100\engineering /user:COMPANY\alice ChangeMe123!
dir Z:

# Or map via GUI:
# File Explorer -> This PC -> Map Network Drive
# Folder: \\192.168.1.100\engineering
```

### Step 9.3: Test from macOS client

```bash
# Command line
open smb://alice@192.168.1.100/engineering

# Or Finder -> Go -> Connect to Server -> smb://192.168.1.100/engineering
```

### Step 9.4: Verify permissions across all shares

```bash
# As alice — should see engineering and shared, not finance
smbclient //192.168.1.100/engineering -U alice -c 'ls'
smbclient //192.168.1.100/finance -U alice -c 'ls'
# Expected: NT_STATUS_ACCESS_DENIED for finance

# As diana — should see finance
smbclient //192.168.1.100/finance -U diana -c 'ls'

# Guest — should see public only
smbclient //192.168.1.100/public -N -c 'ls'
```

---

## Phase 10: Disaster Recovery Drill

### Step 10.1: Simulate configuration failure

```bash
# Corrupt smb.conf intentionally
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.broken
echo "INVALID CONFIG" | sudo tee /etc/samba/smb.conf

# Samba should fail to reload
sudo systemctl reload smbd 2>&1 || echo "Samba reload failed as expected"

# Restore from backup
sudo cp /etc/samba/smb.conf.backup.* /etc/samba/smb.conf
sudo systemctl restart smbd
sudo systemctl status smbd
```

### Step 10.2: Restore from backup

```bash
# Simulate data loss
sudo rm -rf /srv/samba/dept/engineering/*

# Restore from rsync backup
sudo rsync -av /backup/samba/dept/engineering/ /srv/samba/dept/engineering/

# Verify
ls -la /srv/samba/dept/engineering/
```

### Step 10.3: Verify integrity after recovery

```bash
# Health check
/usr/local/bin/samba-healthcheck.sh

# Test config
testparm -s

# Test access
smbclient //localhost/engineering -U alice -c 'ls'

# Check logs
sudo tail -20 /var/log/samba/log.smbd
```

---

## Verify

### End-to-End Verification Checklist

```bash
# 1. Services running
systemctl is-active smbd nmbd

# 2. Config valid
testparm -s 2>&1 | grep -i error || echo "Config OK"

# 3. Shares visible
smbclient -L localhost -N 2>/dev/null | grep -E '(engineering|marketing|finance|hr|shared|public)'

# 4. User access works
smbclient //localhost/engineering -U alice -c 'ls' >/dev/null 2>&1 && echo "Alice: OK"

# 5. ACLs applied
getfacl /srv/samba/dept/finance 2>/dev/null | grep -q sgrp && echo "ACLs: OK"

# 6. Backup exists
ls /backup/samba/dept/ 2>/dev/null && echo "Backups: OK"

# 7. Monitoring running
cat /var/lib/node_exporter/textfile_collector/samba.prom 2>/dev/null | head -5

# 8. Firewall active
ufw status | grep -q active && echo "Firewall: OK"

# 9. Health check passes
/usr/local/bin/samba-healthcheck.sh && echo "Health: OK"

# 10. Integrity check passes
/usr/local/bin/samba-integrity-check.sh && echo "Integrity: OK"
```

### Expected Output

All 10 checks should return OK. If any fail, refer to the corresponding phase for remediation.

---

## Rollback

### Full Rollback — Remove Everything

```bash
# Stop services
sudo systemctl stop smbd nmbd winbind

# Remove packages
sudo apt purge -y samba smbclient samba-common-bin cifs-utils winbind
sudo apt autoremove -y

# Remove data
sudo rm -rf /srv/samba
sudo rm -rf /backup/samba
sudo rm -rf /etc/samba
sudo rm -f /usr/local/bin/samba-*.sh
sudo rm -f /etc/cron.d/samba-*
sudo rm -f /var/lib/node_exporter/textfile_collector/samba.prom

# Remove users (careful — only Samba users)
for user in alice bob charlie diana; do
    sudo smbpasswd -x "$user" 2>/dev/null || true
    sudo userdel "$user" 2>/dev/null || true
done

# Remove groups
for grp in sgrp-engineering sgrp-marketing sgrp-finance sgrp-hr sgrp-shared; do
    sudo groupdel "$grp" 2>/dev/null || true
done

# Remove firewall rules
sudo ufw delete allow 445/tcp
sudo ufw delete allow 139/tcp

echo "Rollback complete"
```

### Partial Rollback — Restore Config Only

```bash
sudo cp /etc/samba/smb.conf.backup.* /etc/samba/smb.conf
sudo systemctl restart smbd
```

---

## Common Errors

### Error: "NT_STATUS_ACCESS_DENIED" when connecting

**Cause**: User not in valid users list or Samba password not set.
**Solution**:
```bash
# Check user exists in Samba database
sudo pdbedit -L

# Re-add user
sudo smbpasswd -a username

# Check group membership
groups username
```

### Error: "testparm" reports "Permission denied" on share path

**Cause**: Share directory permissions incorrect.
**Solution**:
```bash
# Fix ownership
sudo chown root:groupname /srv/samba/dept/sharename
sudo chmod 2770 /srv/samba/dept/sharename

# Verify
ls -la /srv/samba/dept/
```

### Error: "Connection refused" on port 445

**Cause**: smbd not running or firewall blocking.
**Solution**:
```bash
# Check service
sudo systemctl status smbd

# Check firewall
sudo ufw status | grep 445

# Check if listening
ss -tlnp | grep 445
```

### Error: Shares not visible in Windows Network

**Cause**: nmbd not running or workgroup mismatch.
**Solution**:
```bash
# Check nmbd
sudo systemctl status nmbd

# Check workgroup
testparm -s 2>/dev/null | grep "workgroup"

# Ensure NetBIOS ports open
sudo ufw allow 139/tcp
```

### Error: "Too many open files"

**Cause**: File descriptor limit too low.
**Solution**:
```bash
# Check current limit
ulimit -n

# Increase for Samba
echo "smbd hard nofile 65536" | sudo tee -a /etc/security/limits.conf
sudo systemctl restart smbd
```

### Error: Backup script fails with "rsync: connection refused"

**Cause**: If backing up to remote host, SSH key not configured.
**Solution**:
```bash
# For local backup, ensure /backup/samba exists
sudo mkdir -p /backup/samba

# For remote backup, set up SSH key
ssh-keygen -t ed25519 -f ~/.ssh/samba-backup -N ""
ssh-copy-id -i ~/.ssh/samba-backup.pub backupuser@backup-server
```

### Error: ACLs not working — "Operation not supported"

**Cause**: Filesystem not mounted with ACL support.
**Solution**:
```bash
# Check mount options
mount | grep "$(df /srv/samba --output=source | tail -1)"

# For ext4, remount with acl
sudo mount -o remount,acl /srv/samba

# Or add to /etc/fstab:
# /dev/sdb1 /srv/samba ext4 defaults,acl 0 2
```

---

## References

- [Samba Wiki — Official Documentation](https://wiki.samba.org/)
- [Samba smb.conf Man Page](https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html)
- [Samba Security](https://www.samba.org/samba/security/)
- [Ubuntu Samba Guide](https://ubuntu.com/server/docs/samba-file-server)
- [RHEL Samba Documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/managing_file_systems_and_storage/serving-files-with-samba)
- [Samba VFS Modules](https://www.samba.org/samba/docs/current/man-html/vfs_acl_xattr.8.html)
- [setfacl/getfacl Man Page](https://linux.die.net/man/1/setfacl)
- [Prometheus Node Exporter](https://github.com/prometheus/node_exporter)
- [AppArmor Samba Profile](https://gitlab.com/apparmor/apparmor/-/wikis/Samba)
- [Realmd AD Integration](https://www.freedesktop.org/software/realmd/docs/)
