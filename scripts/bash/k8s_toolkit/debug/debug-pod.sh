#!/usr/bin/env bash
#
# PURPOSE: Interactive debugging toolkit for a Kubernetes pod (logs, exec, describe)
# USAGE: ./debug-pod.sh <pod-name> [--namespace=<ns>]
# REQUIREMENTS: Pod must exist, kubectl access
# SAFETY: Read-only except for exec commands entered by user during interactive session.
#
# EXAMPLES:
#   ./debug-pod.sh my-app-5d94f6b7f9-abcde
#   ./debug-pod.sh my-app-pod --namespace=production

set -euo pipefail
IFS=$'\n\t'

# Defaults
NAMESPACE="default"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_banner() {
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║           Kubernetes Pod Debug Toolkit                   ║
╠═══════════════════════════════════════════════════════════╣
║ Commands:                                                ║
║  d        - Describe pod                                 ║
║  l        - Show logs (last 100 lines)                   ║
║  lf       - Follow logs                                  ║
║  ls       - List containers in pod                       ║
║  e        - Exec into first container (bash/sh)          ║
║  ec <c>   - Exec into specific container                ║
║  p        - Show pod yaml/config                         ║
║  eo       - Show events for pod/namespace               ║
║  ?/h      - Show this help                               ║
║  q        - Exit                                         ║
╚═══════════════════════════════════════════════════════════╝
EOF
}

usage() {
    grep '^#' "$0" | cut -c4- | head -n 18 | tail -n +3
    exit 1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --namespace=*| -n=*)
                NAMESPACE="${1#*=}"
                ;;
            -h|--help) usage ;;
            -*)
                log_error "Unknown option: $1"
                usage
                ;;
            *)
                if [[ -z "$POD_NAME" ]]; then
                    POD_NAME="$1"
                else
                    log_error "Multiple pod names provided"
                    usage
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
}

# Command implementations
cmd_describe() {
    kubectl describe pod "$POD_NAME" -n "$NAMESPACE"
}

cmd_logs() {
    local follow_flag=""
    [[ "$1" == "follow" ]] && follow_flag="-f"
    kubectl logs "$POD_NAME" -n "$NAMESPACE" --tail=100 $follow_flag
}

cmd_list_containers() {
    echo "Containers in pod '$POD_NAME':"
    kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{range .spec.containers[*]}{.name}{"\n"}{end}'
}

cmd_exec() {
    local container="$1"
    if [[ -z "$container" ]]; then
        # Get first container name
        container=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.containers[0].name}')
    fi

    log_info "Starting exec session in container: $container"
    log_info "Type 'exit' to return to debug menu"

    kubectl exec -it "$POD_NAME" -n "$NAMESPACE" -c "$container" -- /bin/bash || \
    kubectl exec -it "$POD_NAME" -n "$NAMESPACE" -c "$container" -- /bin/sh
}

cmd_show_yaml() {
    kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o yaml
}

cmd_events() {
    local ns_flag=""
    [[ "$NAMESPACE" != "default" ]] && ns_flag="-n $NAMESPACE"
    kubectl get events $ns_flag --field-selector involvedObject.name=$POD_NAME --sort-by='.lastTimestamp'
}

main() {
    parse_args "$@"

    validate_pod

    log_info "Debugging pod: $POD_NAME (namespace: $NAMESPACE)"
    print_banner

    while true; do
        echo -ne "\n${BLUE}[debug]${NC} > " >&2
        read -r cmd args

        case "$cmd" in
            q|quit)
                log_info "Exiting debug session"
                break
                ;;
            ?|h|help)
                print_banner
                ;;
            d)
                cmd_describe
                ;;
            l)
                cmd_logs "$args"
                ;;
            lf)
                cmd_logs "follow"
                ;;
            ls)
                cmd_list_containers
                ;;
            e)
                cmd_exec "$args"
                ;;
            ec)
                cmd_exec "$args"
                ;;
            p)
                cmd_show_yaml
                ;;
            eo)
                cmd_events
                ;;
            "")
                # Empty input, continue
                ;;
            *)
                log_warn "Unknown command: $cmd (type ? for help)"
                ;;
        esac
    done
}

main "$@"