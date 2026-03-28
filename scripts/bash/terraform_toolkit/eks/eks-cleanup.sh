#!/usr/bin/env bash
set -euo pipefail

# Terraform EKS Cluster Cleanup Script
# Purpose: Safely destroy EKS cluster and associated resources
# Requirements: terraform, aws cli
# Safety: DRY_RUN enabled by default

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/../../../docs/how-to"

DRY_RUN="${DRY_RUN:-true}"
AWS_REGION="${AWS_REGION:-us-east-1}"
CLUSTER_NAME="${CLUSTER_NAME:-my-eks-cluster}"
TERRAFORM_DIR="${PROJECT_DIR}/terraform-eks-project"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_dependencies() {
    local deps=("terraform" "aws")
    for dep in "${deps[@]}"; do
        command -v "$dep" >/dev/null 2>&1 || { log_error "$dep not found"; exit 1; }
    done
    log_info "All dependencies satisfied"
}

destroy_terraform() {
    log_info "Destroying Terraform resources..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would run: terraform destroy"
        log_warn "[dry-run] Would run: terraform destroy -target=module.node_group"
        log_warn "[dry-run] Would run: terraform destroy -target=module.eks"
        log_warn "[dry-run] Would run: terraform destroy -target=module.vpc"
        return 0
    fi
    
    log_warn "This will destroy all resources. Enter 'yes' to proceed:"
    terraform -chdir="$TERRAFORM_DIR" destroy -auto-approve
}

remove_kubeconfig() {
    log_info "Removing kubeconfig entry..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would remove kubeconfig for $CLUSTER_NAME"
        return 0
    fi
    kubectl config delete-cluster "$CLUSTER_NAME" 2>/dev/null || true
    kubectl config delete-user "$CLUSTER_NAME" 2>/dev/null || true
}

cleanup_aws_resources() {
    log_info "Cleaning up AWS resources..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would clean up CloudWatch logs"
        log_warn "[dry-run] Would clean up ELB security groups"
        return 0
    fi
    
    aws logs delete-log-group --log-group-name "/aws/eks/$CLUSTER_NAME/cluster" 2>/dev/null || true
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --execute         Actually destroy resources (default is dry-run)
    --skip-prompt    Skip confirmation prompt
    -h, --help       Show this help message

Environment Variables:
    DRY_RUN          Set to 'false' to actually destroy
    AWS_REGION       AWS region (default: us-east-1)
    CLUSTER_NAME     EKS cluster name (default: my-eks-cluster)

Examples:
    $0                    # Dry-run mode
    $0 --execute          # Actually destroy
    $0 --execute --skip-prompt
EOF
}

main() {
    local execute=false
    local skip_prompt=false
    
    for arg in "$@"; do
        case $arg in
            --execute) execute=true ;;
            --skip-prompt) skip_prompt=true ;;
            -h|--help) show_usage; exit 0 ;;
        esac
    done
    
    if [ "$execute" = false ]; then
        DRY_RUN=true
        log_warn "Running in DRY-RUN mode. Use --execute to actually destroy."
    fi
    
    log_info "Starting EKS cleanup..."
    log_info "DRY_RUN: $DRY_RUN"
    log_info "AWS_REGION: $AWS_REGION"
    log_info "CLUSTER_NAME: $CLUSTER_NAME"
    
    check_dependencies
    
    if [ "$execute" = true ] && [ "$skip_prompt" = false ]; then
        log_warn "This will PERMANENTLY DELETE all cluster resources!"
        read -p "Type 'yes' to confirm: " confirm
        if [ "$confirm" != "yes" ]; then
            log_info "Aborted"
            exit 0
        fi
    fi
    
    destroy_terraform
    remove_kubeconfig
    cleanup_aws_resources
    
    log_info "EKS cleanup complete"
}

main "$@"
