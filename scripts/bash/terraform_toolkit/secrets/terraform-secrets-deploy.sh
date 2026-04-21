#!/usr/bin/env bash
set -euo pipefail

# Terraform Secrets Manager deployment script
# Purpose: Deploy and manage AWS Secrets Manager resources via Terraform
# Requirements: AWS credentials, Terraform >= 1.0
# Safety: Uses Terraform's -auto-approve with explicit confirmation for destructive ops

readonly SCRIPT_NAME="terraform-secrets-deploy"
readonly SCRIPT_VERSION="1.0.0"

# Configuration
ENVIRONMENT="${1:-dev}"
ACTION="${2:-apply}"
PROJECT_NAME="${PROJECT_NAME:-myproject}"
AWS_REGION="${AWS_REGION:-us-east-1}"

# ANSI colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { echo -e "${BLUE}[DEBUG]${NC} $1"; }

usage() {
    cat <<EOF
$SCRIPT_NAME v$SCRIPT_VERSION

Usage: $SCRIPT_NAME <environment> <action>

Arguments:
  environment  Environment name (dev, staging, prod) [default: dev]
  action      Action to perform (plan, apply, destroy) [default: apply]

Examples:
  $SCRIPT_NAME dev plan
  $SCRIPT_NAME prod apply
  $SCRIPT_NAME dev destroy
EOF
}

# Check for required tools
check_dependencies() {
    local deps=("terraform" "aws")
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "$cmd not found. Please install $cmd first."
            exit 1
        fi
    done
    log_debug "All dependencies satisfied"
}

# Validate environment
validate_environment() {
    if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod|devops)$ ]]; then
        log_error "Invalid environment: $ENVIRONMENT. Use: dev, staging, prod, or devops"
        exit 1
    fi
}

# Check AWS credentials
check_aws_credentials() {
    log_info "Verifying AWS credentials..."
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        log_error "AWS credentials not configured or invalid"
        exit 1
    fi
    log_debug "AWS credentials valid"
}

# Initialize Terraform
terraform_init() {
    log_info "Initializing Terraform for environment: $ENVIRONMENT"
    cd "environments/$ENVIRONMENT" || { log_error "Environment directory not found"; exit 1; }
    
    if [ -n "${DRY_RUN:-}" ]; then
        log_warn "DRY_RUN mode enabled - will not actually initialize"
        return
    fi
    
    terraform init -upgrade || { log_error "Terraform init failed"; exit 1; }
    log_debug "Terraform initialized successfully"
}

# Generate plan
terraform_plan() {
    log_info "Generating Terraform plan..."
    
    if [ -n "${DRY_RUN:-}" ]; then
        log_warn "DRY_RUN mode enabled - would generate plan"
        return
    fi
    
    terraform plan -out=tfplan || { log_error "Terraform plan failed"; exit 1; }
    log_debug "Plan saved to tfplan"
}

# Apply changes
terraform_apply() {
    log_info "Applying Terraform changes..."
    
    if [ -n "${DRY_RUN:-}" ]; then
        log_warn "DRY_RUN mode enabled - would apply changes"
        return
    fi
    
    if [ -f tfplan ]; then
        terraform apply tfplan || { log_error "Terraform apply failed"; exit 1; }
    else
        log_error "No plan file found. Run 'plan' first."
        exit 1
    fi
    log_debug "Changes applied successfully"
}

# Destroy environment
terraform_destroy() {
    log_warn "WARNING: This will destroy all secrets in $ENVIRONMENT!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        log_info "Destroy cancelled"
        exit 0
    fi
    
    log_info "Destroying $ENVIRONMENT resources..."
    
    if [ -n "${DRY_RUN:-}" ]; then
        log_warn "DRY_RUN mode enabled - would destroy resources"
        return
    fi
    
    terraform destroy -auto-approve || { log_error "Terraform destroy failed"; exit 1; }
    log_info "Resources destroyed"
}

# Main execution
main() {
    log_info "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
    log_info "Environment: $ENVIRONMENT, Action: $ACTION"
    
    check_dependencies
    validate_environment
    check_aws_credentials
    
    # Store original directory
    local base_dir
    base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    cd "$base_dir" || { log_error "Failed to change to base directory"; exit 1; }
    log_debug "Working directory: $(pwd)"
    
    case "$ACTION" in
        plan)
            terraform_init
            terraform_plan
            ;;
        apply)
            terraform_init
            terraform_plan
            terraform_apply
            ;;
        destroy)
            terraform_destroy
            ;;
        *)
            log_error "Unknown action: $ACTION"
            usage
            exit 1
            ;;
    esac
    
    log_info "Completed successfully"
    cd "$base_dir"
}

# Run main with all arguments
main "$@"