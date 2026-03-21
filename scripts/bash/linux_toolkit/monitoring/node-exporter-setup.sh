#!/usr/bin/env bash
# =============================================================================
# Prometheus Node Exporter Setup Script
# =============================================================================
# Purpose: Install and configure Prometheus node_exporter for Linux system monitoring
# Usage: ./node-exporter-setup.sh [--dry-run] [--version VERSION] [--port PORT]
# Requirements: root privileges, systemd, curl
# Safety Notes:
#   - Always run with --dry-run first to preview installation steps
#   - This script creates systemd service and firewall rules
#   - Backup existing configurations before overwriting
# Tested OS: RHEL 7/8/9, Ubuntu 20.04/22.04, Debian 11/12
# =============================================================================

set -euo pipefail

DRY_RUN="${DRY_RUN:-true}"
VERSION="${VERSION:-1.8.2}"
PORT="${PORT:-9100}"
INSTALL_DIR="/opt/prometheus"
SYSTEMD_DIR="/etc/systemd/system"
MONITORING_USER="node_exporter"

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Install and configure Prometheus node_exporter for system monitoring

OPTIONS:
    --dry-run          Preview installation steps without executing (default: true)
    --version VERSION   Node exporter version (default: 1.8.2)
    --port PORT        Listen port (default: 9100)
    -h, --help        Show this help message

Examples:
    $0 --dry-run
    $0 --version 1.8.0 --port 9100
    DRY_RUN=false $0 --version 1.8.2

EOF
    exit 0
}

log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
}

check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        log "ERROR" "This script must be run as root"
        exit 1
    fi
}

check_dependencies() {
    log "INFO" "Checking dependencies..."
    
    local required_cmds
    required_cmds=("curl" "tar" "useradd" "systemctl")
    
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log "WARN" "Command '$cmd' not found - some features may not work"
        fi
    done
    
    if command -v firewall-cmd >/dev/null 2>&1; then
        log "INFO" "firewall-cmd available"
    else
        log "WARN" "firewall-cmd not found - firewall config will be skipped"
    fi
    
    log "INFO" "Dependency check complete"
}

create_user() {
    log "INFO" "Creating monitoring user..."
    
    if id "$MONITORING_USER" &>/dev/null; then
        log "INFO" "User $MONITORING_USER already exists"
    else
        if [[ "$DRY_RUN" == "true" ]]; then
            log "INFO" "[DRY-RUN] Would create user: $MONITORING_USER"
        else
            useradd --no-create-home --shell /usr/sbin/nologin "$MONITORING_USER" 2>/dev/null || true
            log "INFO" "User created: $MONITORING_USER"
        fi
    fi
}

download_exporter() {
    log "INFO" "Downloading node_exporter v$VERSION..."
    
    local download_url="https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.linux-amd64.tar.gz"
    local download_file="/tmp/node_exporter-${VERSION}.linux-amd64.tar.gz"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would download: $download_url"
        log "INFO" "[DRY-RUN] Would extract to: $INSTALL_DIR"
        return 0
    fi
    
    mkdir -p "$INSTALL_DIR"
    
    if curl -L --progress-bar "$download_url" -o "$download_file"; then
        log "INFO" "Download complete"
        
        tar -xzf "$download_file" -C /tmp/
        cp /tmp/node_exporter-${VERSION}.linux-amd64/node_exporter "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/node_exporter"
        chown "$MONITORING_USER:$MONITORING_USER" "$INSTALL_DIR/node_exporter"
        
        rm -rf /tmp/node_exporter-${VERSION}.linux-amd64 "$download_file"
        log "INFO" "Node exporter installed to $INSTALL_DIR"
    else
        log "ERROR" "Failed to download node_exporter"
        return 1
    fi
}

create_systemd_service() {
    log "INFO" "Creating systemd service..."
    
    local service_file="$SYSTEMD_DIR/node_exporter.service"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would create service: $service_file"
        return 0
    fi
    
    cat > "$service_file" <<EOF
[Unit]
Description=Prometheus Node Exporter
Documentation=https://github.com/prometheus/node_exporter
After=network-online.target

[Service]
Type=simple
User=$MONITORING_USER
Group=$MONITORING_USER
ExecStart=$INSTALL_DIR/node_exporter --collector.textfile.directory=/var/lib/node_exporter/textfile_collector --web.listen-address=:$PORT
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable node_exporter
    log "INFO" "Systemd service created and enabled"
}

configure_firewall() {
    log "INFO" "Configuring firewall..."
    
    if ! command -v firewall-cmd >/dev/null 2>&1; then
        log "WARN" "firewall-cmd not found, skipping firewall configuration"
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would allow port $PORT through firewall"
        return 0
    fi
    
    if firewall-cmd --state &>/dev/null; then
        firewall-cmd --permanent --add-port=${PORT}/tcp
        firewall-cmd --reload
        log "INFO" "Firewall configured - port $PORT opened"
    else
        log "INFO" "Firewall not active, skipping"
    fi
}

create_textfile_collector() {
    log "INFO" "Creating textfile collector directory..."
    
    local textfile_dir="/var/lib/node_exporter/textfile_collector"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would create: $textfile_dir"
        return 0
    fi
    
    mkdir -p "$textfile_dir"
    chown "$MONITORING_USER:$MONITORING_USER" "$textfile_dir"
    log "INFO" "Textfile collector directory created"
}

start_service() {
    log "INFO" "Starting node_exporter service..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would start service: node_exporter"
        return 0
    fi
    
    systemctl restart node_exporter
    sleep 2
    
    if systemctl is-active --quiet node_exporter; then
        log "INFO" "Node exporter is running"
    else
        log "ERROR" "Failed to start node_exporter"
        systemctl status node_exporter
        return 1
    fi
}

verify_installation() {
    log "INFO" "Verifying installation..."
    
    local max_retries=5
    local retry=0
    
    while [[ $retry -lt $max_retries ]]; do
        if curl -s "http://localhost:$PORT/metrics" | head -n 5 | grep -q "node_exporter"; then
            log "INFO" "Node exporter is responding on port $PORT"
            return 0
        fi
        ((retry++))
        sleep 1
    done
    
    log "WARN" "Could not verify node exporter - may need manual check"
    return 0
}

print_summary() {
    log "INFO" "=============================================="
    log "INFO" "  Node Exporter Installation Complete"
    log "INFO" "=============================================="
    log "INFO" "Version:      $VERSION"
    log "INFO" "Listen Port:  $PORT"
    log "INFO" "Install Dir:  $INSTALL_DIR"
    log "INFO" ""
    log "INFO" "Service:      systemctl start|stop|restart node_exporter"
    log "INFO" "Metrics:      http://localhost:$PORT/metrics"
    log "INFO" ""
    log "INFO" "Next steps:"
    log "INFO" "  1. Add to Prometheus scrape config:"
    log "INFO" "     - job_name: 'node'"
    log "INFO" "       static_configs:"
    log "INFO" "         - targets: ['localhost:$PORT']"
    log "INFO" "  2. Import Grafana dashboard (ID: 1860)"
    log "INFO" "=============================================="
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --version)
                VERSION="$2"
                shift 2
                ;;
            --port)
                PORT="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
    done
    
    log "INFO" "Node Exporter Setup Starting..."
    log "INFO" "Dry-run mode: $DRY_RUN"
    log "INFO" "Version: $VERSION"
    log "INFO" "Port: $PORT"
    
    check_dependencies
    create_user
    download_exporter
    create_systemd_service
    configure_firewall
    create_textfile_collector
    start_service
    verify_installation
    print_summary
    
    log "INFO" "Setup complete"
}

main "$@"
