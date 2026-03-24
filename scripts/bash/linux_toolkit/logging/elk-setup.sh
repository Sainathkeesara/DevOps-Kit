#!/usr/bin/env bash
# =============================================================================
# ELK Stack Setup Script for Linux Log Aggregation
# =============================================================================
# Purpose: Install and configure Elasticsearch, Logstash, Kibana, and Filebeat
#          for centralized log aggregation across Linux servers
# Usage: ./elk-setup.sh [--dry-run] [--components COMPONENTS] [--version VERSION]
# Requirements: root privileges, systemd, 4GB+ RAM recommended
# Safety Notes:
#   - Always run with --dry-run first to preview installation steps
#   - This script creates systemd services and modifies network configuration
#   - Backup existing configurations before overwriting
#   - Elasticsearch requires specific kernel parameters
# Tested OS: Ubuntu 20.04/22.04, RHEL 8/9, Debian 11/12
# =============================================================================

set -euo pipefail

DRY_RUN="${DRY_RUN:-true}"
COMPONENTS="${COMPONENTS:-all}"
VERSION="${VERSION:-8.12.0}"
ES_HEAP_SIZE="${ES_HEAP_SIZE:-2g}"
INSTALL_DIR="/opt/elk"
DATA_DIR="/var/lib/elasticsearch"
LOG_DIR="/var/log/elasticsearch"
CONFIG_DIR="/etc/elasticsearch"
SYSTEMD_DIR="/etc/systemd/system"
KIBANA_PORT="${KIBANA_PORT:-5601}"
ES_PORT="${ES_PORT:-9200}"
ES_MEM_LIMIT="${ES_MEM_LIMIT:-4g}"

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Install and configure ELK stack for centralized log aggregation

OPTIONS:
    --dry-run          Preview installation steps without executing (default: true)
    --components COMP  Components to install: all|elasticsearch|logstash|kibana|filebeat (default: all)
    --version VERSION  Elasticsearch/ELK version (default: 8.12.0)
    --es-heap-size    Elasticsearch heap size (default: 2g)
    --kibana-port     Kibana web port (default: 5601)
    -h, --help        Show this help message

Examples:
    $0 --dry-run
    $0 --components all --version 8.12.0
    DRY_RUN=false $0 --components elasticsearch,kibana

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
    required_cmds=("curl" "wget" "tar" "systemctl" "java")
    
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log "WARN" "Command '$cmd' not found - some features may not work"
        fi
    done
    
    log "INFO" "Dependency check complete"
}

configure_kernel() {
    log "INFO" "Configuring kernel parameters for Elasticsearch..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would configure kernel parameters"
        return 0
    fi
    
    cat >> /etc/sysctl.conf <<EOF

# Elasticsearch required parameters
vm.max_map_count=262144
fs.file-max=65536
EOF
    
    sysctl -w vm.max_map_count=262144 2>/dev/null || true
    sysctl -w fs.file-max=65536 2>/dev/null || true
    
    cat >> /etc/security/limits.conf <<EOF

# Elasticsearch required limits
elasticsearch soft nofile 65536
elasticsearch hard nofile 65536
elasticsearch soft nproc 4096
elasticsearch hard nproc 4096
EOF
    
    log "INFO" "Kernel parameters configured"
}

install_elasticsearch() {
    local es_dir="$INSTALL_DIR/elasticsearch"
    
    if [[ "$COMPONENTS" != "all" ]] && [[ "$COMPONENTS" != *"elasticsearch"* ]]; then
        log "INFO" "Skipping Elasticsearch (not in components list)"
        return 0
    fi
    
    log "INFO" "Installing Elasticsearch $VERSION..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would install Elasticsearch $VERSION to $es_dir"
        return 0
    fi
    
    mkdir -p "$es_dir" "$DATA_DIR" "$LOG_DIR" "$CONFIG_DIR"
    
    local download_url="https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${VERSION}-linux-x86_64.tar.gz"
    local download_file="/tmp/elasticsearch-${VERSION}.tar.gz"
    
    log "INFO" "Downloading Elasticsearch from $download_url"
    
    if curl -L --progress-bar "$download_url" -o "$download_file"; then
        log "INFO" "Download complete, extracting..."
        tar -xzf "$download_file" -C /tmp/
        cp -r /tmp/elasticsearch-${VERSION}/* "$es_dir/"
        
        chown -R root:root "$es_dir"
        chown -R elasticsearch:elasticsearch "$DATA_DIR" "$LOG_DIR"
        
        rm -rf /tmp/elasticsearch-${VERSION} "$download_file"
        log "INFO" "Elasticsearch installed to $es_dir"
    else
        log "ERROR" "Failed to download Elasticsearch"
        return 1
    fi
}

configure_elasticsearch() {
    if [[ "$COMPONENTS" != "all" ]] && [[ "$COMPONENTS" != *"elasticsearch"* ]]; then
        return 0
    fi
    
    log "INFO" "Configuring Elasticsearch..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would configure Elasticsearch"
        return 0
    fi
    
    cat > "$CONFIG_DIR/elasticsearch.yml" <<EOF
cluster.name: elk-cluster
node.name: \${HOSTNAME}
path.data: $DATA_DIR
path.logs: $LOG_DIR
network.host: 0.0.0.0
http.port: $ES_PORT
discovery.type: single-node
xpack.security.enabled: true
xpack.security.http.ssl.enabled: false
xpack.security.transport.ssl.enabled: false
EOF

    cat > "$CONFIG_DIR/jvm.options.d/heap.options" <<EOF
-Xms$ES_HEAP_SIZE
-Xmx$ES_HEAP_SIZE
EOF

    if ! id elasticsearch &>/dev/null; then
        useradd --no-create-home --shell /usr/sbin/nologin elasticsearch 2>/dev/null || true
    fi
    
    chown -R elasticsearch:elasticsearch "$DATA_DIR" "$LOG_DIR" "$CONFIG_DIR"
    
    log "INFO" "Elasticsearch configured"
}

install_logstash() {
    if [[ "$COMPONENTS" != "all" ]] && [[ "$COMPONENTS" != *"logstash"* ]]; then
        log "INFO" "Skipping Logstash (not in components list)"
        return 0
    fi
    
    log "INFO" "Installing Logstash $VERSION..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would install Logstash $VERSION"
        return 0
    fi
    
    local ls_dir="$INSTALL_DIR/logstash"
    local download_url="https://artifacts.elastic.co/downloads/logstash/logstash-${VERSION}-linux-x86_64.tar.gz"
    local download_file="/tmp/logstash-${VERSION}.tar.gz"
    
    mkdir -p "$ls_dir" "$CONFIG_DIR/logstash" "/var/lib/logstash"
    
    log "INFO" "Downloading Logstash from $download_url"
    
    if curl -L --progress-bar "$download_url" -o "$download_file"; then
        log "INFO" "Download complete, extracting..."
        tar -xzf "$download_file" -C /tmp/
        cp -r /tmp/logstash-${VERSION}/* "$ls_dir/"
        
        rm -rf /tmp/logstash-${VERSION} "$download_file"
        log "INFO" "Logstash installed to $ls_dir"
    else
        log "ERROR" "Failed to download Logstash"
        return 1
    fi
}

configure_logstash() {
    if [[ "$COMPONENTS" != "all" ]] && [[ "$COMPONENTS" != *"logstash"* ]]; then
        return 0
    fi
    
    log "INFO" "Configuring Logstash..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would configure Logstash pipeline"
        return 0
    fi
    
    mkdir -p "$CONFIG_DIR/logstash/pipeline"
    
    cat > "$CONFIG_DIR/logstash/pipeline/01-logs.conf" <<EOF
input {
  beats {
    port => 5044
  }
  file {
    path => "/var/log/*.log"
    start_position => "beginning"
  }
}

filter {
  if [message] =~ /ERROR/ {
    mutate { add_tag => ["error"] }
  }
  if [message] =~ /WARN/ {
    mutate { add_tag => ["warning"] }
  }
  grok {
    match => { "message" => "%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{GREEDYDATA:log_message}" }
  }
  date {
    match => [ "timestamp", "ISO8601" ]
  }
}

output {
  elasticsearch {
    hosts => ["localhost:$ES_PORT"]
    index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
  }
}
EOF

    log "INFO" "Logstash configured"
}

install_kibana() {
    if [[ "$COMPONENTS" != "all" ]] && [[ "$COMPONENTS" != *"kibana"* ]]; then
        log "INFO" "Skipping Kibana (not in components list)"
        return 0
    fi
    
    log "INFO" "Installing Kibana $VERSION..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would install Kibana $VERSION"
        return 0
    fi
    
    local kb_dir="$INSTALL_DIR/kibana"
    local download_url="https://artifacts.elastic.co/downloads/kibana/kibana-${VERSION}-linux-x86_64.tar.gz"
    local download_file="/tmp/kibana-${VERSION}.tar.gz"
    
    mkdir -p "$kb_dir" "$CONFIG_DIR/kibana"
    
    log "INFO" "Downloading Kibana from $download_url"
    
    if curl -L --progress-bar "$download_url" -o "$download_file"; then
        log "INFO" "Download complete, extracting..."
        tar -xzf "$download_file" -C /tmp/
        cp -r /tmp/kibana-${VERSION}/* "$kb_dir/"
        
        rm -rf /tmp/kibana-${VERSION} "$download_file"
        log "INFO" "Kibana installed to $kb_dir"
    else
        log "ERROR" "Failed to download Kibana"
        return 1
    fi
}

configure_kibana() {
    if [[ "$COMPONENTS" != "all" ]] && [[ "$COMPONENTS" != *"kibana"* ]]; then
        return 0
    fi
    
    log "INFO" "Configuring Kibana..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would configure Kibana"
        return 0
    fi
    
    cat > "$CONFIG_DIR/kibana/kibana.yml" <<EOF
server.port: $KIBANA_PORT
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://localhost:$ES_PORT"]
elasticsearch.username: "elastic"
elasticsearch.password: "changeme"
logging.dest: /var/log/kibana/kibana.log
logging.quiet: false
EOF

    mkdir -p /var/log/kibana
    chown -R kibana:kibana "$CONFIG_DIR/kibana" /var/log/kibana
    
    log "INFO" "Kibana configured"
}

install_filebeat() {
    if [[ "$COMPONENTS" != "all" ]] && [[ "$COMPONENTS" != *"filebeat"* ]]; then
        log "INFO" "Skipping Filebeat (not in components list)"
        return 0
    fi
    
    log "INFO" "Installing Filebeat..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would install Filebeat"
        return 0
    fi
    
    local download_url="https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${VERSION}-linux-x86_64.tar.gz"
    local download_file="/tmp/filebeat-${VERSION}.tar.gz"
    local fb_dir="$INSTALL_DIR/filebeat"
    
    mkdir -p "$fb_dir" "$CONFIG_DIR/filebeat"
    
    log "INFO" "Downloading Filebeat from $download_url"
    
    if curl -L --progress-bar "$download_url" -o "$download_file"; then
        log "INFO" "Download complete, extracting..."
        tar -xzf "$download_file" -C /tmp/
        cp -r /tmp/filebeat-${VERSION}/* "$fb_dir/"
        
        rm -rf /tmp/filebeat-${VERSION} "$download_file"
        log "INFO" "Filebeat installed to $fb_dir"
    else
        log "ERROR" "Failed to download Filebeat"
        return 1
    fi
}

configure_filebeat() {
    if [[ "$COMPONENTS" != "all" ]] && [[ "$COMPONENTS" != *"filebeat"* ]]; then
        return 0
    fi
    
    log "INFO" "Configuring Filebeat..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would configure Filebeat"
        return 0
    fi
    
    cat > "$CONFIG_DIR/filebeat/filebeat.yml" <<EOF
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*.log
    - /var/log/syslog
  fields:
    service: syslog
  fields_under_root: true

output.logstash:
  hosts: ["localhost:5044"]

processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
EOF

    chown -R root:root "$CONFIG_DIR/filebeat"
    
    log "INFO" "Filebeat configured"
}

create_systemd_services() {
    log "INFO" "Creating systemd services..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would create systemd services"
        return 0
    fi
    
    if [[ "$COMPONENTS" == "all" ]] || [[ "$COMPONENTS" == *"elasticsearch"* ]]; then
        cat > "$SYSTEMD_DIR/elasticsearch.service" <<EOF
[Unit]
Description=Elasticsearch
Documentation=https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=elasticsearch
Group=elasticsearch
ExecStart=$INSTALL_DIR/elasticsearch/bin/elasticsearch
Restart=on-failure
RestartSec=30s

[Install]
WantedBy=multi-user.target
EOF
    fi
    
    if [[ "$COMPONENTS" == "all" ]] || [[ "$COMPONENTS" == *"logstash"* ]]; then
        cat > "$SYSTEMD_DIR/logstash.service" <<EOF
[Unit]
Description=Logstash
Documentation=https://www.elastic.co/guide/en/logstash/current/index.html
Wants=network-online.target
After=network-online.target elasticsearch.service

[Service]
Type=simple
User=root
Group=root
ExecStart=$INSTALL_DIR/logstash/bin/logstash --path.settings $CONFIG_DIR/logstash
Restart=on-failure
RestartSec=30s

[Install]
WantedBy=multi-user.target
EOF
    fi
    
    if [[ "$COMPONENTS" == "all" ]] || [[ "$COMPONENTS" == *"kibana"* ]]; then
        cat > "$SYSTEMD_DIR/kibana.service" <<EOF
[Unit]
Description=Kibana
Documentation=https://www.elastic.co/guide/en/kibana/current/index.html
Wants=network-online.target
After=network-online.target elasticsearch.service

[Service]
Type=simple
User=kibana
Group=kibana
ExecStart=$INSTALL_DIR/kibana/bin/kibana --config $CONFIG_DIR/kibana/kibana.yml
Restart=on-failure
RestartSec=30s

[Install]
WantedBy=multi-user.target
EOF
    fi
    
    if [[ "$COMPONENTS" == "all" ]] || [[ "$COMPONENTS" == *"filebeat"* ]]; then
        cat > "$SYSTEMD_DIR/filebeat.service" <<EOF
[Unit]
Description=Filebeat
Documentation=https://www.elastic.co/guide/en/beats/filebeat/current/index.html
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
Group=root
ExecStart=$INSTALL_DIR/filebeat/filebeat -c $CONFIG_DIR/filebeat/filebeat.yml
Restart=on-failure
RestartSec=30s

[Install]
WantedBy=multi-user.target
EOF
    fi
    
    systemctl daemon-reload
    log "INFO" "Systemd services created"
}

start_services() {
    log "INFO" "Starting ELK services..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would start ELK services"
        return 0
    fi
    
    if [[ "$COMPONENTS" == "all" ]] || [[ "$COMPONENTS" == *"elasticsearch"* ]]; then
        systemctl enable elasticsearch
        systemctl start elasticsearch
        sleep 10
        log "INFO" "Elasticsearch started"
    fi
    
    if [[ "$COMPONENTS" == "all" ]] || [[ "$COMPONENTS" == *"logstash"* ]]; then
        systemctl enable logstash
        systemctl start logstash
        log "INFO" "Logstash started"
    fi
    
    if [[ "$COMPONENTS" == "all" ]] || [[ "$COMPONENTS" == *"kibana"* ]]; then
        systemctl enable kibana
        systemctl start kibana
        log "INFO" "Kibana started"
    fi
    
    if [[ "$COMPONENTS" == "all" ]] || [[ "$COMPONENTS" == *"filebeat"* ]]; then
        systemctl enable filebeat
        systemctl start filebeat
        log "INFO" "Filebeat started"
    fi
}

verify_installation() {
    log "INFO" "Verifying installation..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Skipping verification"
        return 0
    fi
    
    if [[ "$COMPONENTS" == "all" ]] || [[ "$COMPONENTS" == *"elasticsearch"* ]]; then
        local max_retries=10
        local retry=0
        
        while [[ $retry -lt $max_retries ]]; do
            if curl -s "http://localhost:$ES_PORT" | grep -q "cluster_name"; then
                log "INFO" "Elasticsearch is responding on port $ES_PORT"
                return 0
            fi
            ((retry++))
            sleep 3
        done
        log "WARN" "Could not verify Elasticsearch - may need manual check"
    fi
    
    if [[ "$COMPONENTS" == "all" ]] || [[ "$COMPONENTS" == *"kibana"* ]]; then
        log "INFO" "Kibana available at http://localhost:$KIBANA_PORT"
    fi
}

print_summary() {
    log "INFO" "=============================================="
    log "INFO" "  ELK Stack Installation Complete"
    log "INFO" "=============================================="
    log "INFO" "Components    : $COMPONENTS"
    log "INFO" "Version       : $VERSION"
    log "INFO" "ES Heap Size : $ES_HEAP_SIZE"
    log "INFO" ""
    log "INFO" "Services:"
    [[ "$COMPONENTS" == "all" ]] || [[ "$COMPONENTS" == *"elasticsearch"* ]] && \
        log "INFO" "  - Elasticsearch: http://localhost:$ES_PORT"
    [[ "$COMPONENTS" == "all" ]] || [[ "$COMPONENTS" == *"logstash"* ]] && \
        log "INFO" "  - Logstash:      Beats on port 5044"
    [[ "$COMPONENTS" == "all" ]] || [[ "$COMPONENTS" == *"kibana"* ]] && \
        log "INFO" "  - Kibana:        http://localhost:$KIBANA_PORT"
    [[ "$COMPONENTS" == "all" ]] || [[ "$COMPONENTS" == *"filebeat"* ]] && \
        log "INFO" "  - Filebeat:      Running, sending to Logstash"
    log "INFO" ""
    log "INFO" "Default credentials:"
    log "INFO" "  Username: elastic"
    log "INFO" "  Password: changeme"
    log "INFO" ""
    log "INFO" "Next steps:"
    log "INFO" "  1. Change default elastic password: curl -X POST -u elastic:changeme 'localhost:9200/_security/user/elastic/_password' -d '{\"password\":\"your_new_password\"}'"
    log "INFO" "  2. Access Kibana at http://localhost:$KIBANA_PORT"
    log "INFO" "  3. Configure Filebeat on client servers"
    log "INFO" "=============================================="
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --components)
                COMPONENTS="$2"
                shift 2
                ;;
            --version)
                VERSION="$2"
                shift 2
                ;;
            --es-heap-size)
                ES_HEAP_SIZE="$2"
                shift 2
                ;;
            --kibana-port)
                KIBANA_PORT="$2"
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
    
    log "INFO" "ELK Stack Setup Starting..."
    log "INFO" "Dry-run mode: $DRY_RUN"
    log "INFO" "Components: $COMPONENTS"
    log "INFO" "Version: $VERSION"
    
    check_root
    check_dependencies
    configure_kernel
    install_elasticsearch
    configure_elasticsearch
    install_logstash
    configure_logstash
    install_kibana
    configure_kibana
    install_filebeat
    configure_filebeat
    create_systemd_services
    start_services
    verify_installation
    print_summary
    
    log "INFO" "Setup complete"
}

main "$@"
