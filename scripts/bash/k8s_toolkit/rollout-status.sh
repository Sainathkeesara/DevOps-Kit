#!/usr/bin/env bash
#
# PURPOSE: Monitor Kubernetes deployment/daemonset rollout status
# USAGE: ./rollout-status.sh <resource-type>/<name> [--namespace=<ns>] [--timeout=<duration>]
# REQUIREMENTS: kubectl configured, resource must exist
# SAFETY: Waits for rollout to complete without forcing restart. Returns non-zero on timeout/failure.
#
# EXAMPLES:
#   ./rollout-status.sh deployment/my-app
#   ./rollout-status.sh daemonset/fluentd --namespace=logging
#   ./rollout-status.sh deployment/my-app --timeout=5m

set -euo pipefail
IFS=$'\n\t'

# Defaults
TIMEOUT="3m"
NAMESPACE=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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
    grep '^#' "$0" | cut -c4- | head -n 14 | tail -n +3
    exit 1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --timeout=*)
                TIMEOUT="${1#*=}"
                ;;
            --namespace=*| -n=*)
                NAMESPACE="${1#*=}"
                ;;
            -h|--help) usage ;;
            -*)
                log_error "Unknown option: $1"
                usage
                ;;
            *)
                if [[ -z "$RESOURCE" ]]; then
                    RESOURCE="$1"
                else
                    log_error "Multiple resources provided"
                    usage
                fi
                ;;
        esac
        shift
    done
}

validate_resource() {
    if [[ -z "$RESOURCE" ]]; then
        log_error "Resource argument is required (e.g., deployment/my-app)"
        usage
    fi

    # Validate format: type/name
    if [[ ! "$RESOURCE" =~ ^[a-z0-9-]+/[a-z0-9-]+$ ]]; then
        log_error "Invalid resource format. Use: <type>/<name> (e.g., deployment/my-app)"
        exit 1
    fi

    local type name
    type="${RESOURCE%%/*}"
    name="${RESOURCE##*/}"

    if [[ -z "$NAMESPACE" ]]; then
        if ! kubectl get "$type" "$name" >/dev/null 2>&1; then
            log_error "Resource '$RESOURCE' does not exist in default namespace"
            exit 1
        fi
    else
        if ! kubectl get "$type" "$name" -n "$NAMESPACE" >/dev/null 2>&1; then
            log_error "Resource '$RESOURCE' does not exist in namespace '$NAMESPACE'"
            exit 1
        fi
    fi
}

build_rollout_command() {
    local cmd="kubectl rollout status $RESOURCE"
    [[ -n "$NAMESPACE" ]] && cmd="$cmd -n $NAMESPACE"
    cmd="$cmd --timeout=$TIMEOUT"

    echo "$cmd"
}

main() {
    parse_args "$@"

    validate_resource

    local rollout_cmd
    rollout_cmd=$(build_rollout_command)

    log_info "Monitoring rollout: $RESOURCE (timeout: $TIMEOUT)"
    log_info "Command: $rollout_cmd"

    if eval "$rollout_cmd"; then
        log_info "Rollout completed successfully"
        exit 0
    else
        local exit_code=$?
        log_error "Rollout failed or timed out (exit code: $exit_code)"
        exit $exit_code
    fi
}

main "$@"
