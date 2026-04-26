#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_NAME="linux-loki-promtail-deploy"
readonly SCRIPT_VERSION="1.0.0"

# Requirements: curl, sudo, systemd (for systemd-based Linux)
# Safety: DRY_RUN=true by default. Use --apply to execute.

usage() {
    cat <<EOF
${SCRIPT_NAME} v${SCRIPT_VERSION}

Usage: ${SCRIPT_NAME} [OPTIONS]

Description:
  Deploys Loki log aggregator and Promtail log shipper on Linux servers.
  Supports single-node deployment and scales to multi-server setups.

Options:
  --apply         Apply changes (default is dry-run)
  --loki-server   Loki server hostname (default: localhost)
  --loki-port     Loki server port (default: 3100)
  --role          Role: loki-server or promtail-client (default: loki-server)
  --storage-path  Path for Loki storage (default: /var/lib/loki)
  --retention     Log retention in hours (default: 720)
  -h, --help  Show this help

Examples:
  # Dry-run Loki server deployment
  ${SCRIPT_NAME} --role loki-server

  # Apply Loki server deployment
  ${SCRIPT_NAME} --role loki-server --apply

  # Deploy Promtail client
  ${SCRIPT_NAME} --role promtail-client --loki-server loki.internal --apply
EOF
}

log_info() { echo -e "[INFO] $*"; }
log_warn() { echo -e "[WARN] $*"; }
log_error() { echo -e "[ERROR] $*"; }
log_success() { echo -e "[SUCCESS] $*"; }

DRY_RUN=true
ROLE="loki-server"
LOKI_HOST="localhost"
LOKI_PORT="3100"
STORAGE_PATH="/var/lib/loki"
RETENTION_HOURS="720"

while [[ $# -gt 0 ]]; do
    case $1 in
        --apply)
            DRY_RUN=false
            shift
            ;;
        --loki-server)
            LOKI_HOST="$2"
            shift 2
            ;;
        --loki-port)
            LOKI_PORT="$2"
            shift 2
            ;;
        --role)
            ROLE="$2"
            shift 2
            ;;
        --storage-path)
            STORAGE_PATH="$2"
            shift 2
            ;;
        --retention)
            RETENTION_HOURS="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

check_dependencies() {
    local deps=("curl" "systemctl")
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "$cmd not found. Please install $cmd first."
            exit 1
        fi
    done
    
    if [[ "$EUID" -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)."
        exit 1
    fi
    
    log_info "All dependencies satisfied"
}

install_loki() {
    log_info "Installing Loki..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warn "[dry-run] Would download and install Loki"
        return 0
    fi
    
    local loki_version="3.2.0"
    
    if command -v apt-get >/dev/null 2>&1; then
        curl -s -L "https://github.com/grafana/loki/releases/download/v${loki_version}/loki_amd64.deb" -o /tmp/loki.deb
        dpkg -i /tmp/loki.deb || apt-get -f install -y
    elif command -v yum >/dev/null 2>&1; then
        curl -s -L "https://github.com/grafana/loki/releases/download/v${loki_version}/loki-3.2.0.x86_64.rpm" -o /tmp/loki.rpm
        yum localinstall -y /tmp/loki.rpm
    else
        log_error "Unsupported package manager"
        return 1
    fi
    
    log_success "Loki installed"
}

configure_loki() {
    log_info "Configuring Loki..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warn "[dry-run] Would configure Loki with storage path: $STORAGE_PATH"
        return 0
    fi
    
    mkdir -p "$STORAGE_PATH" /var/log/loki /etc/loki
    chown -R root:root "$STORAGE_PATH" /var/log/loki
    
    cat > /etc/loki/local-config.yaml <<EOF
auth_enabled: false
server:
  http_listen_port: 3100
  grpc_listen_port: 9096
common:
  path_prefix: $STORAGE_PATH
  storage:
    filesystem:
      chunks_directory: $STORAGE_PATH/chunks
      rules_directory: $STORAGE_PATH/rules
  replication_factor: 1
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory
limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  ingestion_rate_mb: 50
  ingestion_burst_size_mb: 100
schema_config:
  configs:
    - from: 2024-01-01
      store: boltdb-shipper
      object_store: filesystem
      schema: v12
      index:
        prefix: index_
        period: 24h
storage_config:
  boltdb:
    directory: $STORAGE_PATH/index
  filesystem:
    directory: $STORAGE_PATH/chunks
chunk_store_config:
  max_look_back_period: ${RETENTION_HOURS}h
table_manager:
  retention_deletes_enabled: true
  retention_period: ${RETENTION_HOURS}h
EOF
    
    log_success "Loki configured"
}

start_loki_service() {
    log_info "Starting Loki service..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warn "[dry-run] Would start Loki service"
        return 0
    fi
    
    systemctl daemon-reload
    systemctl enable loki
    systemctl start loki
    
    if systemctl is-active --quiet loki; then
        log_success "Loki service started"
    else
        log_error "Loki service failed to start"
        systemctl status loki
        return 1
    fi
}

install_promtail() {
    log_info "Installing Promtail..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warn "[dry-run] Would install and configure Promtail"
        return 0
    fi
    
    local promtail_version="3.2.0"
    
    if command -v apt-get >/dev/null 2>&1; then
        curl -s -L "https://github.com/grafana/loki/releases/download/v${promtail_version}/promtail_amd64.deb" -o /tmp/promtail.deb
        dpkg -i /tmp/promtail.deb || apt-get -f install -y
    elif command -v yum >/dev/null 2>&1; then
        curl -s -L "https://github.com/grafana/loki/releases/download/v${promtail_version}/promtail-3.2.0.x86_64.rpm" -o /tmp/promtail.rpm
        yum localinstall -y /tmp/promtail.rpm
    else
        log_error "Unsupported package manager"
        return 1
    fi
    
    log_success "Promtail installed"
}

configure_promtail() {
    log_info "Configuring Promtail..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warn "[dry-run] Would configure Promtail to send to $LOKI_HOST:$LOKI_PORT"
        return 0
    fi
    
    mkdir -p /var/lib/promtail /var/log/promtail /etc/promtail
    chown -R root:root /var/lib/promtail /var/log/promtail
    
    cat > /etc/promtail/promtail-config.yaml <<EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 9081
clients:
  - endpoint: http://${LOKI_HOST}:${LOKI_PORT}/loki/api/v1/push
    retry_interval: 5s
    batch_timeout: 10s
    external_labels:
      environment: production
      datacenter: dc1
scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: system_logs
          host: $(hostname)
          __path__: /var/log/*.log
  - job_name: auth_logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: auth
          host: $(hostname)
          __path__: /var/log/auth.log
  - job_name: syslog
    syslog:
      listen_address: 0.0.0.0:514
      labels:
        job: syslog
        host: $(hostname)
  - job_name: journal
    journal:
      path: /var/log/journal
      labels:
        job: systemd
        host: $(hostname)
EOF
    
    log_success "Promtail configured"
}

start_promtail_service() {
    log_info "Starting Promtail service..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warn "[dry-run] Would start Promtail service"
        return 0
    fi
    
    systemctl daemon-reload
    systemctl enable promtail
    systemctl start promtail
    
    if systemctl is-active --quiet promtail; then
        log_success "Promtail service started"
    else
        log_error "Promtail service failed to start"
        systemctl status promtail
        return 1
    fi
}

verify_deployment() {
    log_info "Verifying deployment..."
    
    if [[ "$ROLE" == "loki-server" ]]; then
        if curl -s http://localhost:3100/ready | grep -q "ready"; then
            log_success "Loki is ready to accept logs"
        else
            log_error "Loki not ready"
            return 1
        fi
    else
        if curl -s http://localhost:9080/metrics | grep -q "promtail_"; then
            log_success "Promtail is running"
        else
            log_error "Promtail not running"
            return 1
        fi
    fi
    
    log_success "Verification complete"
}

main() {
    log_info "Starting ${SCRIPT_NAME} v${SCRIPT_VERSION}"
    log_info "Role: ${ROLE}"
    log_info "Loki Server: ${LOKI_HOST}:${LOKI_PORT}"
    log_info "Dry-run: ${DRY_RUN}"
    
    check_dependencies
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warn "Running in DRY-RUN mode. Use --apply to execute."
    fi
    
    case "$ROLE" in
        loki-server)
            install_loki
            configure_loki
            start_loki_service
            ;;
        promtail-client)
            install_promtail
            configure_promtail
            start_promtail_service
            ;;
        *)
            log_error "Invalid role: $ROLE"
            exit 1
            ;;
    esac
    
    verify_deployment
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "Run again with --apply to execute changes"
    fi
    
    log_success "Complete"
}

main "$@"