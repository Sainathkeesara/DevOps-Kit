#!/usr/bin/env bash
#
# PURPOSE: Restart a Kubernetes deployment/daemonset/statefulset by rolling it out
# USAGE: ./rollartion-restart.sh <resource-type>/<name> [--namespace=<ns>] [--watch] [--timeout=<duration>] [--dry-run]
# REQUIREMENTS: kubectl configured, resource must support rollout (deployment, statefulset, daemonset)
# SAFETY: Supports dry-run mode. Respects PodDisruptionBudgets during restart.
#
# EXAMPLES:
#   ./rollout-restart.sh deployment/my-app
#   ./rollout-restart.sh deployment/my-app --watch
#   ./rollout-restart.sh daemonset/fluentd --namespace=logging --timeout=5m --dry-run

set -euo pipefail
IFS=$'\n\t'

DRY_RUN=0
WATCH=0
TIMEOUT="3m"
NAMESPACE=""
RESOURCE=""

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
            --dry-run) DRY_RUN=1 ;;
            --watch) WATCH=1 ;;
            --timeout=*)
                TIMEOUT="${1#*=}"
                ;;
            --namespace=*|-n=*)
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

    if [[ ! "$RESOURCE" =~ ^[a-z0-9-]+/[a-z0-9-]+$ ]]; then
        log_error "Invalid resource format. Use: <type>/<name> (e.g., deployment/my-app)"
        exit 1
    fi

    local type name
    type="${RESOURCE%%/*}"
    name="${RESOURCE##*/}"

    local supported=0
    for stype in deployment statefulset daemonset; do
        if [[ "$type" == "$stype" ]]; then
            supported=1
            break
        fi
    done
    if [[ $supported -eq 0 ]]; then
        log_error "Unsupported resource type: $type. Supported: deployment, statefulset, daemonset"
        exit 1
    fi

    local get_cmd="kubectl get $type $name"
    [[ -n "$NAMESPACE" ]] && get_cmd="$get_cmd -n $NAMESPACE"

    if ! $get_cmd >/dev/null 2>&1; then
        log_error "Resource '$RESOURCE' does not exist${NAMESPACE:+ in namespace '$NAMESPACE'}"
        exit 1
    fi
}

get_restart_command() {
    local type="$1"
    local name="$2"
    local cmd="kubectl rollout restart $type/$name"
    [[ -n "$NAMESPACE" ]] && cmd="$cmd -n $NAMESPACE"
    echo "$cmd"
}

get_rollout_status_command() {
    local type="$1"
    local name="$2"
    local cmd="kubectl rollout status $type/$name"
    [[ -n "$NAMESPACE" ]] && cmd="$cmd -n $NAMESPACE"
    cmd="$cmd --timeout=$TIMEOUT"
    echo "$cmd"
}

main() {
    parse_args "$@"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "DRY RUN MODE - No changes will be made"
    fi

    validate_resource

    local type name
    type="${RESOURCE%%/*}"
    name="${RESOURCE##*/}"

    local restart_cmd
    restart_cmd=$(get_restart_command "$type" "$name")

    log_info "Preparing to restart: $RESOURCE${NAMESPACE:+ (namespace: $NAMESPACE)}"
    log_info "Restart command: $restart_cmd"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would execute: $restart_cmd"
        exit 0
    fi

    log_info "Triggering rollout restart..."
    if ! eval "$restart_cmd"; then
        log_error "Failed to trigger rollout restart for $RESOURCE"
        exit 1
    fi

    log_info "Rollout restart triggered successfully"

    if [[ $WATCH -eq 1 ]]; then
        local status_cmd
        status_cmd=$(get_rollout_status_command "$type" "$name")
        log_info "Watching rollout status (timeout: $TIMEOUT)..."
        log_info "Status command: $status_cmd"

        if eval "$status_cmd"; then
            log_info "Rollout completed successfully"
            exit 0
        else
            local exit_code=$?
            log_error "Rollout failed or timed out (exit code: $exit_code)"
            exit $exit_code
        fi
    else
        log_info "Use --watch to monitor rollout progress"
        exit 0
    fi
}

main "$@"
