#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_NAME="ter-019-deploy"
readonly SCRIPT_VERSION="1.0.0"

# Terraform EventBridge with Lambda triggers deployment script
# This script deploys EventBridge rules that trigger Lambda functions based on events
# Requirements: terraform, aws cli, jq
# Safety: Read-only plan by default. Use --apply to deploy, --destroy to teardown.

usage() {
    cat <<EOF
$SCRIPT_NAME v$SCRIPT_VERSION

Usage: $SCRIPT_NAME [OPTIONS]

Description:
  Deploy EventBridge rules with Lambda triggers using Terraform.
  Creates EventBridge rules that capture events and invoke Lambda functions.

Options:
  --environment ENV   Environment name: dev, staging, prod (default: dev)
  --region REGION     AWS region (default: us-east-1)
  --plan              Run terraform plan only (default)
  --apply             Run terraform apply to deploy
  --destroy           Run terraform destroy to teardown
  --var-file FILE     Additional tfvars file
  -h, --help          Show this help message

Examples:
  # Plan only (default)
  $SCRIPT_NAME --environment prod --region us-east-1 --plan

  # Apply deployment
  $SCRIPT_NAME --environment prod --region us-east-1 --apply

  # Destroy resources
  $SCRIPT_NAME --environment prod --region us-east-1 --destroy
EOF
}

log_info() { echo -e "[INFO] $*"; }
log_warn() { echo -e "[WARN] $*"; }
log_error() { echo -e "[ERROR] $*"; }
log_success() { echo -e "[SUCCESS] $*"; }

ENVIRONMENT="dev"
REGION="us-east-1"
ACTION="plan"
VAR_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --region)
            REGION="$2"
            shift 2
            ;;
        --plan)
            ACTION="plan"
            shift
            ;;
        --apply)
            ACTION="apply"
            shift
            ;;
        --destroy)
            ACTION="destroy"
            shift
            ;;
        --var-file)
            VAR_FILE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

check_dependencies() {
    local deps=("terraform" "aws" "jq")
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "$cmd not found. Please install $cmd first."
            exit 1
        fi
    done
    log_info "All dependencies satisfied"
}

check_aws_auth() {
    log_info "Verifying AWS authentication..."
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        log_error "AWS CLI not authenticated. Run 'aws configure' first."
        exit 1
    fi
    local account_id
    account_id=$(aws sts get-caller-identity --query 'Account' --output text)
    log_info "Authenticated as AWS account: $account_id in region: $REGION"
}

setup_terraform() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local tf_dir="$script_dir/../../terraform/eventbridge-lambda"

    if [[ ! -d "$tf_dir" ]]; then
        log_error "Terraform directory not found: $tf_dir"
        exit 1
    fi

    cd "$tf_dir"

    export TF_VAR_environment="$ENVIRONMENT"
    export AWS_REGION="$REGION"

    if [[ -n "$VAR_FILE" ]]; then
        if [[ -f "$VAR_FILE" ]]; then
            export TF_VAR_file="$VAR_FILE"
        else
            log_warn "Var file not found: $VAR_FILE, continuing without it"
        fi
    fi

    log_info "Terraform workspace: $ENVIRONMENT"
    log_info "AWS region: $REGION"
}

run_terraform() {
    log_info "Running terraform $ACTION..."

    case "$ACTION" in
        plan)
            terraform plan -var-file="environments/${ENVIRONMENT}.tfvars" -out="tfplan"
            log_success "Terraform plan complete. Run with --apply to deploy."
            ;;
        apply)
            log_warn "About to apply terraform changes..."
            read -p "Continue? (yes/no): " confirm
            if [[ "$confirm" != "yes" ]]; then
                log_info "Aborted by user"
                exit 0
            fi
            terraform apply -var-file="environments/${ENVIRONMENT}.tfvars" tfplan
            log_success "Terraform apply complete"
            ;;
        destroy)
            log_warn "About to DESTROY all resources..."
            read -p "Type 'yes' to confirm: " confirm
            if [[ "$confirm" != "yes" ]]; then
                log_info "Aborted by user"
                exit 0
            fi
            terraform destroy -var-file="environments/${ENVIRONMENT}.tfvars" -auto-approve
            log_success "Terraform destroy complete"
            ;;
    esac
}

main() {
    log_info "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
    log_info "Environment: $ENVIRONMENT, Region: $REGION, Action: $ACTION"

    check_dependencies
    check_aws_auth
    setup_terraform
    run_terraform

    log_success "Completed successfully"
}

main "$@"