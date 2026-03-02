#!/usr/bin/env bash
#
# PURPOSE: Monitor multiple deployments for rollouts and health status
# USAGE: ./deployment-monitor.sh [--namespace=<ns>] [--deployments=<list>] [--interval=<seconds>]
# REQUIREMENTS: kubectl access, optional: metrics-server for pod metrics
# SAFETY: Read-only monitoring; no modifications to cluster.
#
# This script polls deployments and reports:
# - Rollout status (available replicas vs desired)
# - Pod restart counts
# - Recent events affecting deployments/pods
#
# Useful for CI/CD pipelines or post-deployment verification.

set -euo pipefail
IFS=$'\n\t'

# Defaults
NAMESPACE="default"
DEPLOYMENTS=()
INTERVAL=10
CHECK_EVENTS=1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

usage() {
    grep '^#' "$0" | cut -c4- | head -n 25 | tail -n +3
    exit 1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --namespace=*| -n=*)
                NAMESPACE="${1#*=}"
                ;;
            --deployments=*)
                IFS=',' read -ra DEPLOYMENTS <<< "${1#*=}"
                ;;
            --interval=*)
                INTERVAL="${1#*=}"
                ;;
            --no-events) CHECK_EVENTS=0 ;;
            -h|--help) usage ;;
            *) log_warn "Unknown arg: $1" ;;
        esac
        shift
    done
}

get_deployments() {
    if [[ ${#DEPLOYMENTS[@]} -eq 0 ]]; then
        # Auto-discover all deployments in namespace
        mapfile -t DEPLOYMENTS < <(kubectl get deployments -n "$NAMESPACE" -o custom-columns=:.metadata.name --no-headers)
    fi
}

check_rollout_status() {
    local deploy="$1"
    local desired available unavailable
    desired=$(kubectl get deployment "$deploy" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
    available=$(kubectl get deployment "$deploy" -n "$NAMESPACE" -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo "0")
    unavailable=$(kubectl get deployment "$deploy" -n "$NAMESPACE" -o jsonpath='{.status.unavailableReplicas}' 2>/dev/null || echo "0")

    desired=${desired:-0}
    available=${available:-0}
    unavailable=${unavailable:-0}

    if [[ "$available" -eq "$desired" && "$unavailable" -eq 0 ]]; then
        echo -e "${GREEN}HEALTHY${NC} (available: $available/$desired)"
    else
        echo -e "${RED}UNHEALTHY${NC} (available: $available/$desired, unavailable: $unavailable)"
    fi
}

check_pod_restarts() {
    local deploy="$1"
    local pods restarts total_restarts=0

    # Get pods owned by this deployment
    mapfile -t pods < <(kubectl get pods -n "$NAMESPACE" -l app="$deploy" -o custom-columns=:metadata.name --no-headers 2>/dev/null || true)

    if [[ ${#pods[@]} -eq 0 ]]; then
        # Try selector from deployment
        local selector
        selector=$(kubectl get deployment "$deploy" -n "$NAMESPACE" -o jsonpath='{.spec.selector.matchLabels}' 2>/dev/null | tr -d '{}' | sed 's/:/=/' | sed 's/ /,/' || echo "")
        if [[ -n "$selector" ]]; then
            mapfile -t pods < <(kubectl get pods -n "$NAMESPACE" -l "$selector" -o custom-columns=:metadata.name --no-headers 2>/dev/null || true)
        fi
    fi

    for pod in "${pods[@]}"; do
        restarts=$(kubectl get pod "$pod" -n "$NAMESPACE" -o jsonpath='{.status.containerStatuses[*].restartCount}' 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        if [[ "$restarts" -gt 0 ]]; then
            echo -e "${YELLOW}$pod${NC}: $restarts restart(s)"
            total_restarts=$((total_restarts + restarts))
        fi
    done

    if [[ $total_restarts -eq 0 ]]; then
        echo -e "${GREEN}No restarts${NC}"
    fi
}

check_recent_events() {
    local deploy="$1"
    echo "Recent events (last 30m):"
    kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' \
        --field-selector involvedObject.kind=Deployment,involvedObject.name="$deploy" \
        --field-selector lastTimestamp>=$(date -d '30 minutes ago' -Iseconds) 2>/dev/null | head -n 5 || \
    echo "  (no recent events)"
}

print_header() {
    echo ""
    echo -e "${BLUE}=== Monitoring Deployment: $1 ===${NC}"
}

print_summary_line() {
    printf "%-40s %-20s %-20s\n" "$1" "$2" "$3"
}

main() {
    parse_args "$@"

    get_deployments

    if [[ ${#DEPLOYMENTS[@]} -eq 0 ]]; then
        log_error "No deployments found in namespace '$NAMESPACE'"
        exit 1
    fi

    log_info "Starting deployment monitor (namespace: $NAMESPACE, interval: ${INTERVAL}s)"
    log_info "Monitoring ${#DEPLOYMENTS[@]} deployment(s): ${DEPLOYMENTS[*]}"
    echo ""
    printf "%-40s %-20s %-20s\n" "DEPLOYMENT" "STATUS" "RESTARTS"
    echo "--------------------------------------------------------------------"

    while true; do
        # Clear previous output block (simple approach: print timestamp and current statuses)
        echo ""
        echo "Check at: $(date '+%Y-%m-%d %H:%M:%S')"
        printf "%-40s %-20s %-20s\n" "DEPLOYMENT" "STATUS" "RESTARTS"
        echo "--------------------------------------------------------------------"

        for deploy in "${DEPLOYMENTS[@]}"; do
            status=$(check_rollout_status "$deploy")
            restarts=$(check_pod_restarts "$deploy" | head -n 1 | sed 's/\x1b\[[0-9;]*m//g')  # strip colors for alignment
            printf "%-40s %-20s %-20s\n" "$deploy" "$status" "$restarts"
        done

        if [[ $CHECK_EVENTS -eq 1 ]]; then
            echo ""
            for deploy in "${DEPLOYMENTS[@]}"; do
                check_recent_events "$deploy"
            done
        fi

        echo ""
        log_info "Waiting ${INTERVAL}s before next check (Ctrl+C to exit)..."
        sleep "$INTERVAL"
    done
}

main "$@"
