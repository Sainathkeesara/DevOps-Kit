#!/usr/bin/env bash
#
# PURPOSE: Safely drain a Kubernetes node, evicting pods gracefully with optional wait monitoring
# USAGE: ./drain-node.sh <node-name> [--dry-run] [--force] [--ignore-daemonsets] [--wait] [--wait-timeout=<seconds>]
# REQUIREMENTS: kubectl configured with cluster access, node must be schedulable
# SAFETY: Drains node by evicting pods, respecting PodDisruptionBudgets. DaemonSets are skipped by default.
#
# EXAMPLES:
#   ./drain-node.sh ip-10-0-1-100
#   ./drain-node.sh ip-10-0-1-100 --dry-run
#   ./drain-node.sh ip-10-0-1-100 --force --ignore-daemonsets --wait --wait-timeout=300

set -euo pipefail
IFS=$'\n\t'

# Defaults
DRY_RUN=0
FORCE=0
IGNORE_DAEMONSETS=0
WAIT_FOR_EVICTION=0
WAIT_TIMEOUT=300
POLL_INTERVAL=5
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
            --wait) WAIT_FOR_EVICTION=1 ;;
            --wait-timeout=*)
                WAIT_FOR_EVICTION=1
                WAIT_TIMEOUT="${1#*=}"
                ;;
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
    cmd="$cmd --delete-emptydir-data"

    echo "$cmd"
}

wait_for_eviction() {
    local node="$1"
    local timeout="$2"
    local elapsed=0

    log_info "Waiting for pod eviction to complete (timeout: ${timeout}s)..."

    while [[ $elapsed -lt $timeout ]]; do
        local pod_count
        pod_count=$(kubectl get pods --field-selector="spec.nodeName=$node" \
            --all-namespaces \
            -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | wc -w)

        if [[ "$pod_count" -eq 0 ]]; then
            log_info "All pods evicted from node '$node'"
            return 0
        fi

        log_info "Still $pod_count pod(s) on node, waiting... (${elapsed}s/${timeout}s)"
        sleep "$POLL_INTERVAL"
        elapsed=$((elapsed + POLL_INTERVAL))
    done

    log_warn "Timeout reached ($timeout s), some pods may still be present"
    return 1
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
        log_info "Node '$NODE_NAME' drain command completed"

        if [[ $WAIT_FOR_EVICTION -eq 1 ]]; then
            wait_for_eviction "$NODE_NAME" "$WAIT_TIMEOUT" || log_warn "Eviction wait completed with warnings"
        fi

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
