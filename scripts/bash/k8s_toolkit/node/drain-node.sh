#!/usr/bin/env bash
#
# PURPOSE: Safely drain a Kubernetes node, evicting pods gracefully
# USAGE: ./drain-node.sh <node-name> [--dry-run] [--force] [--ignore-daemonsets]
# REQUIREMENTS: kubectl configured with cluster access, node must be schedulable
# SAFETY: Drains node by evicting pods, respecting PodDisruptionBudgets. DaemonSets are skipped by default.
#
# EXAMPLES:
#   ./drain-node.sh ip-10-0-1-100
#   ./drain-node.sh ip-10-0-1-100 --dry-run
#   ./drain-node.sh ip-10-0-1-100 --force --ignore-daemonsets

set -euo pipefail
IFS=$'\n\t'

# Defaults
DRY_RUN=0
FORCE=0
IGNORE_DAEMONSETS=0
NODE_NAME=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

usage() {
    grep '^#' "$0" | cut -c4- | head -n 13 | tail -n +3
    exit 1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run) DRY_RUN=1 ;;
            --force) FORCE=1 ;;
            --ignore-daemonsets) IGNORE_DAEMONSETS=1 ;;
            -h|--help) usage ;;
            -*)
                log_error "Unknown option: $1"
                usage
                ;;
            *)
                if [[ -z "$NODE_NAME" ]]; then
                    NODE_NAME="$1"
                else
                    log_error "Multiple node names provided"
                    usage
                fi
                ;;
        esac
        shift
    done
}

validate_node() {
    local node="$1"
    if [[ -z "$node" ]]; then
        log_error "Node name is required"
        usage
    fi

    if ! kubectl get node "$node" >/dev/null 2>&1; then
        log_error "Node '$node' does not exist or is not accessible"
        exit 1
    fi
}

check_unschedulable() {
    local node="$1"
    local unschedulable
    unschedulable=$(kubectl get node "$node" -o jsonpath='{.spec.unschedulable}' 2>/dev/null || echo "false")

    if [[ "$unschedulable" == "true" ]]; then
        log_warn "Node '$node' is already marked unschedulable"
        return 0
    fi
    return 1
}

build_drain_command() {
    local cmd="kubectl drain $NODE_NAME"
    [[ $IGNORE_DAEMONSETS -eq 1 ]] && cmd="$cmd --ignore-daemonsets"
    [[ $FORCE -eq 1 ]] && cmd="$cmd --force"
    cmd="$cmd --delete-emptydir-data --timeout=120s"

    echo "$cmd"
}

main() {
    parse_args "$@"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "DRY RUN MODE - No changes will be made"
    fi

    validate_node "$NODE_NAME"

    # Check if already unschedulable
    if check_unschedulable "$NODE_NAME"; then
        log_info "Node '$NODE_NAME' already drained (unschedulable). Skipping."
        exit 0
    fi

    log_info "Preparing to drain node: $NODE_NAME"

    # Build drain command
    local drain_cmd
    drain_cmd=$(build_drain_command)

    log_info "Command: $drain_cmd"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would execute: $drain_cmd"
        exit 0
    fi

    # Execute drain
    log_info "Executing drain operation..."
    if eval "$drain_cmd"; then
        log_info "Node '$NODE_NAME' drained successfully"

        # Mark node unschedulable
        log_info "Marking node as unschedulable..."
        if kubectl cordon "$NODE_NAME"; then
            log_info "Node '$NODE_NAME' is now cordoned"
        else
            log_warn "Drain succeeded but cordon failed. Node may still be schedulable."
            exit 1
        fi
    else
        log_error "Drain operation failed"
        exit 1
    fi
}

main "$@"
