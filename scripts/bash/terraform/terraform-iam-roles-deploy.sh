#!/usr/bin/env bash
set -euo pipefail

# terraform-iam-roles-deploy.sh — Deploy Terraform IAM roles with policy modules
# Purpose: Deploy reusable IAM roles and policy modules to AWS
# Usage: ./terraform-iam-roles-deploy.sh [--plan-only] [--destroy] [--target=<module>]
# Requirements: Terraform 1.10+, AWS CLI, appropriate IAM permissions
# Safety: Dry-run mode supported (set DRY_RUN=true)
# Tested OS: Ubuntu 22.04, macOS 13+, Amazon Linux 2023

DRY_RUN=${DRY_RUN:-false}
PLAN_ONLY=false
DESTROY=false
TARGET_MODULE=""

log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_warn() { echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*"; }

command -v terraform >/dev/null 2>&1 || { log_error "Terraform not found. Install from https://www.terraform.io/downloads.html"; exit 1; }
command -v aws >/dev/null 2>&1 || { log_error "AWS CLI not found. Install from https://aws.amazon.com/cli/"; exit 1; }

show_usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --plan-only      Run terraform plan only, no apply
  --destroy        Destroy resources instead of applying
  --target=<module> Apply/destroy only the specified module
  --dry-run        Show what would be done without executing

Examples:
  $0                              # Deploy IAM roles and policies
  $0 --plan-only                  # Plan only, for review
  $0 --target=module.app_role     # Deploy specific module
  $0 --destroy                    # Destroy all resources
  DRY_RUN=true $0                 # Dry-run mode

EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_usage
        exit 0
        ;;
      --plan-only)
        PLAN_ONLY=true
        shift
        ;;
      --destroy)
        DESTROY=true
        shift
        ;;
      --target=*)
        TARGET_MODULE="$1"
        TARGET_MODULE="${TARGET_MODULE#*=}"
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      *)
        log_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
    esac
  done
}

check_aws_credentials() {
  log_info "Verifying AWS credentials..."
  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    log_error "AWS credentials not configured. Run 'aws configure' first."
    exit 1
  fi
  local account_id
  account_id=$(aws sts get-caller-identity --query 'Account' --output text)
  log_info "Authenticated as: $account_id"
  echo "$account_id"
}

check_iam_permissions() {
  log_info "Verifying IAM permissions..."
  local required_perms=(
    "iam:CreateRole"
    "iam:DeleteRole"
    "iam:CreatePolicy"
    "iam:DeletePolicy"
    "iam:AttachRolePolicy"
    "iam:DetachRolePolicy"
  )
  for perm in "${required_perms[@]}"; do
    if ! aws iam simulate-principal-policy \
      --policy-source-type aws-managed \
      --action-name "$perm" \
      --resource-arn "arn:aws:iam::*:role/test" >/dev/null 2>&1; then
      log_warn "Missing IAM permission: $perm"
    fi
  done
}

terraform_init() {
  log_info "Initializing Terraform..."
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[dry-run] Would run: terraform init"
    return 0
  fi
  terraform init -upgrade
}

terraform_validate() {
  log_info "Validating Terraform configuration..."
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[dry-run] Would run: terraform validate"
    return 0
  fi
  if ! terraform validate; then
    log_error "Terraform validation failed"
    exit 1
  fi
}

terraform_plan() {
  local target_arg=""
  if [[ -n "$TARGET_MODULE" ]]; then
    target_arg="-target=$TARGET_MODULE"
  fi
  
  log_info "Creating Terraform plan..."
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[dry-run] Would run: terraform plan $target_arg"
    return 0
  fi
  
  if [[ "$DESTROY" == "true" ]]; then
    terraform plan -destroy -out=tfplan $target_arg
  else
    terraform plan -out=tfplan $target_arg
  fi
}

terraform_apply() {
  local target_arg=""
  if [[ -n "$TARGET_MODULE" ]]; then
    target_arg="-target=$TARGET_MODULE"
  fi
  
  log_info "Applying Terraform configuration..."
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[dry-run] Would run: terraform apply tfplan $target_arg"
    return 0
  fi
  
  if [[ "$DESTROY" == "true" ]]; then
    log_warn "Destroy mode: This will remove all IAM roles and policies"
    read -p "Are you sure? Type 'yes' to confirm: " confirm
    [[ "$confirm" != "yes" ]] && { log_info "Aborted"; exit 0; }
  fi
  
  terraform apply tfplan $target_arg
}

show_outputs() {
  log_info "Deployment outputs:"
  terraform output --json 2>/dev/null | jq -r 'to_entries[] | "  \(.key): \(.value.value)"'
}

main() {
  parse_args "$@"
  
  log_info "Starting Terraform IAM Roles deployment"
  log_info "========================================="
  
  local account_id
  account_id=$(check_aws_credentials)
  check_iam_permissions
  terraform_init
  terraform_validate
  terraform_plan
  
  if [[ "$PLAN_ONLY" == "false" ]]; then
    if [[ "$DESTROY" == "true" ]]; then
      log_warn "Running in DESTROY mode"
    fi
    terraform_apply
    show_outputs
  else
    log_info "Plan complete. Run without --plan-only to apply."
  fi
  
  log_info "Done!"
}

main "$@"
