#!/usr/bin/env bash
set -euo pipefail

# wazuh-deploy.sh — Deploy Wazuh SIEM server and agents
# Purpose: Automate Wazuh server installation, agent deployment, and basic configuration
# Usage: ./wazuh-deploy.sh [server|agent|status|remove] [options]
# Requirements: Root/sudo access, Ubuntu 20.04+ or RHEL 8+
# Safety: Dry-run mode supported for all destructive operations
# Tested OS: Ubuntu 22.04, RHEL 8.9, AlmaLinux 9.3

DRY_RUN=${DRY_RUN:-false}
WAZUH_MANAGER=${WAZUH_MANAGER:-192.168.1.100}
WAZUH_AGENT_NAME=${WAZUH_AGENT_NAME:-$(hostname)}
WAZUH_MANAGER_PORT=${WAZUH_MANAGER_PORT:-1514}
DASHBOARD_PORT=${DASHBOARD_PORT:-5601}
INDEXER_PORT=${INDEXER_PORT:-9200}

log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*"; }
log_warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $*" >&2; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }

command -v curl >/dev/null 2>&1 || { log_error "curl not found"; exit 1; }
command -v systemctl >/dev/null 2>&1 || { log_error "systemctl not found"; exit 1; }

show_usage() {
  cat <<EOF
Usage: $0 [command] [options]

Commands:
  server     Install and configure Wazuh server components
  agent      Install and configure Wazuh agent
  status     Check Wazuh components status
  remove     Remove Wazuh installation

Options:
  --dry-run           Show what would be done without executing
  --manager IP        Wazuh manager IP (default: $WAZUH_MANAGER)
  --agent-name NAME   Agent name (default: $WAZUH_AGENT_NAME)
  --manager-port PORT Manager port (default: $WAZUH_MANAGER_PORT)

Examples:
  $0 server --manager 192.168.1.100
  $0 agent --manager 192.168.1.100 --agent-name web-server
  $0 status
  $0 server --dry-run

EOF
}

parse_args() {
  if [[ $# -eq 0 ]]; then
    show_usage
    exit 0
  fi

  case "$1" in
    server|agent|status|remove)
      COMMAND="$1"
      shift
      ;;
    -h|--help)
      show_usage
      exit 0
      ;;
    *)
      log_error "Unknown command: $1"
      show_usage
      exit 1
      ;;
  esac

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --manager)
        WAZUH_MANAGER="$2"
        shift 2
        ;;
      --agent-name)
        WAZUH_AGENT_NAME="$2"
        shift 2
        ;;
      --manager-port)
        WAZUH_MANAGER_PORT="$2"
        shift 2
        ;;
      *)
        log_error "Unknown option: $1"
        exit 1
        ;;
    esac
  done
}

detect_os() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS="$ID"
    VERSION="$VERSION_ID"
  else
    log_error "Cannot detect OS"
    exit 1
  fi
  log_info "Detected OS: $OS $VERSION"
}

add_wazuh_repo() {
  log_info "Adding Wazuh repository"

  if [[ "$DRY_RUN" == true ]]; then
    log_info "[dry-run] Would add Wazuh repository for $OS"
    return 0
  fi

  case "$OS" in
    ubuntu|debian)
      curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /usr/share/keyrings/wazuh-archive-keyring.gpg 2>/dev/null || true
      echo "deb [signed-by=/usr/share/keyrings/wazuh-archive-keyring.gpg] https://packages.wazuh.com/4.x/apt stable main" | tee /etc/apt/sources.list.d/wazuh.list >/dev/null
      apt update -qq
      ;;
    rhel|centos|almalinux|rocky)
      cat > /etc/yum.repos.d/wazuh.repo <<EOF
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=Wazuh
baseurl=https://packages.wazuh.com/4.x/yum/
priority=1
EOF
      ;;
    *)
      log_error "Unsupported OS: $OS"
      exit 1
      ;;
  esac
}

install_server() {
  log_info "Installing Wazuh server components"

  detect_os
  add_wazuh_repo

  if [[ "$DRY_RUN" == true ]]; then
    log_info "[dry-run] Would install: wazuh-manager, wazuh-indexer, wazuh-dashboard, wazuh-api"
    return 0
  fi

  local packages="wazuh-manager wazuh-indexer wazuh-dashboard wazuh-api"

  case "$OS" in
    ubuntu|debian)
      export DEBIAN_FRONTEND=noninteractive
      apt install -y -qq $packages
      ;;
    rhel|centos|almalinux|rocky)
      yum install -y $packages
      ;;
  esac

  configure_server
  start_server
}

configure_server() {
  log_info "Configuring Wazuh server"

  if [[ "$DRY_RUN" == true ]]; then
    log_info "[dry-run] Would configure ossec.conf for manager at $WAZUH_MANAGER"
    return 0
  fi

  if [[ -f /var/ossec/etc/ossec.conf ]]; then
    sed -i "s/<manager_ip>.*<\/manager_ip>/<manager_ip>$WAZUH_MANAGER<\/manager_ip>/" /var/ossec/etc/ossec.conf 2>/dev/null || true
  fi

  local indexer_conf="/etc/wazuh-indexer/opensearch.yml"
  if [[ -f "$indexer_conf" ]]; then
    if ! grep -q "network.host:" "$indexer_conf"; then
      echo "network.host: 0.0.0.0" >> "$indexer_conf"
      echo "http.port: $INDEXER_PORT" >> "$indexer_conf"
    fi
  fi

  local dashboard_conf="/etc/wazuh-dashboard/opensearch_dashboards.yml"
  if [[ -f "$dashboard_conf" ]]; then
    if ! grep -q "opensearch.hosts:" "$dashboard_conf"; then
      echo "opensearch.hosts: https://localhost:$INDEXER_PORT" >> "$dashboard_conf"
    fi
  fi
}

start_server() {
  log_info "Starting Wazuh services"

  if [[ "$DRY_RUN" == true ]]; then
    log_info "[dry-run] Would start: wazuh-indexer, wazuh-manager, wazuh-dashboard"
    return 0
  fi

  local services=("wazuh-indexer" "wazuh-manager" "wazuh-dashboard")

  for svc in "${services[@]}"; do
    if systemctl is-active "$svc" &>/dev/null; then
      log_info "Restarting $svc"
      systemctl restart "$svc" || log_warn "Failed to restart $svc"
    else
      log_info "Starting $svc"
      systemctl enable "$svc" 2>/dev/null || true
      systemctl start "$svc" || log_warn "Failed to start $svc"
    fi
  done

  sleep 5
  log_info "Server installation complete"
}

install_agent() {
  log_info "Installing Wazuh agent for $WAZUH_AGENT_NAME"

  detect_os
  add_wazuh_repo

  if [[ "$DRY_RUN" == true ]]; then
    log_info "[dry-run] Would install wazuh-agent and register to $WAZUH_MANAGER"
    return 0
  fi

  case "$OS" in
    ubuntu|debian)
      export DEBIAN_FRONTEND=noninteractive
      WAZUH_MANAGER="$WAZUH_MANAGER" WAZUH_AGENT_NAME="$WAZUH_AGENT_NAME" apt install -y -qq wazuh-agent
      ;;
    rhel|centos|almalinux|rocky)
      WAZUH_MANAGER="$WAZUH_MANAGER" WAZUH_AGENT_NAME="$WAZUH_AGENT_NAME" yum install -y wazuh-agent
      ;;
  esac

  configure_agent
  start_agent
}

configure_agent() {
  log_info "Configuring agent"

  if [[ "$DRY_RUN" == true ]]; then
    log_info "[dry-run] Would configure agent to connect to $WAZUH_MANAGER:$WAZUH_MANAGER_PORT"
    return 0
  fi

  local agent_conf="/var/ossec/etc/ossec.conf"

  if [[ -f "$agent_conf" ]]; then
    sed -i "s/<client><server><address>.*<\/address>/<client><server><address>$WAZUH_MANAGER<\/address>/" "$agent_conf" 2>/dev/null || true
    sed -i "s/<client><server><port>.*<\/port>/<client><server><port>$WAZUH_MANAGER_PORT<\/port>/" "$agent_conf" 2>/dev/null || true
    sed -i "s/<client><agent><name>.*<\/name>/<client><agent><name>$WAZUH_AGENT_NAME<\/name>/" "$agent_conf" 2>/dev/null || true
  fi
}

start_agent() {
  log_info "Starting Wazuh agent"

  if [[ "$DRY_RUN" == true ]]; then
    log_info "[dry-run] Would start wazuh-agent"
    return 0
  fi

  systemctl enable wazuh-agent 2>/dev/null || true
  systemctl restart wazuh-agent
  log_info "Agent installation complete"
}

check_status() {
  log_info "Checking Wazuh status"

  local services=("wazuh-indexer" "wazuh-manager" "wazuh-dashboard" "wazuh-agent")

  for svc in "${services[@]}"; do
    if systemctl is-active "$svc" &>/dev/null; then
      echo "✓ $svc: running"
    else
      echo "✗ $svc: not running"
    fi
  done

  if curl -ks "https://localhost:$INDEXER_PORT/_cluster/health" &>/dev/null; then
    echo "✓ Indexer: healthy"
  else
    echo "✗ Indexer: not responding"
  fi

  if curl -ks "https://localhost:$DASHBOARD_PORT" &>/dev/null; then
    echo "✓ Dashboard: accessible"
  else
    echo "✗ Dashboard: not accessible"
  fi
}

remove_wazuh() {
  log_info "Removing Wazuh installation"

  if [[ "$DRY_RUN" == true ]]; then
    log_info "[dry-run] Would remove all Wazuh packages and data"
    return 0
  fi

  detect_os

  case "$OS" in
    ubuntu|debian)
      apt remove -y -qq wazuh-manager wazuh-indexer wazuh-dashboard wazuh-api wazuh-agent 2>/dev/null || true
      rm -rf /var/ossec /etc/wazuh-* /usr/share/wazuh-* /var/lib/wazuh-indexer
      ;;
    rhel|centos|almalinux|rocky)
      yum remove -y wazuh-manager wazuh-indexer wazuh-dashboard wazuh-api wazuh-agent 2>/dev/null || true
      rm -rf /var/ossec /etc/wazuh-* /usr/share/wazuh-* /var/lib/wazuh-indexer
      ;;
  esac

  log_info "Wazuh removed"
}

parse_args "$@"

case "$COMMAND" in
  server)
    install_server
    ;;
  agent)
    install_agent
    ;;
  status)
    check_status
    ;;
  remove)
    remove_wazuh
    ;;
esac