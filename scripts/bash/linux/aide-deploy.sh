#!/usr/bin/env bash
set -euo pipefail

# aide-deploy.sh — Automated AIDE deployment and management for Linux
# Purpose: Deploy, configure, and manage file integrity monitoring with AIDE
# Usage: ./aide-deploy.sh [init|check|update|rollback|status]
# Requirements: root access, aide package installed
# Safety: Dry-run mode supported for all destructive operations
# Tested OS: Ubuntu 22.04 LTS, AlmaLinux 9.4, Fedora 38

DRY_RUN=${DRY_RUN:-false}
AIDE_CONF="/etc/aide/aide.conf"
AIDE_DB="/var/lib/aide/aide.db.gz"
AIDE_DB_NEW="/var/lib/aide/aide.db.new.gz"
LOG_DIR="/var/log/aide"
REPORT_FILE="$LOG_DIR/aide-report.log"

log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*"; }
log_warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $*" >&2; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }

command -v aide >/dev/null 2>&1 || { log_error "aide not found. Install with: apt-get install aide or dnf install aide"; exit 1; }

show_usage() {
  cat <<EOF
Usage: $0 [command] [options]

Commands:
  init        Initialize AIDE database (first-time setup)
  check       Run integrity check
  update      Update baseline after authorized changes
  rollback    Rollback to previous baseline
  status      Show AIDE status and last check results
  install     Install and configure AIDE (default)

Options:
  --dry-run   Show what would be done without executing
  -h, --help  Show this help message

Examples:
  $0 install              # Install and configure AIDE
  $0 init                 # Initialize baseline database
  $0 check                # Run integrity check
  $0 check --dry-run      # Simulate check without making changes
  $0 update               # Update baseline after system updates

EOF
}

parse_args() {
  if [[ $# -eq 0 ]]; then
    COMMAND="install"
    return
  fi

  case "$1" in
    init|check|update|rollback|status|install)
      COMMAND="$1"
      shift
      ;;
    -h|--help)
      show_usage
      exit 0
      ;;
    --dry-run)
      DRY_RUN=true
      COMMAND="${2:-install}"
      shift 2
      ;;
    *)
      log_error "Unknown command: $1"
      show_usage
      exit 1
      esac
}

detect_os() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
      ubuntu|debian) OS="debian"; ;;
      almalinux|rhel|centos) OS="rhel"; ;;
      fedora) OS="fedora"; ;;
      *) OS="unknown"; ;;
    esac
  else
    OS="unknown"
  fi
  log_info "Detected OS: $OS"
}

install_aide() {
  log_info "Installing AIDE"

  if [[ "$DRY_RUN" == true ]]; then
    log_info "[dry-run] Would install aide package"
    return 0
  fi

  case "$OS" in
    debian)
      apt-get update -qq
      apt-get install -y -qq aide
      ;;
    rhel)
      dnf install -y -q aide || yum install -y -q aide
      ;;
    fedora)
      dnf install -y -q aide
      ;;
    *)
      log_error "Unsupported OS: $OS"
      exit 1
      ;;
  esac

  log_info "AIDE installed successfully"
}

configure_aide() {
  log_info "Configuring AIDE"

  if [[ "$DRY_RUN" == true ]]; then
    log_info "[dry-run] Would configure AIDE"
    return 0
  fi

  mkdir -p "$LOG_DIR"

  if [[ ! -f "$AIDE_CONF" ]]; then
    log_info "Generating default configuration"
    aideinit 2>/dev/null || true
  fi

  log_info "AIDE configured at $AIDE_CONF"
}

init_database() {
  log_info "Initializing AIDE baseline database"

  if [[ "$DRY_RUN" == true ]]; then
    log_info "[dry-run] Would initialize database at $AIDE_DB"
    return 0
  fi

  if [[ -f "$AIDE_DB" ]]; then
    log_warn "Existing database found. Creating backup."
    cp "$AIDE_DB" "${AIDE_DB}.backup-$(date +%Y%m%d)"
  fi

  log_info "Running aide --init (this may take several minutes)..."
  aide --init 2>&1 | tee /tmp/aide-init.log

  if [[ -f "$AIDE_DB_NEW" ]]; then
    mv "$AIDE_DB_NEW" "$AIDE_DB"
    log_info "Baseline database created at $AIDE_DB"
  else
    log_error "Failed to create database"
    exit 1
  fi
}

run_check() {
  log_info "Running AIDE integrity check"

  if [[ "$DRY_RUN" == true ]]; then
    log_info "[dry-run] Would run integrity check"
    return 0
  fi

  local check_output
  check_output=$(aide --check 2>&1)
  local exit_code=$?

  echo "$check_output" | tee "$REPORT_FILE"

  if [[ $exit_code -eq 0 ]]; then
    log_info "No changes detected — system integrity verified"
  else
    log_warn "Changes detected! Review $REPORT_FILE for details"
    log_info "To update baseline after reviewing changes: $0 update"
  fi

  return $exit_code
}

update_baseline() {
  log_info "Updating AIDE baseline database"

  if [[ "$DRY_RUN" == true ]]; then
    log_info "[dry-run] Would update baseline database"
    return 0
  fi

  if [[ ! -f "$AIDE_DB" ]]; then
    log_error "No baseline database found. Run 'init' first."
    exit 1
  fi

  log_info "Running aide --update..."
  aide --update 2>&1 | tee /tmp/aide-update.log

  if [[ -f "$AIDE_DB_NEW" ]]; then
    mv "$AIDE_DB" "${AIDE_DB}.old-$(date +%Y%m%d)"
    mv "$AIDE_DB_NEW" "$AIDE_DB"
    log_info "Baseline updated successfully"
  else
    log_error "Failed to update baseline"
    exit 1
  fi
}

rollback_baseline() {
  log_info "Rolling back to previous baseline"

  if [[ "$DRY_RUN" == true ]]; then
    log_info "[dry-run] Would rollback to previous baseline"
    return 0
  fi

  local backup
  backup=$(ls -t "$AIDE_DB".backup-* 2>/dev/null | head -1)

  if [[ -n "$backup" && -f "$backup" ]]; then
    cp "$backup" "$AIDE_DB"
    log_info "Rolled back to: $backup"
  else
    log_error "No backup found to rollback to"
    exit 1
  fi
}

show_status() {
  log_info "AIDE Status"

  echo "=== AIDE Installation ==="
  command -v aide && aide --version || echo "AIDE not installed"

  echo ""
  echo "=== Database ==="
  if [[ -f "$AIDE_DB" ]]; then
    ls -la "$AIDE_DB"
    echo "Database age: $(echo "$(date +%s) - $(stat -c %Y "$AIDE_DB")" | bc / 86400) days"
  else
    echo "No database found — run 'init' to create baseline"
  fi

  echo ""
  echo "=== Last Report ==="
  if [[ -f "$REPORT_FILE" ]]; then
    tail -20 "$REPORT_FILE"
  else
    echo "No report found — run 'check' to generate"
  fi

  echo ""
  echo "=== Configuration ==="
  if [[ -f "$AIDE_CONF" ]]; then
    echo "Config: $AIDE_CONF"
    echo "Monitored paths: $(grep -E "^(/|\.+)" "$AIDE_CONF" | grep -v "^#" | wc -l)"
  else
    echo "No configuration found"
  fi
}

main() {
  parse_args "$@"
  detect_os

  case "$COMMAND" in
    install)
      install_aide
      configure_aide
      log_info "AIDE installation complete. Run 'init' to create baseline."
      ;;
    init)
      init_database
      ;;
    check)
      run_check
      ;;
    update)
      update_baseline
      ;;
    rollback)
      rollback_baseline
      ;;
    status)
      show_status
      ;;
    *)
      log_error "Unknown command: $COMMAND"
      show_usage
      exit 1
      ;;
  esac

  log_info "Done"
}

main "$@"