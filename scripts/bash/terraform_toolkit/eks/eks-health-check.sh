#!/usr/bin/env bash
set -euo pipefail

# EKS Cluster Health Check Script
# Purpose: Verify EKS cluster health and node status
# Requirements: kubectl, aws cli

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

CLUSTER_NAME="${CLUSTER_NAME:-my-eks-cluster}"
AWS_REGION="${AWS_REGION:-us-east-1}"

check_cluster_status() {
    log_info "Checking cluster status..."
    local status
    status=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" --query 'cluster.status' --output text 2>/dev/null)
    
    if [ "$status" = "ACTIVE" ]; then
        log_info "Cluster status: ACTIVE"
        return 0
    else
        log_error "Cluster status: $status"
        return 1
    fi
}

check_nodes() {
    log_info "Checking nodes..."
    local node_count
    node_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    
    if [ "$node_count" -gt 0 ]; then
        log_info "Nodes: $node_count ready"
        kubectl get nodes
        return 0
    else
        log_error "No nodes found"
        return 1
    fi
}

check_system_pods() {
    log_info "Checking system pods..."
    local not_ready
    not_ready=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -v "Running" | grep -v "Completed" | wc -l)
    
    if [ "$not_ready" -eq 0 ]; then
        log_info "All system pods running"
        kubectl get pods -n kube-system
        return 0
    else
        log_warn "$not_ready system pods not ready"
        kubectl get pods -n kube-system
        return 1
    fi
}

check_core_addons() {
    log_info "Checking core addons..."
    local addons=("kube-proxy" "vpc-cni" "coredns")
    
    for addon in "${addons[@]}"; do
        local status
        status=$(aws eks describe-addon --cluster-name "$CLUSTER_NAME" --addon-name "$addon" --region "$AWS_REGION" --query 'addon.status' --output text 2>/dev/null)
        
        if [ "$status" = "ACTIVE" ]; then
            log_info "Addon $addon: ACTIVE"
        else
            log_warn "Addon $addon: $status"
        fi
    done
}

check_api_server() {
    log_info "Checking API server..."
    
    if kubectl cluster-info >/dev/null 2>&1; then
        log_info "API server: reachable"
        return 0
    else
        log_error "API server: unreachable"
        return 1
    fi
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -n, --name NAME     Cluster name (default: my-eks-cluster)
    -r, --region REGION AWS region (default: us-east-1)
    -h, --help         Show this help message

Examples:
    $0
    $0 -n my-cluster -r us-west-2
EOF
}

main() {
    for arg in "$@"; do
        case $arg in
            -n|--name) CLUSTER_NAME="$2"; shift 2 ;;
            -r|--region) AWS_REGION="$2"; shift 2 ;;
            -h|--help) show_usage; exit 0 ;;
        esac
    done
    
    log_info "Running EKS health checks..."
    log_info "Cluster: $CLUSTER_NAME"
    log_info "Region: $AWS_REGION"
    echo ""
    
    local failed=0
    
    check_cluster_status || ((failed++))
    echo ""
    
    check_api_server || ((failed++))
    echo ""
    
    check_nodes || ((failed++))
    echo ""
    
    check_system_pods || ((failed++))
    echo ""
    
    check_core_addons
    echo ""
    
    if [ $failed -eq 0 ]; then
        log_info "All health checks passed"
        exit 0
    else
        log_error "$failed health check(s) failed"
        exit 1
    fi
}

main "$@"
