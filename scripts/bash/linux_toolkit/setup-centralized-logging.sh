#!/usr/bin/env bash
set -euo pipefail

# Centralized Logging Setup — syslog-ng + Logstash + Elasticsearch
# Purpose: Deploy a production-grade centralized logging pipeline on Linux
# Usage: ./setup-centralized-logging.sh --action <install|configure|verify|remove>
# Requirements: sudo, apt-get or dnf, curl, java 17+
# Safety: DRY_RUN=true by default — set DRY_RUN=false for actual deployment
# Tested on: Ubuntu 22.04, RHEL 9

DRY_RUN="${DRY_RUN:-true}"
ACTION=""
LOG_SERVER="${LOG_SERVER:-localhost}"
ES_URL="${ES_URL:-http://localhost:9200}"
LOGSTASH_TCP_PORT="${LOGSTASH_TCP_PORT:-5140}"
SYSLOG_TCP_PORT="${SYSLOG_TCP_PORT:-514}"
SYSLOG_UDP_PORT="${SYSLOG_UDP_PORT:-514}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_dependencies() {
    local deps=("curl" "java")
    for dep in "${deps[@]}"; do
        command -v "$dep" >/dev/null 2>&1 || { log_error "$dep not found — install it first"; exit 1; }
    done

    if java -version 2>&1 | grep -q "version \"1[7-9]\|version \"2[0-9]"; then
        log_info "Java version OK"
    else
        log_error "Java 17+ required. Found: $(java -version 2>&1 | head -1)"
        exit 1
    fi

    log_info "All dependencies satisfied"
}

detect_package_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    else
        log_error "Unsupported package manager. Requires apt-get or dnf."
        exit 1
    fi
}

install_syslog_ng() {
    local pkg_mgr
    pkg_mgr=$(detect_package_manager)

    log_info "Installing syslog-ng..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would install syslog-ng via $pkg_mgr"
        return 0
    fi

    if [ "$pkg_mgr" = "apt" ]; then
        sudo apt-get update -qq
        sudo apt-get install -y syslog-ng syslog-ng-mod-json syslog-ng-mod-geoip
    else
        sudo dnf install -y syslog-ng syslog-ng-json syslog-ng-geoip
    fi

    log_info "syslog-ng installed: $(syslog-ng --version 2>&1 | head -1)"
}

install_logstash() {
    log_info "Installing Logstash..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would install Logstash from Elastic repository"
        return 0
    fi

    local pkg_mgr
    pkg_mgr=$(detect_package_manager)

    if [ "$pkg_mgr" = "apt" ]; then
        wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elastic-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/elastic-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
        sudo apt-get update -qq
        sudo apt-get install -y logstash
    else
        sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
        cat <<EOF | sudo tee /etc/yum.repos.d/elastic.repo
[elastic-8.x]
name=Elastic repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
        sudo dnf install -y logstash
    fi

    log_info "Logstash installed"
}

install_elasticsearch() {
    log_info "Installing Elasticsearch..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would install Elasticsearch"
        return 0
    fi

    local pkg_mgr
    pkg_mgr=$(detect_package_manager)

    if [ "$pkg_mgr" = "apt" ]; then
        sudo apt-get install -y elasticsearch
    else
        sudo dnf install -y elasticsearch
    fi

    sudo systemctl enable elasticsearch
    sudo systemctl start elasticsearch

    log_info "Waiting for Elasticsearch to start..."
    local retries=0
    while ! curl -s "${ES_URL}/_cluster/health" | grep -q '"status"'; do
        retries=$((retries + 1))
        if [ $retries -gt 60 ]; then
            log_error "Elasticsearch did not start within 60 seconds"
            exit 1
        fi
        sleep 1
    done

    log_info "Elasticsearch is running"
}

configure_syslog_ng() {
    log_info "Configuring syslog-ng..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would configure syslog-ng"
        return 0
    fi

    if [ ! -f /etc/syslog-ng/syslog-ng.conf ]; then
        log_error "syslog-ng not installed. Run --action install first."
        exit 1
    fi

    sudo cp /etc/syslog-ng/syslog-ng.conf "/etc/syslog-ng/syslog-ng.conf.bak.$(date +%Y%m%d%H%M%S)"

    sudo tee /etc/syslog-ng/syslog-ng.conf > /dev/null <<'SYSLOG_CONF'
@version: 4.5
@include "scl.conf"

options {
    chain-hostnames(no);
    create-dirs(yes);
    dir-group("adm");
    dir-perm(0750);
    group("adm");
    keep-hostname(yes);
    log-fifo-size(10000);
    perm(0640);
    time-reopen(10);
    use-dns(no);
    use-fqdn(no);
};

source s_local {
    system();
    internal();
};

source s_remote_tcp {
    tcp(
        ip("0.0.0.0")
        port(SYSLOG_TCP_PORT)
        max-connections(100)
        log-iw-size(10000)
    );
};

source s_remote_udp {
    udp(
        ip("0.0.0.0")
        port(SYSLOG_UDP_PORT)
    );
};

filter f_auth   { facility(auth, authpriv); };
filter f_kernel { facility(kern); };
filter f_cron   { facility(cron); };
filter f_err    { level(err..emerg); };

rewrite r_add_host {
    set("${HOST}", value(".metadata.hostname"));
    set("${ISODATE}", value(".metadata.received_at"));
};

destination d_centralized {
    file(
        "/var/log/centralized/all.json"
        template("$(format-json --scope dot-nv-pairs --exclude 0*,1*,2*,3*,4*,5*,6*,7*,8*,9* --key .metadata.* --pair @timestamp='${ISODATE}' --pair hostname='${HOST}' --pair program='${PROGRAM}' --pair severity='${LEVEL}' --pair facility='${FACILITY}' --pair message='${MESSAGE}')\n")
        create-dirs(yes)
    );
};

destination d_logstash {
    tcp(
        "LOG_SERVER"
        port(SYSLOG_TCP_PORT)
        log-fifo-size(10000)
        flags(no-multi-line)
    );
};

destination d_auth_logs {
    file("/var/log/centralized/auth.log");
};

destination d_kernel_logs {
    file("/var/log/centralized/kern.log");
};

log { source(s_local);      rewrite(r_add_host); destination(d_centralized); };
log { source(s_remote_tcp);  rewrite(r_add_host); destination(d_centralized); };
log { source(s_remote_udp);  rewrite(r_add_host); destination(d_centralized); };
log { source(s_local);      filter(f_auth);      destination(d_auth_logs); };
log { source(s_remote_tcp);  filter(f_auth);      destination(d_auth_logs); };
log { source(s_local);      filter(f_kernel);    destination(d_kernel_logs); };
SYSLOG_CONF

    sudo sed -i "s|LOG_SERVER|${LOG_SERVER}|g" /etc/syslog-ng/syslog-ng.conf
    sudo sed -i "s|SYSLOG_TCP_PORT|${SYSLOG_TCP_PORT}|g" /etc/syslog-ng/syslog-ng.conf
    sudo sed -i "s|SYSLOG_UDP_PORT|${SYSLOG_UDP_PORT}|g" /etc/syslog-ng/syslog-ng.conf

    sudo mkdir -p /var/log/centralized
    sudo chown syslog:adm /var/log/centralized
    sudo chmod 0750 /var/log/centralized

    if syslog-ng --syntax-only 2>&1; then
        log_info "syslog-ng configuration validated"
    else
        log_error "syslog-ng configuration syntax error"
        exit 1
    fi
}

configure_logstash() {
    log_info "Configuring Logstash pipeline..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would configure Logstash pipeline"
        return 0
    fi

    sudo mkdir -p /etc/logstash/conf.d

    sudo tee /etc/logstash/conf.d/centralized-logging.conf > /dev/null <<LOGSTASH_CONF
input {
  tcp {
    port => ${LOGSTASH_TCP_PORT}
    codec => json
    type => "syslog-ng"
  }
  beats {
    port => 5044
    type => "beats"
  }
}

filter {
  if [type] == "syslog-ng" {
    date {
      match => ["@timestamp", "ISO8601"]
      target => "@timestamp"
    }
    if [program] == "sshd" and [message] =~ "Accepted|Failed" {
      grok {
        match => { "message" => "for %{USER:ssh_user} from %{IP:source_ip} port %{INT:source_port}" }
      }
      if [source_ip] {
        geoip {
          source => "source_ip"
          target => "geoip"
        }
      }
      mutate {
        add_field => { "auth_event" => "true" }
      }
    }
    mutate {
      lowercase => [ "severity" ]
      add_field => { "pipeline_version" => "1.0" }
    }
  }
}

output {
  if [type] == "syslog-ng" {
    elasticsearch {
      hosts => ["${ES_URL}"]
      index => "centralized-logs-%{+YYYY.MM.dd}"
      template_name => "centralized-logs"
    }
  }
  if [type] == "beats" {
    elasticsearch {
      hosts => ["${ES_URL}"]
      index => "beats-logs-%{+YYYY.MM.dd}"
    }
  }
}
LOGSTASH_CONF

    if sudo /usr/share/logstash/bin/logstash --config.test_and_exit -f /etc/logstash/conf.d/centralized-logging.conf 2>&1; then
        log_info "Logstash pipeline configuration validated"
    else
        log_error "Logstash pipeline configuration error"
        exit 1
    fi
}

create_index_template() {
    log_info "Creating Elasticsearch index template..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would create Elasticsearch index template"
        return 0
    fi

    curl -s -X PUT "${ES_URL}/_index_template/centralized-logs" \
        -H 'Content-Type: application/json' \
        -d '{
        "index_patterns": ["centralized-logs-*"],
        "template": {
            "settings": {
                "number_of_shards": 2,
                "number_of_replicas": 1
            },
            "mappings": {
                "properties": {
                    "@timestamp": { "type": "date" },
                    "hostname": { "type": "keyword" },
                    "program": { "type": "keyword" },
                    "severity": { "type": "keyword" },
                    "facility": { "type": "keyword" },
                    "message": { "type": "text" },
                    "source_ip": { "type": "ip" },
                    "geoip": {
                        "properties": {
                            "location": { "type": "geo_point" },
                            "country_name": { "type": "keyword" },
                            "city_name": { "type": "keyword" }
                        }
                    }
                }
            }
        }
    }' > /dev/null

    log_info "Index template created"
}

start_services() {
    log_info "Starting services..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would start syslog-ng, logstash, elasticsearch"
        return 0
    fi

    sudo systemctl enable syslog-ng
    sudo systemctl restart syslog-ng
    log_info "syslog-ng started: $(systemctl is-active syslog-ng)"

    sudo systemctl enable logstash
    sudo systemctl restart logstash
    log_info "Logstash started: $(systemctl is-active logstash)"

    sudo systemctl enable elasticsearch
    sudo systemctl restart elasticsearch
    log_info "Elasticsearch started: $(systemctl is-active elasticsearch)"
}

verify_installation() {
    log_info "=== Verification ==="

    echo ""
    echo "  syslog-ng status:   $(systemctl is-active syslog-ng 2>/dev/null || echo 'not installed')"
    echo "  Logstash status:    $(systemctl is-active logstash 2>/dev/null || echo 'not installed')"
    echo "  Elasticsearch:      $(systemctl is-active elasticsearch 2>/dev/null || echo 'not installed')"
    echo ""

    if systemctl is-active --quiet syslog-ng; then
        local syslog_stats
        syslog_stats=$(syslog-ng --stats 2>/dev/null | grep -c "processed" || echo "0")
        echo "  syslog-ng sources:  $syslog_stats"
    fi

    if curl -s "${ES_URL}/_cluster/health" > /dev/null 2>&1; then
        local es_status
        es_status=$(curl -s "${ES_URL}/_cluster/health" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        echo "  ES cluster health:  $es_status"
    fi

    if curl -s "http://localhost:9600/_node/stats" > /dev/null 2>&1; then
        local logstash_events
        logstash_events=$(curl -s "http://localhost:9600/_node/stats/pipelines" | grep -o '"events_in":\([0-9]*\)' | head -1 | cut -d: -f2)
        echo "  Logstash events in: ${logstash_events:-0}"
    fi

    echo ""
    log_info "Verification complete."
}

action_install() {
    check_dependencies
    install_syslog_ng
    install_logstash
    install_elasticsearch
    log_info "All components installed."
}

action_configure() {
    configure_syslog_ng
    configure_logstash
    create_index_template
    start_services
    log_info "All components configured and started."
}

action_verify() {
    verify_installation
}

action_remove() {
    log_warn "REMOVING centralized logging components..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would stop and remove all components"
        return 0
    fi

    sudo systemctl stop logstash syslog-ng elasticsearch 2>/dev/null || true
    sudo systemctl disable logstash syslog-ng elasticsearch 2>/dev/null || true
    sudo rm -f /etc/logstash/conf.d/centralized-logging.conf
    sudo rm -rf /var/log/centralized
    log_info "Services stopped and configs removed."
}

show_usage() {
    cat << EOF
Usage: $0 --action <ACTION> [OPTIONS]

Actions:
    install     Install syslog-ng, Logstash, and Elasticsearch
    configure   Configure all components and start services
    verify      Check status of all components
    remove      Stop services and remove configs

Options:
    --server HOST       Logging server hostname (default: localhost)
    --es-url URL        Elasticsearch URL (default: http://localhost:9200)
    -h, --help          Show this help message

Environment Variables:
    DRY_RUN             Set to 'false' to perform actual changes (default: true)
    LOG_SERVER          Same as --server
    ES_URL              Same as --es-url

Examples:
    $0 --action install
    DRY_RUN=false $0 --action install
    DRY_RUN=false $0 --action configure --server logs.example.com
    $0 --action verify
EOF
}

main() {
    while [ $# -gt 0 ]; do
        case $1 in
            --action)   ACTION="$2"; shift 2 ;;
            --server)   LOG_SERVER="$2"; shift 2 ;;
            --es-url)   ES_URL="$2"; shift 2 ;;
            -h|--help)  show_usage; exit 0 ;;
            *)          log_error "Unknown option: $1"; show_usage; exit 1 ;;
        esac
    done

    if [ -z "$ACTION" ]; then
        log_error "No action specified. Use --action <install|configure|verify|remove>"
        show_usage
        exit 1
    fi

    log_info "=== Centralized Logging Setup ==="
    log_info "Action    : $ACTION"
    log_info "Server    : $LOG_SERVER"
    log_info "ES URL    : $ES_URL"
    log_info "DRY_RUN   : $DRY_RUN"
    echo ""

    case $ACTION in
        install)   action_install ;;
        configure) action_configure ;;
        verify)    action_verify ;;
        remove)    action_remove ;;
        *)         log_error "Unknown action: $ACTION"; show_usage; exit 1 ;;
    esac

    echo ""
    log_info "=== Done ==="
}

main "$@"
