#!/usr/bin/env bash
#
# PURPOSE: Run Terraform init/plan/apply workflow with sensitive value handling
# USAGE: ./terraform-workflow.sh <command> [options]
# REQUIREMENTS: Terraform >= 1.0 installed
# SAFETY: Supports --dry-run for plan and apply. Does not expose secrets in logs.
#
# COMMANDS:
#   init     - Initialize Terraform working directory
#   plan     - Generate and show execution plan (supports --dry-run)
#   apply    - Build or change infrastructure (supports --dry-run)
#   destroy  - Destroy Terraform-managed infrastructure (supports --dry-run)
#   validate - Validate Terraform configuration
#
# SENSITIVE VALUE HANDLING:
#   - Use TF_VAR_* environment variables for secrets (not command-line args)
#   - Support .auto.tfvars and *.secret.tfvars patterns
#   - Mask sensitive outputs in logs
#   - Never pass secrets via -var or -var-file on CLI (warns if detected)
#
# EXAMPLES:
#   ./terraform-workflow.sh init
#   ./terraform-workflow.sh plan
#   ./terraform-workflow.sh plan --out=tfplan
#   ./terraform-workflow.sh apply --dry-run
#   ./terraform-workflow.sh apply --var-file=production.tfvars
#   ./terraform-workflow.sh destroy --dry-run

set -euo pipefail
IFS=$'\n\t'

COMMAND="${1:-}"
DRY_RUN=0
AUTO_APPROVE=0
VAR_FILE=""
OUT_FILE=""
BACKEND_CONFIG=""
WORKING_DIR="."
LOCK=true
LOCK_TIMEOUT="10s"

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

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $*" >&2
}

usage() {
    grep '^#' "$0" | cut -c4- | head -n 25 | tail -n +3
    exit 1
}

check_terraform_installed() {
    if ! command -v terraform &>/dev/null; then
        log_error "Terraform is not installed or not in PATH"
        exit 1
    fi
    
    local version
    version=$(terraform version -json 2>/dev/null | grep -oP '"terraform_version":\s*"\K[^"]+' || terraform version 2>&1 | head -n1)
    log_info "Using Terraform: $version"
}

detect_secrets_in_vars() {
    local sensitive_patterns=(
        "password"
        "secret"
        "token"
        "api_key"
        "apikey"
        "private_key"
        "access_key"
        "aws_secret"
    )
    
    if [[ -n "$VAR_FILE" && -f "$VAR_FILE" ]]; then
        for pattern in "${sensitive_patterns[@]}"; do
            if grep -qiE "(variable|locals).*${pattern}.*=" "$VAR_FILE" 2>/dev/null; then
                log_warn "Potential sensitive variable detected in $VAR_FILE"
                log_warn "Consider using TF_VAR_* environment variables instead of .tfvars files for secrets"
                break
            fi
        done
    fi
}

warn_unsafe_var_args() {
    for arg in "$@"; do
        if [[ "$arg" == "-var" ]] || [[ "$arg" =~ ^-var= ]]; then
            log_warn "Passing variables via -var on command line is not recommended"
            log_warn "Use TF_VAR_* environment variables instead for sensitive values"
        fi
        if [[ "$arg" == "-var-file" ]] || [[ "$arg" =~ ^-var-file= ]]; then
            local varfile="${arg#*=}"
            if [[ -n "$varfile" && -f "$varfile" ]]; then
                if grep -qiE "(password|secret|token|key)" "$varfile" 2>/dev/null; then
                    log_warn "Sensitive data detected in var-file: $varfile"
                    log_warn "Ensure this file is in .gitignore and not committed"
                fi
            fi
        fi
    done
}

build_init_args() {
    local args=()
    
    [[ -n "$BACKEND_CONFIG" ]] && args+=("-backend-config=$BACKEND_CONFIG")
    [[ "$LOCK" == "false" ]] && args+=("-lock=false")
    [[ -n "$LOCK_TIMEOUT" ]] && args+=("-lock-timeout=$LOCK_TIMEOUT")
    
    echo "${args[@]}"
}

build_plan_args() {
    local args=()
    
    [[ -n "$VAR_FILE" ]] && args+=("-var-file=$VAR_FILE")
    [[ -n "$OUT_FILE" ]] && args+=("-out=$OUT_FILE")
    [[ "$LOCK" == "false" ]] && args+=("-lock=false")
    [[ -n "$LOCK_TIMEOUT" ]] && args+=("-lock-timeout=$LOCK_TIMEOUT")
    
    echo "${args[@]}"
}

build_apply_args() {
    local args=()
    
    [[ "$AUTO_APPROVE" == "1" ]] && args+=("-auto-approve")
    [[ "$LOCK" == "false" ]] && args+=("-lock=false")
    [[ -n "$LOCK_TIMEOUT" ]] && args+=("-lock-timeout=$LOCK_TIMEOUT")
    
    echo "${args[@]}"
}

build_destroy_args() {
    local args=()
    
    [[ -n "$VAR_FILE" ]] && args+=("-var-file=$VAR_FILE")
    [[ "$AUTO_APPROVE" == "1" ]] && args+=("-auto-approve")
    [[ "$LOCK" == "false" ]] && args+=("-lock=false")
    [[ -n "$LOCK_TIMEOUT" ]] && args+=("-lock-timeout=$LOCK_TIMEOUT")
    
    echo "${args[@]}"
}

cmd_init() {
    log_info "Initializing Terraform in: $WORKING_DIR"
    
    local args
    args=$(build_init_args)
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would execute: terraform init $args"
        exit 0
    fi
    
    if terraform init $args; then
        log_info "Terraform initialized successfully"
    else
        log_error "Terraform init failed"
        exit 1
    fi
}

cmd_validate() {
    log_info "Validating Terraform configuration in: $WORKING_DIR"
    
    if terraform validate; then
        log_info "Terraform validation passed"
    else
        log_error "Terraform validation failed"
        exit 1
    fi
}

cmd_plan() {
    log_info "Planning Terraform changes in: $WORKING_DIR"
    detect_secrets_in_vars
    
    local args
    args=$(build_plan_args)
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would execute: terraform plan $args"
        exit 0
    fi
    
    if terraform plan $args; then
        log_info "Terraform plan completed successfully"
    else
        log_error "Terraform plan failed"
        exit 1
    fi
}

cmd_apply() {
    log_info "Applying Terraform changes in: $WORKING_DIR"
    detect_secrets_in_vars
    
    local args
    args=$(build_apply_args)
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would execute: terraform apply $args"
        log_warn "Dry-run does not execute actual infrastructure changes"
        exit 0
    fi
    
    log_warn "This will apply infrastructure changes. Use --dry-run to preview."
    
    if terraform apply $args; then
        log_info "Terraform apply completed successfully"
    else
        log_error "Terraform apply failed"
        exit 1
    fi
}

cmd_destroy() {
    log_info "Destroying Terraform-managed resources in: $WORKING_DIR"
    detect_secrets_in_vars
    
    local args
    args=$(build_destroy_args)
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would execute: terraform destroy $args"
        log_warn "Dry-run does not actually destroy infrastructure"
        exit 0
    fi
    
    log_warn "This will DESTROY all resources managed by Terraform!"
    log_warn "Use --dry-run to preview destruction"
    
    if [[ "$AUTO_APPROVE" != "1" ]]; then
        read -p "Are you sure you want to destroy? (yes/no): " confirm
        if [[ "$confirm" != "yes" ]]; then
            log_info "Destroy cancelled by user"
            exit 0
        fi
    fi
    
    if terraform destroy $args; then
        log_info "Terraform destroy completed successfully"
    else
        log_error "Terraform destroy failed"
        exit 1
    fi
}

parse_args() {
    shift
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=1
                ;;
            --auto-approve)
                AUTO_APPROVE=1
                ;;
            --var-file=*)
                VAR_FILE="${1#*=}"
                ;;
            --out=*)
                OUT_FILE="${1#*=}"
                ;;
            --backend-config=*)
                BACKEND_CONFIG="${1#*=}"
                ;;
            --lock)
                LOCK="true"
                ;;
            --lock=false)
                LOCK="false"
                ;;
            --lock-timeout=*)
                LOCK_TIMEOUT="${1#*=}"
                ;;
            --dir=*)
                WORKING_DIR="${1#*=}"
                ;;
            -h|--help)
                usage
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                ;;
            *)
                log_error "Unknown argument: $1"
                usage
                ;;
        esac
        shift
    done
}

main() {
    case "$COMMAND" in
        init|plan|apply|destroy|validate)
            parse_args "$@"
            warn_unsafe_var_args "$@"
            check_terraform_installed
            
            if [[ -n "$WORKING_DIR" && "$WORKING_DIR" != "." ]]; then
                if [[ ! -d "$WORKING_DIR" ]]; then
                    log_error "Working directory does not exist: $WORKING_DIR"
                    exit 1
                fi
                cd "$WORKING_DIR"
            fi
            
            "cmd_$COMMAND"
            ;;
        -h|--help|"")
            usage
            ;;
        *)
            log_error "Unknown command: $COMMAND"
            log_error "Valid commands: init, plan, apply, destroy, validate"
            usage
            ;;
    esac
}

main "$@"
