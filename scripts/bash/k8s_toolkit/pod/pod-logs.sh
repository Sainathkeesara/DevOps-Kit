#!/usr/bin/env bash
#
# PURPOSE: Stream logs from a Kubernetes pod with formatting and filtering options
# USAGE: ./pod-logs.sh <pod-name> [--namespace=<ns>] [--since=<duration>] [--tail=<lines>] [--follow]
# REQUIREMENTS: Pod must exist and have at least one container
# SAFETY: Read-only log retrieval, no modifications to cluster
#
# EXAMPLES:
#   ./pod-logs.sh my-app-5d94f6b7f9-abcde
#   ./pod-logs.sh my-app --namespace=default --tail=100
#   ./pod-logs.sh my-app --since=1h --follow

set -euo pipefail
IFS=$'\n\t'

# Defaults
NAMESPACE="default"
SINCE=""
TAIL=""
FOLLOW=0
CONTAINER=""

RED='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${RED}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

usage() {
    grep '^#' "$0" | cut -c4- | head -n 17 | tail -n +3
    exit 1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --namespace=*| -n=*)
                NAMESPACE="${1#*=}"
                ;;
            --since=*)
                SINCE="${1#*=}"
                ;;
            --tail=*)
                TAIL="${1#*=}"
                ;;
            --container=*)
                CONTAINER="${1#*=}"
                ;;
            --follow| -f) FOLLOW=1 ;;
            -h|--help) usage ;;
            -*)
                log_warn "Unknown option: $1 (ignoring)"
                ;;
            *)
                if [[ -z "$POD_NAME" ]]; then
                    POD_NAME="$1"
                else
                    log_warn "Multiple pod names provided (using first: $POD_NAME)"
                fi
                ;;
        esac
        shift
    done
}

validate_pod() {
    if [[ -z "$POD_NAME" ]]; then
        log_error "Pod name is required"
        usage
    fi

    if ! kubectl get pod "$POD_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
        log_error "Pod '$POD_NAME' does not exist in namespace '$NAMESPACE'"
        exit 1
    fi

    # Check if pod has at least one container
    local phase
    phase=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
    if [[ "$phase" != "Running" && "$phase" != "Pending" ]]; then
        log_warn "Pod phase is '$phase'. Logs may be unavailable."
    fi
}

build_logs_command() {
    local cmd="kubectl logs $POD_NAME -n $NAMESPACE"

    [[ -n "$SINCE" ]] && cmd="$cmd --since=$SINCE"
    [[ -n "$TAIL" ]] && cmd="$cmd --tail=$TAIL"
    [[ -n "$CONTAINER" ]] && cmd="$cmd -c $CONTAINER"
    [[ $FOLLOW -eq 1 ]] && cmd="$cmd -f"

    echo "$cmd"
}

main() {
    parse_args "$@"

    validate_pod

    local logs_cmd
    logs_cmd=$(build_logs_command)

    log_info "Fetching logs from pod: $POD_NAME (namespace: $NAMESPACE)"

    if [[ $FOLLOW -eq 1 ]]; then
        log_info "Following logs (press Ctrl+C to stop)..."
    fi

    # Execute logs command directly (streams to stdout)
    if eval "$logs_cmd"; then
        exit 0
    else
        local exit_code=$?
        if [[ $FOLLOW -eq 1 ]]; then
            log_info "Log streaming terminated"
        else
            log_error "Failed to retrieve logs (exit code: $exit_code)"
        fi
        exit $exit_code
    fi
}

main "$@"
