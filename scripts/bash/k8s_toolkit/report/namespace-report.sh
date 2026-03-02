#!/usr/bin/env bash
#
# PURPOSE: Generate a comprehensive namespace resource report
# USAGE: ./namespace-report.sh [--namespace=<ns>] [--output=<format>] [--include-events]
# REQUIREMENTS: kubectl configured with cluster access
# SAFETY: Read-only reporting, no modifications
#
# OUTPUT: Summary of pods, deployments, services, PVCs, events, resource usage
#
# EXAMPLES:
#   ./namespace-report.sh
#   ./namespace-report.sh --namespace=production
#   ./namespace-report.sh --namespace=default --include-events
#   ./namespace-report.sh --output=wide

set -euo pipefail
IFS=$'\n\t'

# Defaults
NAMESPACE="default"
OUTPUT_FORMAT="text"
INCLUDE_EVENTS=0
INCLUDE_METRICS=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
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

print_header() {
    echo -e "${CYAN}========== $1 ==========${NC}"
}

print_subheader() {
    echo -e "${MAGENTA}>> $1${NC}"
}

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
            --output=*)
                OUTPUT_FORMAT="${1#*=}"
                ;;
            --include-events) INCLUDE_EVENTS=1 ;;
            --include-metrics) INCLUDE_METRICS=1 ;;
            -h|--help) usage ;;
            -*)
                log_error "Unknown option: $1"
                usage
                ;;
            *)
                log_warn "Unexpected argument: $1 (ignoring)"
                ;;
        esac
        shift
    done
}

validate_namespace() {
    if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        log_error "Namespace '$NAMESPACE' does not exist"
        exit 1
    fi
}

check_metrics_available() {
    if kubectl get --raw "/apis/metrics.k8s.io/v1beta1/namespaces/$NAMESPACE/pods" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

report_intro() {
    echo ""
    print_header "Namespace Report: $NAMESPACE"
    echo "Generated: $(date -u +%Y-%m-%d\ %H:%M:%S\ UTC)"
    echo ""
}

report_pods() {
    print_subheader "Pods"
    kubectl get pods -n "$NAMESPACE" -o wide

    local pod_count
    pod_count=$(kubectl get pods -n "$NAMESPACE" --no-headers | wc -l)
    echo "Total pods: $pod_count"
    echo ""

    # Pod phase breakdown
    print_subheader "Pod Phases"
    kubectl get pods -n "$NAMESPACE" -o custom-columns=NAME:.metadata.name,PHASE:.status.phase --no-headers | \
        sort | uniq -c | sort -rn
    echo ""
}

report_deployments() {
    if kubectl get deployments -n "$NAMESPACE" >/dev/null 2>&1; then
        print_subheader "Deployments"
        kubectl get deployments -n "$NAMESPACE"

        local deploy_count
        deploy_count=$(kubectl get deployments -n "$NAMESPACE" --no-headers | wc -l)
        echo "Total deployments: $deploy_count"
        echo ""
    fi
}

report_daemonsets() {
    if kubectl get daemonsets -n "$NAMESPACE" >/dev/null 2>&1; then
        print_subheader "DaemonSets"
        kubectl get daemonsets -n "$NAMESPACE"

        local ds_count
        ds_count=$(kubectl get daemonsets -n "$NAMESPACE" --no-headers | wc -l)
        echo "Total daemonsets: $ds_count"
        echo ""
    fi
}

report_services() {
    print_subheader "Services"
    kubectl get services -n "$NAMESPACE"

    local svc_count
    svc_count=$(kubectl get services -n "$NAMESPACE" --no-headers | wc -l)
    echo "Total services: $svc_count"
    echo ""
}

report_pvcs() {
    if kubectl get persistentvolumeclaims -n "$NAMESPACE" >/dev/null 2>&1; then
        print_subheader "PersistentVolumeClaims"
        kubectl get persistentvolumeclaims -n "$NAMESPACE"

        local pvc_count
        pvc_count=$(kubectl get persistentvolumeclaims -n "$NAMESPACE" --no-headers | wc -l)
        echo "Total PVCs: $pvc_count"
        echo ""
    fi
}

report_ingresses() {
    if kubectl get ingresses -n "$NAMESPACE" >/dev/null 2>&1; then
        print_subheader "Ingresses"
        kubectl get ingresses -n "$NAMESPACE"

        local ing_count
        ing_count=$(kubectl get ingresses -n "$NAMESPACE" --no-headers | wc -l)
        echo "Total ingresses: $ing_count"
        echo ""
    fi
}

report_configmaps_secrets() {
    print_subheader "ConfigMaps & Secrets"
    echo "ConfigMaps: $(kubectl get configmaps -n "$NAMESPACE" --no-headers | wc -l)"
    echo "Secrets: $(kubectl get secrets -n "$NAMESPACE" --no-headers | wc -l)"
    echo ""
}

report_metrics() {
    if [[ $INCLUDE_METRICS -eq 1 ]]; then
        if check_metrics_available; then
            print_subheader "Resource Usage (Metrics)"
            if kubectl get --raw "/apis/metrics.k8s.io/v1beta1/namespaces/$NAMESPACE/pods" | \
               jq -r '.items[] | "\(.metadata.name) \(.containers[0].usage.cpu // "0") \(.containers[0].usage.memory // "0")"' 2>/dev/null; then
                echo ""
            else
                log_warn "jq not available or metrics endpoint returned unexpected data"
                echo "Use: kubectl top pods -n $NAMESPACE"
                echo ""
            fi
        else
            log_warn "Metrics API not available"
            echo ""
        fi
    fi
}

report_events() {
    if [[ $INCLUDE_EVENTS -eq 1 ]]; then
        print_subheader "Recent Events (last 24h)"
        kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' | head -n 20
        echo ""
    fi
}

report_issues() {
    print_subheader "Potential Issues"

    local failed_pods
    failed_pods=$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{range .items[?(@.status.phase=="Failed")]}{.metadata.name}{"\n"}{end}' 2>/dev/null)

    if [[ -n "$failed_pods" ]]; then
        echo -e "${RED}Failed pods:${NC}"
        echo "$failed_pods"
    else
        echo "No failed pods detected"
    fi

    local pending_pods
    pending_pods=$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{range .items[?(@.status.phase=="Pending")]}{.metadata.name}{"\n"}{end}' 2>/dev/null)

    if [[ -n "$pending_pods" ]]; then
        echo -e "${YELLOW}Pending pods:${NC}"
        echo "$pending_pods"
        echo "Common causes: insufficient resources, PVC binding, node selector/taints"
    fi

    local restarted_containers
    restarted_containers=$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{range .status.containerStatuses[*]}{.name}{": "}{.restartCount}{"\n"}{end}{end}' 2>/dev/null | \
        awk '$2 > 0' || true)

    if [[ -n "$restarted_containers" ]]; then
        echo -e "${YELLOW}Containers with restarts:${NC}"
        echo "$restarted_containers" | column -t
    fi

    echo ""
}

main() {
    parse_args "$@"

    validate_namespace

    report_intro
    report_pods
    report_deployments
    report_daemonsets
    report_services
    report_pvcs
    report_ingresses
    report_configmaps_secrets
    report_metrics
    report_events
    report_issues

    log_info "Report complete for namespace: $NAMESPACE"
}

main "$@"
