#!/usr/bin/env bash
set -euo pipefail

# AIDE (Advanced Intrusion Detection Environment) Configuration Management Script
# Purpose: Deploy, configure, and manage AIDE for file integrity monitoring on Linux
# Usage: ./aide-deploy.sh [--install|--init|--check|--update|--rollback] [OPTIONS]
# Requirements: Root/sudo access, Linux (Ubuntu 22.04, RHEL 9, Debian 12)
# Safety: Idempotent — safe to run multiple times. Supports DRY_RUN mode.
# Tested on: Ubuntu 22.04, RHEL 9, Debian 12

DRY_RUN="${DRY_RUN:-false}"
AIDE_CONFIG="/etc/aide/aide.conf"
AIDE_DB="/var/lib/aide/aide.db"
AIDE_DB_BACKUP="/var/lib/aide/aide.db.backup"
LOG_FILE="/var/log/aide-deployment.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE" 2>/dev/null || echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Error: This script must be run as root" >&2
        exit 1
    fi
}

install_aide() {
    log "Installing AIDE..."
    
    if command_exists aide; then
        log "AIDE already installed: $(aide --version 2>/dev/null | head -1)"
        return 0
    fi
    
    if [ "$DRY_RUN" = true ]; then
        log "[dry-run] Would install AIDE package"
        return 0
    fi
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian)
                apt-get update
                apt-get install -y aide
                ;;
            rhel|centos|fedora)
                dnf install -y aide
                ;;
            *)
                log "Error: Unsupported OS: $ID"
                exit 1
                ;;
        esac
    else
        log "Error: Cannot determine OS"
        exit 1
    fi
    
    log "AIDE installed successfully"
}

initialize_database() {
    log "Initializing AIDE database..."
    
    if [ "$DRY_RUN" = true ]; then
        log "[dry-run] Would initialize AIDE database at $AIDE_DB"
        return 0
    fi
    
    aide --init 2>/dev/null || {
        log "Warning: aide --init had issues, checking configuration..."
        if [ -f "$AIDE_CONFIG" ]; then
            log "Configuration file exists, attempting to initialize..."
            aide --init --config="$AIDE_CONFIG" || log "Warning: Initialization returned non-zero"
        fi
    }
    
    if [ -f /var/lib/aide/aide.db.new ]; then
        mv /var/lib/aide/aide.db.new "$AIDE_DB"
        log "AIDE database initialized at $AIDE_DB"
    elif [ -f "$AIDE_DB" ]; then
        log "AIDE database already exists at $AIDE_DB"
    else
        log "Warning: Database initialization may have failed"
    fi
}

create_custom_config() {
    local config_file="${1:-$AIDE_CONFIG}"
    local custom_dir="/etc/aide/aide.conf.d"
    
    log "Creating custom AIDE configuration..."
    
    if [ "$DRY_RUN" = true ]; then
        log "[dry-run] Would create AIDE configuration at $config_file"
        return 0
    fi
    
    mkdir -p "$custom_dir"
    
    cat > "$config_file" <<'EOF'
# AIDE Configuration for File Integrity Monitoring
# Database location
database=file:/var/lib/aide/aide.db
database_out=file:/var/lib/aide/aide.db.new

# Report settings
report_url=file:/var/log/aide/aide.log
report_level=20

# Group definitions
@@define DBDIR /var/lib/aide
@@define LOGDIR /var/log/aide

# Root filesystem - critical directories
/boot   MD5     p+i+n+u+g+s+m+c+acl+selinux+xattrs+sha256
/       MD5     p+i+n+u+g+s+m+c+acl+selinux+xattrs+sha256
!/proc
!/sys
!/dev
!/run
!/tmp

# System binaries - verify integrity
/bin    MD5     p+i+n+u+g+s+m+c+acl+selinux+xattrs+sha256
/sbin   MD5     p+i+n+u+g+s+m+c+acl+selinux+xattrs+sha256
/usr    MD5     p+i+n+u+g+s+m+c+acl+selinux+xattrs+sha256

# Configuration files
/etc    MD5     p+i+n+u+g+s+m+c+acl+selinux+xattrs+sha256
/etc/aide/aide.conf.d/    p+i+n+u+g+s+m+c+acl+selinux+xattrs+sha256

# Log directories
/var/log    MD5     p+i+n+u+g+s+m+c+acl+selinux+xattrs+sha256
/var/log/aide   p+i+n+u+g+s+m+c+acl+selinux+xattrs+sha256

# Cron directories
/etc/cron.daily  p+i+n+u+g+s+m+c+acl+selinux+xattrs+sha256
/etc/cron.hourly p+i+n+u+g+s+m+c+acl+selinux+xattrs+sha256
/etc/cron.weekly p+i+n+u+g+s+m+c+acl+selinux+xattrs+sha256
/etc/cron.monthly    p+i+n+u+g+s+m+c+acl+selinux+xattrs+sha256

# SSH configuration
/etc/ssh/sshd_config    p+i+n+u+g+s+m+c+acl+selinux+xattrs+sha256
/etc/ssh/ssh_config p+i+n+u+g+s+m+c+acl+selinux+xattrs+sha256

# User databases
/var/lib/aide   p+i+n+u+g+s+m+c+acl+selinux+xattrs+sha256
/var/cache/aide p+i+n+u+g+s+m+c+acl+selinux+xattrs+sha256
EOF
    
    log "Configuration created at $config_file"
}

run_integrity_check() {
    log "Running AIDE integrity check..."
    
    if [ "$DRY_RUN" = true ]; then
        log "[dry-run] Would run: aide --check"
        return 0
    fi
    
    if aide --check --config="$AIDE_CONFIG" 2>&1 | tee -a /var/log/aide/aide.log; then
        log "AIDE check passed - no changes detected"
        return 0
    else
        local exit_code=$?
        log "Warning: AIDE detected changes (exit code: $exit_code)"
        return "$exit_code"
    fi
}

update_database() {
    log "Updating AIDE database..."
    
    if [ "$DRY_RUN" = true ]; then
        log "[dry-run] Would run: aide --update"
        return 0
    fi
    
    if [ -f "$AIDE_DB" ]; then
        cp "$AIDE_DB" "$AIDE_DB_BACKUP.$(date +%Y%m%d)"
        log "Database backed up to $AIDE_DB_BACKUP.$(date +%Y%m%d)"
    fi
    
    aide --update --config="$AIDE_CONFIG" 2>/dev/null || {
        log "Warning: aide --update returned non-zero"
    }
    
    if [ -f /var/lib/aide/aide.db.new ]; then
        mv /var/lib/aide/aide.db.new "$AIDE_DB"
        log "Database updated at $AIDE_DB"
    fi
}

setup_cron_job() {
    log "Setting up daily AIDE cron job..."
    
    if [ "$DRY_RUN" = true ]; then
        log "[dry-run] Would create cron job at /etc/cron.d/aide"
        return 0
    fi
    
    mkdir -p /etc/cron.daily/aide-run
    
    cat > /etc/cron.daily/aide-run.sh <<'EOF'
#!/bin/bash
# AIDE daily integrity check
# Run at 3:00 AM daily
LOGFILE="/var/log/aide/daily-check.log"
AIDE_CONF="/etc/aide/aide.conf"
DB_FILE="/var/lib/aide/aide.db"

mkdir -p "$(dirname "$LOGFILE")"

if [ ! -f "$DB_FILE" ]; then
    echo "$(date): Database not found, initializing..." >> "$LOGFILE"
    aide --init --config="$AIDE_CONF" 2>/dev/null
    exit 0
fi

echo "$(date): Starting AIDE check..." >> "$LOGFILE"
if aide --check --config="$AIDE_CONF" >> "$LOGFILE" 2>&1; then
    echo "$(date): No changes detected" >> "$LOGFILE"
else
    echo "$(date): WARNING: Changes detected - review $LOGFILE" >> "$LOGFILE"
fi
EOF
    
    chmod +x /etc/cron.daily/aide-run.sh
    
    cat > /etc/cron.d/aide <<'EOF'
0 3 * * * root /etc/cron.daily/aide-run.sh
EOF
    
    log "Cron job configured to run daily at 3:00 AM"
}

verify_installation() {
    log "Verifying AIDE installation..."
    
    local errors=0
    
    if ! command_exists aide; then
        log "Error: aide command not found"
        errors=$((errors + 1))
    fi
    
    if [ ! -f "$AIDE_CONFIG" ]; then
        log "Error: Configuration file not found at $AIDE_CONFIG"
        errors=$((errors + 1))
    fi
    
    if [ ! -f "$AIDE_DB" ]; then
        log "Warning: Database not initialized. Run with --init flag"
    fi
    
    if [ $errors -gt 0 ]; then
        log "Verification failed with $errors error(s)"
        return 1
    fi
    
    log "AIDE installation verified successfully"
    return 0
}

rollback() {
    log "Rolling back AIDE configuration..."
    
    if [ "$DRY_RUN" = true ]; then
        log "[dry-run] Would rollback AIDE configuration"
        return 0
    fi
    
    local backup_file
    backup_file=$(ls -1t "$AIDE_DB_BACKUP."* 2>/dev/null | head -1)
    
    if [ -n "$backup_file" ]; then
        cp "$backup_file" "$AIDE_DB"
        log "Database restored from $backup_file"
    else
        log "No backup found to restore"
    fi
}

show_usage() {
    cat <<EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    --install         Install AIDE and create configuration
    --init            Initialize AIDE database
    --check           Run integrity check
    --update          Update database with current state
    --verify          Verify installation
    --rollback        Rollback database to last backup

Options:
    --dry-run         Show what would be done without executing
    --config FILE     Use custom configuration file

Examples:
    $0 --install --dry-run
    $0 --init
    $0 --check
    $0 --update

Environment:
    DRY_RUN=true      Enable dry-run mode
EOF
}

main() {
    local command=""
    local custom_config=""
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --install)
                command="install"
                shift
                ;;
            --init)
                command="init"
                shift
                ;;
            --check)
                command="check"
                shift
                ;;
            --update)
                command="update"
                shift
                ;;
            --verify)
                command="verify"
                shift
                ;;
            --rollback)
                command="rollback"
                shift
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --config)
                custom_config="$2"
                shift 2
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    mkdir -p "$(dirname "$LOG_FILE")"
    mkdir -p /var/log/aide
    
    case "$command" in
        install)
            check_root
            install_aide
            create_custom_config "$custom_config"
            verify_installation
            ;;
        init)
            check_root
            initialize_database
            ;;
        check)
            check_root
            run_integrity_check
            ;;
        update)
            check_root
            update_database
            ;;
        verify)
            verify_installation
            ;;
        rollback)
            check_root
            rollback
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
    
    log "AIDE operation completed"
}

main "$@"
