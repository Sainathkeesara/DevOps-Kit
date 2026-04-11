#!/usr/bin/env bash
# AIDE (Advanced Intrusion Detection Environment) - Configuration Management Script
# Purpose: Automated installation, configuration, and integrity monitoring with AIDE
# Usage: ./aide-config.sh [OPTIONS]
# Requirements: root privileges, Linux system with package manager
# Safety: Supports DRY_RUN mode for testing - set DRY_RUN=true to preview actions
# Tested OS: Ubuntu 22.04/24.04, RHEL 9, Debian 12

set -euo pipefail

DRY_RUN="${DRY_RUN:-false}"
AIDE_DB_DIR="/var/lib/aide"
AIDE_CONF_DIR="/etc/aide"
AIDE_LOG_DIR="/var/log/aide"
REPORT_EMAIL="${REPORT_EMAIL:-root@localhost}"

log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

log_warn() {
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

dry_run() {
    if [ "$DRY_RUN" = "true" ]; then
        echo "[DRY-RUN] $*"
        return 0
    fi
    return 1
}

command -v apt-get >/dev/null 2>&1 && DISTRO="debian" || \
command -v dnf >/dev/null 2>&1 && DISTRO="rhel" || \
command -v yum >/dev/null 2>&1 && DISTRO="rhel" || DISTRO="unknown"

install_aide() {
    log_info "Installing AIDE..."

    if dry_run "Would install aide package"; then
        return 0
    fi

    case "$DISTRO" in
        debian)
            apt-get update -qq
            apt-get install -y -qq aide
            ;;
        rhel)
            dnf install -y -q aide
            ;;
        *)
            log_error "Unsupported distribution: $DISTRO"
            exit 1
            ;;
    esac

    log_info "AIDE installed successfully"
}

create_directories() {
    log_info "Creating required directories..."

    if dry_run "Would create $AIDE_DB_DIR"; then
        mkdir -p "$AIDE_DB_DIR"
    fi
    mkdir -p "$AIDE_CONF_DIR"
    mkdir -p "$AIDE_LOG_DIR"
    mkdir -p /etc/cron.d

    log_info "Directories created"
}

configure_aide() {
    log_info "Configuring AIDE..."

    AIDE_CONF="$AIDE_CONF_DIR/aide.conf"

    if dry_run "Would create AIDE configuration at $AIDE_CONF"; then
        cat > "$AIDE_CONF" << 'EOF'
# AIDE Configuration for Linux Configuration Management

# Database and report locations
database=file:/var/lib/aide/aide.db
database_out=file:/var/lib/aide/aide.db.new
report_url=file:/var/log/aide/aide-report.log
report_email=root@localhost

# File and directory groups
# ================== System Configuration Files ==================
FIP = p+i+n+u+g+s+m+c+md5+sha1+sha256+sha512+acl+xattrs
DIR = p+i+n+u+g+s+m+c+md5+sha1+sha512+acl+xattrs

# Critical system directories
/etc/config     FIP
/etc/sysconfig  FIP
/etc/default   FIP
/var/spool/cron FIP
/etc/cron.d    FIP
/etc/cron.daily FIP
/etc/cron.weekly FIP
/etc/cron.monthly FIP
/etc/sudoers.d FIP
/etc/sudoers   FIP

# System binaries - check for tampering
/bin            FIP
/sbin           FIP
/usr/bin        FIP
/usr/sbin       FIP
/usr/local/bin  FIP
/usr/local/sbin FIP

# Library directories - detect malicious libraries
/lib            FIP
/lib64          FIP
/usr/lib        FIP
/usr/lib64      FIP

# System logs - detect log tampering
/var/log        DIR

# SSH configuration
/etc/ssh        FIP

# Package management
/var/lib/dpkg   DIR
/var/lib/rpm    DIR

# Kernel and boot
/boot           FIP
/etc/grub.d     FIP
/etc/default/grub FIP

# Network configuration
/etc/network    DIR
/etc/sysconfig/network-scripts DIR

# User and group databases
/etc/passwd    FIP
/etc/group     FIP
/etc/shadow    FIP
/etc/gshadow   FIP
/etc/sudoers   FIP
EOF
        return 0
    fi

    cat > "$AIDE_CONF" << 'EOF'
# AIDE Configuration for Linux Configuration Management

# Database and report locations
database=file:/var/lib/aide/aide.db
database_out=file:/var/lib/aide/aide.db.new
report_url=file:/var/log/aide/aide-report.log
report_email=root@localhost

# File and directory groups
# ================== System Configuration Files ==================
FIP = p+i+n+u+g+s+m+c+md5+sha1+sha256+sha512+acl+xattrs
DIR = p+i+n+u+g+s+m+c+md5+sha1+sha512+acl+xattrs

# Critical system directories
/etc/config     FIP
/etc/sysconfig  FIP
/etc/default   FIP
/var/spool/cron FIP
/etc/cron.d    FIP
/etc/cron.daily FIP
/etc/cron.weekly FIP
/etc/cron.monthly FIP
/etc/sudoers.d FIP
/etc/sudoers   FIP

# System binaries - check for tampering
/bin            FIP
/sbin           FIP
/usr/bin        FIP
/usr/sbin       FIP
/usr/local/bin  FIP
/usr/local/sbin FIP

# Library directories - detect malicious libraries
/lib            FIP
/lib64          FIP
/usr/lib        FIP
/usr/lib64      FIP

# System logs - detect log tampering
/var/log        DIR

# SSH configuration
/etc/ssh        FIP

# Package management
/var/lib/dpkg   DIR
/var/lib/rpm    DIR

# Kernel and boot
/boot           FIP
/etc/grub.d     FIP
/etc/default/grub FIP

# Network configuration
/etc/network    DIR
/etc/sysconfig/network-scripts DIR

# User and group databases
/etc/passwd    FIP
/etc/group     FIP
/etc/shadow    FIP
/etc/gshadow   FIP
/etc/sudoers   FIP
EOF

    log_info "AIDE configuration written to $AIDE_CONF"
}

initialize_database() {
    log_info "Initializing AIDE database (baseline)..."

    if dry_run "Would initialize AIDE database"; then
        return 0
    fi

    aide --init 2>&1 | tee /tmp/aide-init.log
    if [ $? -eq 0 ]; then
        mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
        log_info "AIDE database initialized successfully"
    else
        log_error "AIDE database initialization failed"
        exit 1
    fi
}

create_cron_schedule() {
    log_info "Setting up automated integrity checks..."

    CRON_FILE="/etc/cron.d/aide-integrity"

    if dry_run "Would create cron job at $CRON_FILE"; then
        cat > "$CRON_FILE" << 'EOF'
# AIDE integrity check - daily run
# Run at 3:00 AM daily
0 3 * * * root /usr/bin/aide --check | /usr/bin/logger -t AIDE
EOF
        return 0
    fi

    cat > "$CRON_FILE" << 'EOF'
# AIDE integrity check - daily run
# Run at 3:00 AM daily
0 3 * * * root /usr/bin/aide --check | /usr/bin/logger -t AIDE
EOF

    chmod 644 "$CRON_FILE"
    log_info "Cron job created at $CRON_FILE"
}

create_check_script() {
    log_info "Creating manual check script..."

    SCRIPT_PATH="/usr/local/bin/aide-check.sh"

    if dry_run "Would create check script at $SCRIPT_PATH"; then
        cat > "$SCRIPT_PATH" << 'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

REPORT_FILE="/var/log/aide/aide-report-$(date +%Y%m%d-%H%M%S).log"
AIDE_BIN="/usr/bin/aide"

command -v "$AIDE_BIN" >/dev/null 2>&1 || { echo "Error: aide not found"; exit 1; }

echo "Running AIDE integrity check..."
$AIDE_BIN --check > "$REPORT_FILE" 2>&1

if grep -q "All files match AIDE database" "$REPORT_FILE"; then
    echo "✓ No changes detected - system integrity verified"
    exit 0
else
    echo "⚠ WARNING: Changes detected! Review $REPORT_FILE"
    exit 2
fi
SCRIPT
        return 0
    fi

    cat > "$SCRIPT_PATH" << 'SCRIPT'
#!/usr/bin/env bash
# AIDE Manual Check Script
# Purpose: Run manual integrity check and generate report

set -euo pipefail

REPORT_FILE="/var/log/aide/aide-report-$(date +%Y%m%d-%H%M%S).log"
AIDE_BIN="/usr/bin/aide"

command -v "$AIDE_BIN" >/dev/null 2>&1 || { echo "Error: aide not found"; exit 1; }

log_info() {
    echo "[INFO] $*"
}

log_info "Running AIDE integrity check..."
$AIDE_BIN --check > "$REPORT_FILE" 2>&1

if grep -q "All files match AIDE database" "$REPORT_FILE"; then
    log_info "No changes detected - system integrity verified"
    exit 0
else
    log_info "WARNING: Changes detected! Review $REPORT_FILE"
    exit 2
fi
SCRIPT

    chmod +x "$SCRIPT_PATH"
    log_info "Check script created at $SCRIPT_PATH"
}

verify_installation() {
    log_info "Verifying AIDE installation..."

    if dry_run "Would verify AIDE installation"; then
        return 0
    fi

    if command -v aide >/dev/null 2>&1; then
        log_info "AIDE binary: $(command -v aide)"
        log_info "AIDE version: $(aide --version | head -1)"
        log_info "Configuration: $AIDE_CONF_DIR/aide.conf"
        log_info "Database: $AIDE_DB_DIR/aide.db"
        log_info "✓ AIDE verification complete"
    else
        log_error "AIDE binary not found"
        exit 1
    fi
}

main() {
    log_info "Starting AIDE configuration management setup..."
    log_info "DRY_RUN mode: $DRY_RUN"

    install_aide
    create_directories
    configure_aide
    initialize_database
    create_cron_schedule
    create_check_script
    verify_installation

    log_info "AIDE configuration management setup complete!"
    log_info "Run 'aide-check.sh' for manual checks"
    log_info "View reports in /var/log/aide/"
}

main "$@"