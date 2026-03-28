#!/usr/bin/env bash
set -euo pipefail

# Terraform EKS Cluster Deployment Script
# Purpose: Automate EKS cluster provisioning with managed node groups
# Requirements: terraform, aws cli, kubectl
# Safety: Supports DRY_RUN mode

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/../../../docs/how-to"

DRY_RUN="${DRY_RUN:-false}"
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
    local deps=("terraform" "aws" "kubectl")
    for dep in "${deps[@]}"; do
        command -v "$dep" >/dev/null 2>&1 || { log_error "$dep not found"; exit 1; }
    done
    log_info "All dependencies satisfied"
}

init_terraform() {
    log_info "Initializing Terraform..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would run: terraform init"
        return 0
    fi
    terraform -chdir="$TERRAFORM_DIR" init -upgrade
}

plan_terraform() {
    log_info "Planning Terraform changes..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would run: terraform plan"
        return 0
    fi
    terraform -chdir="$TERRAFORM_DIR" plan -out=tfplan
}

apply_terraform() {
    log_info "Applying Terraform changes..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would run: terraform apply"
        return 0
    fi
    terraform -chdir="$TERRAFORM_DIR" apply tfplan
}

configure_kubectl() {
    log_info "Configuring kubectl..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would run: aws eks update-kubeconfig"
        return 0
    fi
    aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION"
}

verify_cluster() {
    log_info "Verifying cluster..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would verify cluster"
        return 0
    fi
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if kubectl get nodes >/dev/null 2>&1; then
            log_info "Cluster is ready"
            kubectl get nodes
            return 0
        fi
        log_info "Waiting for cluster... (attempt $attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done
    
    log_error "Cluster verification failed"
    return 1
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --dry-run         Show what would be done without making changes
    --init            Initialize Terraform only
    --plan            Run Terraform plan only
    --apply           Run Terraform apply (requires confirmation)
    --full            Run full deployment pipeline
    --verify          Verify cluster after deployment
    -h, --help        Show this help message

Environment Variables:
    DRY_RUN          Set to 'true' for dry-run mode
    AWS_REGION       AWS region (default: us-east-1)
    CLUSTER_NAME     EKS cluster name (default: my-eks-cluster)

Examples:
    $0 --dry-run --full
    $0 --init --plan
    $0 --apply
EOF
}

main() {
    local action="full"
    
    for arg in "$@"; do
        case $arg in
            --dry-run) DRY_RUN=true ;;
            --init) action="init" ;;
            --plan) action="plan" ;;
            --apply) action="apply" ;;
            --full) action="full" ;;
            --verify) action="verify" ;;
            -h|--help) show_usage; exit 0 ;;
        esac
    done
    
    log_info "Starting EKS deployment..."
    log_info "DRY_RUN: $DRY_RUN"
    log_info "AWS_REGION: $AWS_REGION"
    log_info "CLUSTER_NAME: $CLUSTER_NAME"
    
    check_dependencies
    
    case $action in
        init)
            init_terraform
            ;;
        plan)
            init_terraform
            plan_terraform
            ;;
        apply)
            init_terraform
            plan_terraform
            apply_terraform
            ;;
        full)
            init_terraform
            plan_terraform
            apply_terraform
            configure_kubectl
            verify_cluster
            ;;
        verify)
            verify_cluster
            ;;
    esac
    
    log_info "EKS deployment complete"
}

main "$@"
