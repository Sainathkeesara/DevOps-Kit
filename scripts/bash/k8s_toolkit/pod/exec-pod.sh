#!/usr/bin/env bash
#
# PURPOSE: Execute a command inside a Kubernetes pod interactively
# USAGE: ./exec-pod.sh <pod-name> <command> [args...] [--namespace=<ns>] [--container=<container>]
# REQUIREMENTS: Pod must be running, target container must exist
# SAFETY: Executes arbitrary commands inside container. Requires user to specify command explicitly.
#
# EXAMPLES:
#   ./exec-pod.sh my-app-5d94f6b7f9-abcde /bin/bash
#   ./exec-pod.sh my-app-5d94f6b7f9-abcde --namespace=default --container=app
#   ./exec-pod.sh my-app-5d94f6b7f9-abcde ls -la /app

set -euo pipefail
IFS=$'\n\t'

# Defaults
NAMESPACE="default"
CONTAINER=""

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

usage() {
    grep '^#' "$0" | cut -c4- | head -n 20 | tail -n +3
    exit 1
}

parse_args() {
    # First non-option arg is POD_NAME, second is COMMAND (and rest are command args)
    local args=()
    while [[ $# -gt 0 ]]; do
        case $1 in
            --namespace=*| -n=*)
                NAMESPACE="${1#*=}"
                ;;
            --container=*)
                CONTAINER="${1#*=}"
                ;;
            -h|--help) usage ;;
            -*)
                log_error "Unknown option: $1"
                usage
                ;;
            *)
                args+=("$1")
                ;;
        esac
        shift
    done

    if [[ ${#args[@]} -lt 2 ]]; then
        log_error "Pod name and command are required"
        usage
    fi

    POD_NAME="${args[0]}"
    # Remaining args form the command to execute
    shift
    COMMAND_ARGS=("$@")
}

validate_pod() {
    if ! kubectl get pod "$POD_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
        log_error "Pod '$POD_NAME' does not exist in namespace '$NAMESPACE'"
        exit 1
    fi

    local phase
    phase=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
    if [[ "$phase" != "Running" ]]; then
        log_warn "Pod phase is '$phase'. Exec may fail or be limited."
    fi

    # If container is specified, verify it exists in pod
    if [[ -n "$CONTAINER" ]]; then
        local containers
        containers=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{range .spec.containers[*]}{.name}{" "}{end}' 2>/dev/null || echo "")
        if ! echo "$containers" | grep -qw "$CONTAINER"; then
            log_error "Container '$CONTAINER' not found in pod '$POD_NAME'"
            log_info "Available containers: $containers"
            exit 1
        fi
    fi
}

build_exec_command() {
    local cmd="kubectl exec $POD_NAME -n $NAMESPACE"
    [[ -n "$CONTAINER" ]] && cmd="$cmd -c $CONTAINER"
    cmd="$cmd -- ${COMMAND_ARGS[@]}"

    echo "$cmd"
}

main() {
    parse_args "$@"

    validate_pod

    local exec_cmd
    exec_cmd=$(build_exec_command)

    log_info "Executing in pod: $POD_NAME (namespace: $NAMESPACE)"

    # Run the command
    if bash -c "$exec_cmd"; then
        log_info "Command completed successfully"
        exit 0
    else
        local exit_code=$?
        log_error "Command failed with exit code: $exit_code"
        exit $exit_code
    fi
}

main "$@"
