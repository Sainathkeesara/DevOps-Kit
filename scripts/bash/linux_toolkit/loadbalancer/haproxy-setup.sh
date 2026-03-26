#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# HAProxy Load Balancer — Automated Setup Script
#
# Purpose: Install and configure HAProxy as a Layer 4/7 load balancer on
#          Ubuntu 24.04/22.04 LTS with SSL termination, health checks,
#          and Prometheus metrics exporter.
#
# Usage:   ./haproxy-setup.sh [OPTIONS]
#          ./haproxy-setup.sh --backends "10.0.1.10:8080,10.0.1.11:8080" --domain example.com
#          ./haproxy-setup.sh --dry-run --backends "10.0.1.10:8080,10.0.1.11:8080"
#
# Requirements:
#   - Ubuntu 24.04 or 22.04 LTS
#   - Root privileges (sudo)
#   - Ports 80, 443, 8404 available
#   - Network connectivity to backend servers
#   - TLS certificate files (or use --self-signed for testing)
#
# Safety notes:
#   - Dry-run mode (--dry-run) prints all actions without executing
#   - Creates timestamped backup of existing haproxy.cfg before changes
#   - Validates config syntax before applying (haproxy -c)
#   - Does NOT modify firewall rules automatically — use --firewall flag
#
# Tested on: Ubuntu 24.04 LTS, Ubuntu 22.04 LTS
# =============================================================================

DRY_RUN=false
FIREWALL=false
SELF_SIGNED=false
BACKENDS=""
DOMAIN=""
HTTP_PORT=80
HTTPS_PORT=443
STATS_PORT=8404
STATS_USER="admin"
STATS_PASS="changeme"
HEALTH_PATH="/health"
BALANCE="roundrobin"
CERT_DIR="/etc/haproxy/certs"
EXPORTER_VERSION="0.15.0"

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
Usage: haproxy-setup.sh [OPTIONS]

Required:
  --backends "ip:port,ip:port"   Comma-separated backend server list

Options:
  --domain DOMAIN                Domain name for TLS (default: localhost)
  --self-signed                  Generate self-signed cert (testing only)
  --cert-dir DIR                 TLS certificate directory (default: /etc/haproxy/certs)
  --health-path PATH             Backend health check endpoint (default: /health)
  --balance MODE                 Load balancing algorithm: roundrobin|source|leastconn (default: roundrobin)
  --http-port PORT               HTTP frontend port (default: 80)
  --https-port PORT              HTTPS frontend port (default: 443)
  --stats-port PORT              Stats page port (default: 8404)
  --stats-user USER              Stats page username (default: admin)
  --stats-pass PASS              Stats page password (default: changeme)
  --firewall                     Configure ufw rules automatically
  --dry-run                      Print actions without executing
  --help                         Show this help message
USAGE
    exit 0
}

# shellcheck disable=SC2294
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
        --backends)     BACKENDS="$2"; shift 2 ;;
        --domain)       DOMAIN="$2"; shift 2 ;;
        --self-signed)  SELF_SIGNED=true; shift ;;
        --cert-dir)     CERT_DIR="$2"; shift 2 ;;
        --health-path)  HEALTH_PATH="$2"; shift 2 ;;
        --balance)      BALANCE="$2"; shift 2 ;;
        --http-port)    HTTP_PORT="$2"; shift 2 ;;
        --https-port)   HTTPS_PORT="$2"; shift 2 ;;
        --stats-port)   STATS_PORT="$2"; shift 2 ;;
        --stats-user)   STATS_USER="$2"; shift 2 ;;
        --stats-pass)   STATS_PASS="$2"; shift 2 ;;
        --firewall)     FIREWALL=true; shift ;;
        --dry-run)      DRY_RUN=true; shift ;;
        --help)         usage ;;
        *)              log_error "Unknown option: $1"; usage ;;
    esac
done

# --- Validation ---
if [ -z "$BACKENDS" ]; then
    log_error "--backends is required"
    usage
fi

if [ "$(id -u)" -ne 0 ] && [ "$DRY_RUN" = false ]; then
    log_error "This script must be run as root (or use --dry-run)"
    exit 1
fi

if [ -z "$DOMAIN" ]; then
    DOMAIN="localhost"
    log_warn "No --domain specified, using 'localhost'"
fi

# --- Binary checks ---
for cmd in apt-get systemctl curl; do
    command -v "$cmd" >/dev/null 2>&1 || { log_error "$cmd not found"; exit 1; }
done

# --- Pre-flight ---
log_info "=== HAProxy Load Balancer Setup ==="
log_info "Backends: $BACKENDS"
log_info "Domain: $DOMAIN"
log_info "Balance: $BALANCE"
log_info "Ports: HTTP=$HTTP_PORT, HTTPS=$HTTPS_PORT, Stats=$STATS_PORT"
log_info "Dry-run: $DRY_RUN"

# --- Step 1: Install HAProxy ---
log_info "Step 1/9: Installing HAProxy..."
command -v haproxy >/dev/null 2>&1 && log_info "HAProxy already installed: $(haproxy -v 2>&1 | head -1)" || run_or_dry "apt-get update && apt-get install -y haproxy"

# --- Step 2: Backup existing config ---
log_info "Step 2/9: Backing up existing configuration..."
if [ -f /etc/haproxy/haproxy.cfg ]; then
    BACKUP="/etc/haproxy/haproxy.cfg.bak.$(date +%Y%m%d%H%M%S)"
    run_or_dry "cp /etc/haproxy/haproxy.cfg '$BACKUP'"
    log_info "Backup created: $BACKUP"
fi

# --- Step 3: Generate config ---
log_info "Step 3/9: Generating HAProxy configuration..."

# Build backend server lines
BACKEND_SERVERS=""
IFS=',' read -ra BACKEND_ARRAY <<< "$BACKENDS"
IDX=1
for backend in "${BACKEND_ARRAY[@]}"; do
    BACKEND_SERVERS="${BACKEND_SERVERS}    server srv${IDX} ${backend} check inter 5s fall 3 rise 2 weight 100
"
    IDX=$((IDX + 1))
done

CONFIG=$(cat << HAPROXY_CFG
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon
    ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets
    tune.ssl.default-dh-param 2048

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    option  forwardfor
    option  http-server-close
    timeout connect 5000
    timeout client  50000
    timeout server  50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http

frontend http_front
    bind *:${HTTP_PORT}
    http-request redirect scheme https code 301 unless { ssl_fc }

frontend https_front
    bind *:${HTTPS_PORT} ssl crt ${CERT_DIR}/site.pem alpn h2,http/1.1
    mode http
    http-response set-header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
    http-response set-header X-Content-Type-Options "nosniff"
    http-response set-header X-Frame-Options "DENY"
    http-request set-header X-Forwarded-Proto https
    default_backend app_servers

frontend stats
    bind *:${STATS_PORT}
    mode http
    stats enable
    stats uri /stats
    stats refresh 10s
    stats admin if LOCALHOST
    stats auth ${STATS_USER}:${STATS_PASS}

backend app_servers
    mode http
    balance ${BALANCE}
    option httpchk GET ${HEALTH_PATH}
    http-check expect status 200
${BACKEND_SERVERS}
HAPROXY_CFG
)

if [ "$DRY_RUN" = true ]; then
    echo "[dry-run] Would write /etc/haproxy/haproxy.cfg:"
    echo "$CONFIG"
else
    echo "$CONFIG" > /etc/haproxy/haproxy.cfg
fi

# --- Step 4: TLS certificate ---
log_info "Step 4/9: Setting up TLS certificate..."
run_or_dry "mkdir -p '$CERT_DIR'"

if [ "$SELF_SIGNED" = true ]; then
    log_info "Generating self-signed certificate..."
    run_or_dry "openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
        -keyout '${CERT_DIR}/site.key' \
        -out '${CERT_DIR}/site.crt' \
        -subj '/CN=${DOMAIN}'"
    run_or_dry "cat '${CERT_DIR}/site.crt' '${CERT_DIR}/site.key' > '${CERT_DIR}/site.pem'"
    run_or_dry "chmod 600 '${CERT_DIR}/site.pem'"
else
    if [ -f "${CERT_DIR}/site.pem" ]; then
        log_info "TLS certificate already exists at ${CERT_DIR}/site.pem"
    else
        log_warn "No TLS certificate found. Place fullchain.pem + privkey.pem combined as ${CERT_DIR}/site.pem"
        log_warn "Or re-run with --self-signed for testing"
        if [ "$DRY_RUN" = false ]; then
            log_error "TLS certificate required. Exiting."
            exit 1
        fi
    fi
fi

# --- Step 5: Rsyslog configuration ---
log_info "Step 5/9: Configuring rsyslog for HAProxy logging..."
if [ "$DRY_RUN" = true ]; then
    echo "[dry-run] Would write /etc/rsyslog.d/49-haproxy.conf"
else
    cat > /etc/rsyslog.d/49-haproxy.conf << 'RSYSLOG'
$ModLoad imudp
$UDPServerRun 514
local0.* /var/log/haproxy.log
local1.* /var/log/haproxy.log
RSYSLOG
    systemctl restart rsyslog || log_warn "rsyslog restart failed — logging may not work"
fi

# --- Step 6: Validate and start HAProxy ---
log_info "Step 6/9: Validating and starting HAProxy..."
if [ "$DRY_RUN" = true ]; then
    echo "[dry-run] Would run: haproxy -c -f /etc/haproxy/haproxy.cfg"
    echo "[dry-run] Would run: systemctl restart haproxy"
    echo "[dry-run] Would run: systemctl enable haproxy"
else
    haproxy -c -f /etc/haproxy/haproxy.cfg || { log_error "Configuration validation failed"; exit 1; }
    log_info "Configuration is valid"
    systemctl restart haproxy
    systemctl enable haproxy
    log_info "HAProxy started and enabled"
fi

# --- Step 7: Install Prometheus exporter ---
log_info "Step 7/9: Installing HAProxy Prometheus exporter..."
EXPORTER_URL="https://github.com/prometheus/haproxy_exporter/releases/download/v${EXPORTER_VERSION}/haproxy_exporter-${EXPORTER_VERSION}.linux-amd64.tar.gz"

if command -v haproxy_exporter >/dev/null 2>&1; then
    log_info "haproxy_exporter already installed: $(haproxy_exporter --version 2>&1 | head -1)"
else
    run_or_dry "cd /tmp && wget -q '$EXPORTER_URL' && tar xzf 'haproxy_exporter-${EXPORTER_VERSION}.linux-amd64.tar.gz'"
    run_or_dry "cp '/tmp/haproxy_exporter-${EXPORTER_VERSION}.linux-amd64/haproxy_exporter' /usr/local/bin/"
    run_or_dry "chmod +x /usr/local/bin/haproxy_exporter"
fi

if [ "$DRY_RUN" = true ]; then
    echo "[dry-run] Would write /etc/systemd/system/haproxy-exporter.service"
else
    cat > /etc/systemd/system/haproxy-exporter.service << EOF
[Unit]
Description=HAProxy Prometheus Exporter
After=haproxy.service
Requires=haproxy.service

[Service]
ExecStart=/usr/local/bin/haproxy_exporter --haproxy.scrape-uri="http://${STATS_USER}:${STATS_PASS}@localhost:${STATS_PORT}/stats;csv"
Restart=always
User=haproxy
Group=haproxy

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable haproxy-exporter
    systemctl start haproxy-exporter
    log_info "Prometheus exporter started on port 9101"
fi

# --- Step 8: Log rotation ---
log_info "Step 8/9: Configuring log rotation..."
if [ "$DRY_RUN" = true ]; then
    echo "[dry-run] Would write /etc/logrotate.d/haproxy"
else
    cat > /etc/logrotate.d/haproxy << 'LOGROTATE'
/var/log/haproxy.log {
    daily
    rotate 14
    missingok
    notifempty
    compress
    delaycompress
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
LOGROTATE
fi

# --- Step 9: Firewall (optional) ---
log_info "Step 9/9: Firewall configuration..."
if [ "$FIREWALL" = true ]; then
    command -v ufw >/dev/null 2>&1 || { log_warn "ufw not found, skipping firewall"; }
    run_or_dry "ufw allow ${HTTP_PORT}/tcp comment 'HAProxy HTTP'"
    run_or_dry "ufw allow ${HTTPS_PORT}/tcp comment 'HAProxy HTTPS'"
    run_or_dry "ufw allow ${STATS_PORT}/tcp comment 'HAProxy Stats'"
    run_or_dry "ufw reload"
else
    log_info "Skipping firewall — add rules manually or use --firewall"
fi

# --- Summary ---
log_info "=== Setup Complete ==="
log_info "HTTP frontend:  http://$(hostname -I | awk '{print $1}'):${HTTP_PORT} (redirects to HTTPS)"
log_info "HTTPS frontend: https://$(hostname -I | awk '{print $1}'):${HTTPS_PORT}"
log_info "Stats page:     http://$(hostname -I | awk '{print $1}'):${STATS_PORT}/stats"
log_info "Prometheus:     http://localhost:9101/metrics"
log_info ""
log_info "Verify:  curl -sk https://localhost/health"
log_info "Stats:   curl -s 'http://${STATS_USER}:${STATS_PASS}@localhost:${STATS_PORT}/stats;csv'"
