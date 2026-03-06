#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN="${DRY_RUN:-false}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $*" >&2; }
die() { log "FATAL: $*"; exit 1; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        die "This script must be run as root (use sudo)"
    fi
}

list_failed_services() {
    echo "========================================"
    echo "Failed Systemd Services"
    echo "========================================"
    systemctl --failed --no-pager
}

list_active_services() {
    echo "========================================"
    echo "Active Services (Running)"
    echo "========================================"
    systemctl list-units --type=service --state=running --no-pager
}

service_status() {
    local service="$1"
    echo "========================================"
    echo "Status: $service"
    echo "========================================"
    systemctl status "$service" --no-pager || warn "Service $service not found"
}

restart_service() {
    local service="$1"
    log "Restarting service: $service"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would restart $service"
        return 0
    fi
    
    systemctl restart "$service"
    if systemctl is-active --quiet "$service"; then
        log "Service $service restarted successfully"
    else
        die "Failed to restart $service"
    fi
}

main() {
    local action="${1:-status}"
    local service="${2:-}"
    
    if [[ "$action" == "list-failed" ]]; then
        check_root
        list_failed_services
    elif [[ "$action" == "list-active" ]]; then
        list_active_services
    elif [[ "$action" == "status" && -n "$service" ]]; then
        service_status "$service"
    elif [[ "$action" == "restart" && -n "$service" ]]; then
        check_root
        restart_service "$service"
    else
        echo "Usage: $0 <action> [service]"
        echo "Actions:"
        echo "  list-failed      - List failed systemd services (requires root)"
        echo "  list-active      - List active running services"
        echo "  status <service> - Show status of a service"
        echo "  restart <service> - Restart a service (requires root)"
        echo ""
        echo "Environment variables:"
        echo "  DRY_RUN=true     - Simulate actions without making changes"
        exit 1
    fi
}

main "$@"
