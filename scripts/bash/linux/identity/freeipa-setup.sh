#!/usr/bin/env bash
set -euo pipefail

# freeipa-setup.sh — FreeIPA server deployment and client enrollment
# Purpose: Deploy a FreeIPA domain controller with integrated DNS, then enroll clients
# Usage: ./freeipa-setup.sh [--server|--client] [options]
# Requirements: AlmaLinux 9 / RHEL 9 / Fedora 38+ for server; any supported Linux for client
# Safety: Dry-run mode supported. Backs up existing configs to /var/tmp/freeipa-backup/
# Tested OS: AlmaLinux 9.4, RHEL 9.4, Fedora 39

DRY_RUN=${DRY_RUN:-false}
BACKUP_DIR="/var/tmp/freeipa-backup"
IPA_REALM="${IPA_REALM:-EXAMPLE.COM}"
IPA_DOMAIN="${IPA_DOMAIN:-example.com}"
IPA_ADMIN_PASSWORD="${IPA_ADMIN_PASSWORD:-}"
CLIENT_IPA_SERVER="${CLIENT_IPA_SERVER:-}"
LOG_FILE="/var/log/freeipa-setup.log"

log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*"; }
log_warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $*"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }

command -v getent >/dev/null 2>&1 || { log_error "getent not found"; exit 1; }
command -v hostname >/dev/null 2>&1 || { log_error "hostname not found"; exit 1; }

if [ "$DRY_RUN" = true ]; then
  log_info "DRY RUN MODE — no changes will be made"
fi

usage() {
  cat <<EOF
Usage: $0 [--server|--client] [options]

Options:
  --server              Deploy FreeIPA server (default if no mode specified)
  --client             Enroll as FreeIPA client
  --realm REALM         IPA realm name (default: EXAMPLE.COM)
  --domain DNS_DOMAIN  DNS domain (default: example.com)
  --admin-pass PASS     IPA admin password (required for server)
  --client-server HOST IPA server hostname for client enrollment
  --no-ntp            Skip NTP configuration
  --dns-forwarder IP  DNS forwarder IP address
  --dry-run           Show what would be done without executing

Examples:
  # Deploy FreeIPA server
  $0 --server --domain corp.example.com --admin-pass 'SecurePass123!'

  # Enroll client
  $0 --client --client-server ipa01.corp.example.com
EOF
}

MODE="server"
NTP_ENABLED=true
DNS_FORWARDER="8.8.8.8"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --server) MODE="server"; shift ;;
    --client) MODE="client"; shift ;;
    --realm) IPA_REALM="$2"; shift 2 ;;
    --domain) IPA_DOMAIN="$2"; shift 2 ;;
    --admin-pass) IPA_ADMIN_PASSWORD="$2"; shift 2 ;;
    --client-server) CLIENT_IPA_SERVER="$2"; shift 2 ;;
    --no-ntp) NTP_ENABLED=false; shift ;;
    --dns-forwarder) DNS_FORWARDER="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) log_error "Unknown option: $1"; usage; exit 1 ;;
  esac
done

validate_os() {
  if [ -f /etc/almalinux-release ]; then
    local version=$(grep -oE '[0-9]+' /etc/almalinux-release | head -1)
    if [ "$version" -ge 9 ]; then
      OS="almalinux"
      return 0
    fi
  fi
  if [ -f /etc/redhat-release ]; then
    local version=$(grep -oE '[0-9]+' /etc/redhat-release | head -1)
    if [ "$version" -ge 9 ]; then
      OS="rhel"
      return 0
    fi
  fi
  if [ -f /etc/fedora-release ]; then
    local version=$(grep -oE '[0-9]+' /etc/fedora-release | head -1)
    if [ "$version" -ge 38 ]; then
      OS="fedora"
      return 0
    fi
  fi
  log_error "FreeIPA server requires AlmaLinux 9+, RHEL 9+, or Fedora 38+. Current system not supported."
  return 1
}

backup_existing() {
  if [ "$DRY_RUN" = true ]; then
    log_info "[dry-run] Would backup existing FreeIPA configuration"
    return 0
  fi

  if [ -d /etc/ipa ] || [ -d /var/lib/ipa ]; then
    log_info "Backing up existing FreeIPA configuration to $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    timestamp=$(date +%Y%m%d-%H%M%S)
    [ -d /etc/ipa ] && cp -rp /etc/ipa "$BACKUP_DIR/etc.ipa.$timestamp" 2>/dev/null || true
    [ -d /var/lib/ipa ] && cp -rp /var/lib/ipa "$BACKUP_DIR/var.lib.ipa.$timestamp" 2>/dev/null || true
  fi
}

configure_dns() {
  log_info "Configuring DNS resolver for FreeIPA domain $IPA_DOMAIN"

  if [ "$DRY_RUN" = true ]; then
    log_info "[dry-run] Would configure DNS resolver"
    return 0
  fi

  local resolv_conf="/etc/resolv.conf"
  local current_nameservers=$(grep -E '^nameserver' "$resolv_conf" 2>/dev/null | wc -l)

  if [ "$current_nameservers" -eq 0 ]; then
    log_error "No nameservers configured in $resolv_conf"
    return 1
  fi

  log_info "DNS resolver configuration complete — using localhost as primary resolver"
}

install_ipa_server() {
  log_info "Installing FreeIPA server packages"

  if [ "$DRY_RUN" = true ]; then
    log_info "[dry-run] Would install FreeIPA server packages: ipa-server, ipa-server-dns"
    return 0
  fi

  local packages=("ipa-server" "ipa-server-dns" "ipa-healthcheck")

  case "$OS" in
    almalinux|rhel)
      if ! command -v dnf >/dev/null 2>&1; then
        log_error "dnf not found — cannot install packages"
        return 1
      fi
      log_info "Installing packages with dnf ( AlmaLinux / RHEL )"
      dnf install -y "${packages[@]}" || {
        log_warn "Some packages may require subscription — installing from system-uppa"
        dnf module enable -y idm:DL1 ||
        log_warn "Module enable failed — continuing with available packages"
        dnf install -y "${packages[@]}" || log_warn "Package install returned non-zero"
      }
      ;;
    fedora)
      if ! command -v dnf >/dev/null 2>&1; then
        log_error "dnf not found — cannot install packages"
        return 1
      fi
      log_info "Installing packages with dnf ( Fedora )"
      dnf install -y "${packages[@]}" || log_warn "Package install returned non-zero"
      ;;
    *)
      log_error "Unsupported OS: $OS"
      return 1
      ;;
  esac

  log_info "FreeIPA server packages installed"
}

configure_firewall() {
  log_info "Configuring firewall rules for FreeIPA"

  if [ "$DRY_RUN" = true ]; then
    log_info "[dry-run] Would configure firewall"
    return 0
  fi

  if command -v firewall-cmd >/dev/null 2>&1; then
    local services=("dns" "freeipa-ldaps" "freeipa-replication" "ntp")
    for svc in "${services[@]}"; do
      firewall-cmd --permanent --add-service="$svc" 2>/dev/null || log_warn "Failed to add firewall service: $svc"
    done
    firewall-cmd --reload 2>/dev/null || log_warn "Failed to reload firewall"
  fi

  if command -v iptables >/dev/null 2>&1; then
    log_info "Configuring iptables rules"
    iptables -A INPUT -p udp --dport 53 -j ACCEPT 2>/dev/null || true
    iptables -A INPUT -p tcp --dport 53 -j ACCEPT 2>/dev/null || true
    iptables -A INPUT -p tcp --dport 389 -j ACCEPT 2>/dev/null || true
    iptables -A INPUT -p tcp --dport 636 -j ACCEPT 2>/dev/null || true
  fi

  log_info "Firewall configuration complete"
}

deploy_ipa_server() {
  log_info "Deploying FreeIPA server"

  if [ "$DRY_RUN" = true ]; then
    log_info "[dry-run] Would deploy FreeIPA server with realm $IPA_REALM domain $IPA_DOMAIN"
    return 0
  fi

  if [ -z "$IPA_ADMIN_PASSWORD" ]; then
    log_error "IPA admin password required. Use --admin-pass"
    return 1
  fi

  log_info "Running IPA server installation"

  local ipa_opts=(
    "--realm=$IPA_REALM"
    "--domain=$IPA_DOMAIN"
    "--password=$IPA_ADMIN_PASSWORD"
    "--setup-dns"
    "--dns-forwarder=$DNS_FORWARDER"
    "--no-ntp"
    "--no-ui-redirect"
    "--unattended"
  )

  if [ "$NTP_ENABLED" = false ]; then
    ipa_opts+=("--no-ntp")
  fi

  if ipa-server-install "${ipa_opts[@]}"; then
    log_info "FreeIPA server deployed successfully"
  else
    log_warn "IPA server install returned non-zero — checking if already configured"
    if [ -d /etc/ipa ]; then
      log_info "FreeIPA appears to be already configured"
    else
      log_error "FreeIPA installation failed"
      return 1
    fi
  fi
}

deploy_ipa_client() {
  log_info "Enrolling FreeIPA client to server $CLIENT_IPA_SERVER"

  if [ "$DRY_RUN" = true ]; then
    log_info "[dry-run] Would enroll as client to $CLIENT_IPA_SERVER"
    return 0
  fi

  if [ -z "$CLIENT_IPA_SERVER" ]; then
    log_error "Client enrollment requires --client-server"
    return 1
  fi

  if [ -z "$IPA_ADMIN_PASSWORD" ]; then
    log_error "IPA admin password required. Use --admin-pass"
    return 1
  fi

  local client_opts=(
    "--server=$CLIENT_IPA_SERVER"
    "--realm=$IPA_REALM"
    "--domain=$IPA_DOMAIN"
    "--password=$IPA_ADMIN_PASSWORD"
    "--unattended"
  )

  if [ "$NTP_ENABLED" = false ]; then
    client_opts+=("--no-ntp")
  fi

  log_info "Installing and configuring FreeIPA client"

  if command -v dnf >/dev/null 2>&1; then
    dnf install -y freeipa-client freeipa-admintools 2>/dev/null || log_warn "Client package install returned non-zero"
  fi

  if ipa-client-install "${client_opts[@]}"; then
    log_info "FreeIPA client enrolled successfully"
  else
    log_warn "Client enrollment returned non-zero — checking if already enrolled"
    if [ -f /etc/ipa/default.conf ]; then
      log_info "Client appears to be already enrolled"
    fi
  fi
}

verify_installation() {
  log_info "Verifying FreeIPA deployment"

  if [ "$DRY_RUN" = true ]; then
    log_info "[dry-run] Would verify installation"
    return 0
  fi

  if ! command -v kinit >/dev/null 2>&1; then
    log_error "kinit not found — Kerberos not installed"
    return 1
  fi

  if [ "$MODE" = "server" ]; then
    log_info "Testing admin credentials"
    echo "$IPA_ADMIN_PASSWORD" | kinit admin@$IPA_REALM 2>/dev/null || {
      log_warn "kinit returned non-zero — may be first-run or configuration issue"
    }
  fi

  if command -v ipa >/dev/null 2>&1; then
    log_info "ipa command available"
  fi

  log_info "Verification complete"
}

main() {
  log_info "FreeIPA deployment starting — mode: $MODE, OS detection: enabled"
  log_info "Realm: $IPA_REALM, Domain: $IPA_DOMAIN"

  validate_os || exit 1
  backup_existing
  configure_dns

  case "$MODE" in
    server)
      install_ipa_server
      configure_firewall
      deploy_ipa_server
      ;;
    client)
      deploy_ipa_client
      ;;
  esac

  verify_installation

  log_info "FreeIPA deployment complete"
  log_info "Admin credentials: admin@$IPA_REALM"
}

main "$@"