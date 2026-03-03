#!/usr/bin/env bash
#
# PURPOSE: Restart a Kubernetes pod gracefully by deleting it (replicated by controllers)
# USAGE: ./restart-pod.sh <pod-name> [--namespace=<ns>] [--grace-period=<seconds>] [--force] [--dry-run]
# REQUIREMENTS: Pod must exist and be managed by a controller (deployment/statefulset/daemonset)
# SAFETY: Deleting pod causes controller to recreate it. With --force, pod is killed immediately. --dry-run shows intended actions without execution.
#
# EXAMPLES:
#   ./restart-pod.sh my-app-5d94f6b7f9-abcde
#   ./restart-pod.sh my-app-5d94f6b7f9-abcde --namespace=default
#   ./restart-pod.sh my-app-5d94f6b7f9-abcde --grace-period=30
#   ./restart-pod.sh my-app-5d94f6b7f9-abcde --dry-run

set -euo pipefail
IFS=$'\n\t'

# Defaults
GRACE_PERIOD=30
NAMESPACE="default"
FORCE=0
DRY_RUN=0

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
            --namespace=*| -n=*)
                NAMESPACE="${1#*=}"
                ;;
            --grace-period=*)
                GRACE_PERIOD="${1#*=}"
                ;;
            --force) FORCE=1 ;;
            --dry-run) DRY_RUN=1 ;;
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

main() {
    parse_args "$@"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "DRY RUN MODE - No changes will be made"
    fi

    validate_pod

    # Capture controller information before deletion
    local controller_kind controller_name
    controller_kind=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.metadata.ownerReferences[0].kind}' 2>/dev/null || echo "")
    controller_name=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.metadata.ownerReferences[0].name}' 2>/dev/null || echo "")

    # Check if standalone
    if [[ -z "$controller_kind" || -z "$controller_name" ]]; then
        log_warn "Pod '$POD_NAME' has no controller (standalone). Deleting it will terminate it permanently."
        if [[ $DRY_RUN -eq 0 ]]; then
            read -p "Are you sure you want to continue? (yes/no): " confirm
            if [[ "$confirm" != "yes" ]]; then
                log_info "Aborted."
                exit 0
            fi
        fi
    fi

    log_info "Restarting pod: $POD_NAME (namespace: $NAMESPACE)"
    log_info "Grace period: ${GRACE_PERIOD}s"

    if [[ $FORCE -eq 1 ]]; then
        log_warn "Force mode: pod will be terminated immediately"
        GRACE_PERIOD=0
    fi

    local delete_cmd="kubectl delete pod $POD_NAME -n $NAMESPACE"
    if [[ $GRACE_PERIOD -gt 0 ]]; then
        delete_cmd="$delete_cmd --grace-period=$GRACE_PERIOD"
    fi

    log_info "Would execute: $delete_cmd"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] No changes made."
        exit 0
    fi

    log_info "Executing: $delete_cmd"
    if eval "$delete_cmd"; then
        log_info "Pod '$POD_NAME' deletion initiated. Controller will recreate it."
        log_info "Waiting for new pod to become ready..."
        sleep 2

        # Use captured controller info
        if [[ -n "$controller_kind" && -n "$controller_name" ]]; then
            local rollout_cmd="kubectl rollout status $controller_kind/$controller_name -n $NAMESPACE --timeout=2m"
            log_info "Running: $rollout_cmd"
            if eval "$rollout_cmd"; then
                log_info "New pod is ready"
                exit 0
            else
                log_warn "Rollout check failed or timed out. Check pod status manually."
                exit 1
            fi
        else
            log_info "No controller found. Pod will not be auto-recreated."
            exit 0
        fi
    else
        log_error "Failed to delete pod"
        exit 1
    fi
}

main "$@"