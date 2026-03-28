#!/usr/bin/env bash
set -euo pipefail

# RDS Deployment Automation
# Purpose: Deploy, verify, and manage RDS PostgreSQL with read replicas via Terraform
# Usage: ./rds-deploy.sh --action <plan|apply|destroy|verify|failover-test>
# Requirements: terraform, aws-cli, jq
# Safety: DRY_RUN=true by default — set DRY_RUN=false for destructive operations
# Tested on: Ubuntu 22.04, Amazon Linux 2023

DRY_RUN="${DRY_RUN:-true}"
ACTION=""
TF_DIR="${TF_DIR:-templates/terraform/rds-with-replicas}"
TFVARS="${TFVARS:-terraform.tfvars}"
TIMEOUT="${TIMEOUT:-1800}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_dependencies() {
    local deps=("terraform" "aws" "jq")
    for dep in "${deps[@]}"; do
        command -v "$dep" >/dev/null 2>&1 || { log_error "$dep not found — install it first"; exit 1; }
    done

    if [ ! -d "$TF_DIR" ]; then
        log_error "Terraform directory not found: $TF_DIR"
        exit 1
    fi

    if [ ! -f "$TF_DIR/$TFVARS" ] && [ "$ACTION" != "plan" ]; then
        log_warn "No $TFVARS found — using defaults and environment variables"
    fi

    log_info "All dependencies satisfied"
}

action_plan() {
    log_info "Running terraform plan..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would run: terraform plan -out=rds.tfplan"
        return 0
    fi

    cd "$TF_DIR"
    terraform init -input=false
    terraform validate
    terraform plan -out=rds.tfplan
    log_info "Plan saved to rds.tfplan. Review before applying."
}

action_apply() {
    log_info "Applying RDS configuration..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would run: terraform apply rds.tfplan"
        return 0
    fi

    cd "$TF_DIR"

    if [ ! -f "rds.tfplan" ]; then
        log_error "No rds.tfplan found. Run --action plan first."
        exit 1
    fi

    terraform apply rds.tfplan
    log_info "Apply complete. Waiting for instances to become available..."

    local primary_id
    primary_id=$(terraform output -raw primary_arn 2>/dev/null | awk -F: '{print $NF}' | cut -d/ -f2 || echo "")

    if [ -n "$primary_id" ]; then
        log_info "Waiting for primary instance: $primary_id"
        aws rds wait db-instance-available \
            --db-instance-identifier "$primary_id" \
            --cli-read-timeout "$TIMEOUT" 2>/dev/null || log_warn "Timed out waiting for primary"
    fi

    log_info "Verifying deployment..."
    action_verify_internal
}

action_destroy() {
    log_warn "DESTROYING all RDS resources..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would run: terraform destroy"
        return 0
    fi

    cd "$TF_DIR"

    # Check deletion protection
    local protection
    protection=$(terraform show -json 2>/dev/null | jq -r '.values.root_module.resources[]? | select(.type=="aws_db_instance") | .values.deletion_protection // false' 2>/dev/null | head -1)

    if [ "$protection" = "true" ]; then
        log_error "Deletion protection is enabled. Set deletion_protection = false in terraform.tfvars first."
        exit 1
    fi

    log_warn "This will destroy ALL RDS resources. Continuing in 10 seconds..."
    sleep 10

    terraform plan -destroy -out=destroy.tfplan
    terraform apply destroy.tfplan
    log_info "Destroy complete."
}

action_verify() {
    cd "$TF_DIR"
    action_verify_internal
}

action_verify_internal() {
    log_info "=== RDS Deployment Verification ==="

    local primary_address
    primary_address=$(terraform output -raw primary_address 2>/dev/null || echo "N/A")
    local reader_endpoint
    reader_endpoint=$(terraform output -raw reader_endpoint 2>/dev/null || echo "N/A")
    local replica_count
    replica_count=$(terraform output -json replica_endpoints 2>/dev/null | jq 'length' 2>/dev/null || echo "0")

    echo ""
    echo "  Primary Address:  $primary_address"
    echo "  Reader Endpoint:  $reader_endpoint"
    echo "  Read Replicas:    $replica_count"
    echo ""

    if [ "$primary_address" != "N/A" ]; then
        local primary_id
        primary_id=$(terraform output -raw primary_arn 2>/dev/null | awk -F: '{print $NF}' | cut -d/ -f2 || echo "")

        if [ -n "$primary_id" ]; then
            local status
            status=$(aws rds describe-db-instances \
                --db-instance-identifier "$primary_id" \
                --query 'DBInstances[0].DBInstanceStatus' \
                --output text 2>/dev/null || echo "unknown")
            echo "  Primary Status:   $status"

            local encrypted
            encrypted=$(aws rds describe-db-instances \
                --db-instance-identifier "$primary_id" \
                --query 'DBInstances[0].StorageEncrypted' \
                --output text 2>/dev/null || echo "unknown")
            echo "  Encrypted:        $encrypted"

            local backup_retention
            backup_retention=$(aws rds describe-db-instances \
                --db-instance-identifier "$primary_id" \
                --query 'DBInstances[0].BackupRetentionPeriod' \
                --output text 2>/dev/null || echo "unknown")
            echo "  Backup Retention: $backup_retention days"

            local multi_az
            multi_az=$(aws rds describe-db-instances \
                --db-instance-identifier "$primary_id" \
                --query 'DBInstances[0].MultiAZ' \
                --output text 2>/dev/null || echo "unknown")
            echo "  Multi-AZ:         $multi_az"
        fi
    fi

    echo ""
    log_info "Verification complete."
}

action_failover_test() {
    log_info "=== Failover Test ==="
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would force failover on primary instance"
        return 0
    fi

    cd "$TF_DIR"

    local primary_id
    primary_id=$(terraform output -raw primary_arn 2>/dev/null | awk -F: '{print $NF}' | cut -d/ -f2 || echo "")

    if [ -z "$primary_id" ]; then
        log_error "Could not determine primary instance ID from Terraform output"
        exit 1
    fi

    log_info "Initiating forced failover on: $primary_id"
    aws rds reboot-db-instance \
        --db-instance-identifier "$primary_id" \
        --force-failover

    log_info "Failover initiated. Monitoring status..."
    local elapsed=0
    while [ $elapsed -lt "$TIMEOUT" ]; do
        local status
        status=$(aws rds describe-db-instances \
            --db-instance-identifier "$primary_id" \
            --query 'DBInstances[0].DBInstanceStatus' \
            --output text 2>/dev/null || echo "unknown")

        echo "  Status: $status (${elapsed}s elapsed)"

        if [ "$status" = "available" ]; then
            log_info "Failover complete. Instance is available."
            return 0
        fi

        sleep 10
        elapsed=$((elapsed + 10))
    done

    log_warn "Failover timed out after ${TIMEOUT}s. Check AWS console."
}

show_usage() {
    cat << EOF
Usage: $0 --action <ACTION> [OPTIONS]

Actions:
    plan            Run terraform plan (safe — no changes)
    apply           Apply the terraform plan (requires prior plan)
    destroy         Destroy all RDS resources (CAUTION)
    verify          Verify current deployment status
    failover-test   Force failover on primary instance

Options:
    --dir DIR       Terraform directory (default: templates/terraform/rds-with-replicas)
    --tfvars FILE   Variables file (default: terraform.tfvars)
    --timeout SECS  Wait timeout in seconds (default: 1800)
    -h, --help      Show this help message

Environment Variables:
    DRY_RUN         Set to 'false' to perform destructive operations (default: true)
    TF_VAR_db_password  Database master password

Examples:
    $0 --action plan
    $0 --action apply
    DRY_RUN=false $0 --action apply
    $0 --action verify
    DRY_RUN=false $0 --action failover-test
EOF
}

main() {
    while [ $# -gt 0 ]; do
        case $1 in
            --action)   ACTION="$2"; shift 2 ;;
            --dir)      TF_DIR="$2"; shift 2 ;;
            --tfvars)   TFVARS="$2"; shift 2 ;;
            --timeout)  TIMEOUT="$2"; shift 2 ;;
            -h|--help)  show_usage; exit 0 ;;
            *)          log_error "Unknown option: $1"; show_usage; exit 1 ;;
        esac
    done

    if [ -z "$ACTION" ]; then
        log_error "No action specified. Use --action <plan|apply|destroy|verify|failover-test>"
        show_usage
        exit 1
    fi

    log_info "=== RDS Deploy ==="
    log_info "Action   : $ACTION"
    log_info "TF Dir   : $TF_DIR"
    log_info "DRY_RUN  : $DRY_RUN"
    echo ""

    check_dependencies

    case $ACTION in
        plan)           action_plan ;;
        apply)          action_apply ;;
        destroy)        action_destroy ;;
        verify)         action_verify ;;
        failover-test)  action_failover_test ;;
        *)              log_error "Unknown action: $ACTION"; show_usage; exit 1 ;;
    esac

    echo ""
    log_info "=== Done ==="
}

main "$@"
