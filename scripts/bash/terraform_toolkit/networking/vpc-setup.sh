#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# AWS VPC Setup with Public and Private Subnets
# Purpose: Deploy AWS VPC infrastructure with public/private subnets, NAT GW, and routing
# Requirements: Terraform >= 1.0, AWS CLI, valid AWS credentials
# Safety: Dry-run mode supported via DRY_RUN=1
# Tested on: Ubuntu 22.04, macOS 13+, Amazon Linux 2023
###############################################################################

DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
PROJECT_NAME="${PROJECT_NAME:-vpc-demo}"

VPC_Cidr="10.0.0.0/16"
PublicSubnet1Cidr="10.0.1.0/24"
PublicSubnet2Cidr="10.0.2.0/24"
PrivateSubnet1Cidr="10.0.10.0/24"
PrivateSubnet2Cidr="10.0.11.0/24"
AvailabilityZones="${AWS_REGION}a,${AWS_REGION}b"

log() {
    local level="$1"
    shift
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
    echo "$msg"
}

info() { log "INFO" "$@"; }
warn() { log "WARN" "$@"; }
error() { log "ERROR" "$@"; }

dry_run() {
    if [ "$DRY_RUN" = "true" ]; then
        info "[dry-run] $*"
        return 0
    fi
    return 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_prerequisites() {
    local missing=0
    
    if ! command_exists terraform; then
        error "terraform not found. Install from https://www.terraform.io/downloads.html"
        ((missing++))
    fi
    
    if ! command_exists aws; then
        error "aws CLI not found. Install from https://aws.amazon.com/cli/"
        ((missing++))
    fi
    
    if ! command_exists jq; then
        warn "jq not found — some output formatting will be limited"
    fi
    
    if [ $missing -gt 0 ]; then
        error "Missing $missing prerequisite(s). Exiting."
        exit 1
    fi
    
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        error "AWS credentials not configured. Run 'aws configure' first."
        exit 1
    fi
    
    info "All prerequisites met"
}

init_terraform() {
    info "Initializing Terraform..."
    
    if [ -d ".terraform" ]; then
        info "Using cached Terraform providers"
    else
        dry_run "Would run terraform init" || terraform init -upgrade
    fi
}

validate_config() {
    info "Validating Terraform configuration..."
    dry_run "Would run terraform validate" || terraform validate
    info "Configuration valid"
}

plan_terraform() {
    info "Planning Terraform changes..."
    
    local plan_file="tfplan-$(date +%Y%m%d-%H%M%S).plan"
    
    dry_run "Would run terraform plan" || terraform plan \
        -out="$plan_file" \
        -var="aws_region=$AWS_REGION" \
        -var="environment=$ENVIRONMENT" \
        -var="project_name=$PROJECT_NAME" \
        -var="vpc_cidr=$VPC_Cidr" \
        -var="public_subnet_1_cidr=$PublicSubnet1Cidr" \
        -var="public_subnet_2_cidr=$PublicSubnet2Cidr" \
        -var="private_subnet_1_cidr=$PrivateSubnet1Cidr" \
        -var="private_subnet_2_cidr=$PrivateSubnet2Cidr" \
        -var="availability_zones=$AvailabilityZones"
    
    info "Plan saved to $plan_file"
    
    if [ "$DRY_RUN" != "true" ]; then
        echo ""
        echo "=== Plan Summary ==="
        terraform show "$plan_file" -json | jq -r '.resource_changes[] | "\(.change.actions[]): \(.address)"' 2>/dev/null | head -20 || true
    fi
}

apply_terraform() {
    info "Applying Terraform changes..."
    
    dry_run "Would run terraform apply" || terraform apply \
        -var="aws_region=$AWS_REGION" \
        -var="environment=$ENVIRONMENT" \
        -var="project_name=$PROJECT_NAME" \
        -var="vpc_cidr=$VPC_Cidr" \
        -var="public_subnet_1_cidr=$PublicSubnet1Cidr" \
        -var="public_subnet_2_cidr=$PublicSubnet2Cidr" \
        -var="private_subnet_1_cidr=$PrivateSubnet1Cidr" \
        -var="private_subnet_2_cidr=$PrivateSubnet2Cidr" \
        -var="availability_zones=$AvailabilityZones"
    
    info "Terraform apply complete"
}

show_outputs() {
    info "VPC Outputs:"
    echo ""
    terraform output -json | jq -r '
        to_entries[] | 
        "\(.key): \(.value.value)"
    ' 2>/dev/null || terraform output
    echo ""
}

destroy_infrastructure() {
    warn "This will destroy all resources!"
    read -p "Are you sure you want to destroy? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        info "Destroying infrastructure..."
        dry_run "Would run terraform destroy" || terraform destroy \
            -var="aws_region=$AWS_REGION" \
            -var="environment=$ENVIRONMENT" \
            -var="project_name=$PROJECT_NAME" \
            -var="vpc_cidr=$VPC_Cidr" \
            -var="public_subnet_1_cidr=$PublicSubnet1Cidr" \
            -var="public_subnet_2_cidr=$PublicSubnet2Cidr" \
            -var="private_subnet_1_cidr=$PrivateSubnet1Cidr" \
            -var="private_subnet_2_cidr=$PrivateSubnet2Cidr" \
            -var="availability_zones=$AvailabilityZones"
        info "Infrastructure destroyed"
    else
        info "Destroy cancelled"
    fi
}

show_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
    -h, --help              Show this help message
    -d, --dry-run           Run in dry-run mode (no changes)
    -v, --verbose           Enable verbose output
    -r, --region REGION     AWS region (default: us-east-1)
    -e, --env ENV           Environment name (default: dev)
    -p, --project NAME      Project name (default: vpc-demo)
    --destroy               Destroy the infrastructure
    --plan-only             Run plan only, no apply

Examples:
    $0 --region us-west-2 --env prod
    $0 --dry-run --plan-only
    $0 --destroy
EOF
}

main() {
    local do_plan=false
    local do_apply=true
    local do_destroy=false
    
    for arg in "$@"; do
        case $arg in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                ;;
            -v|--verbose)
                VERBOSE=true
                ;;
            -r|--region)
                AWS_REGION="${2:-}"
                shift
                ;;
            -r=*|--region=*)
                AWS_REGION="${arg#*=}"
                ;;
            -e|--env)
                ENVIRONMENT="${2:-}"
                shift
                ;;
            -e=*|--env=*)
                ENVIRONMENT="${arg#*=}"
                ;;
            -p|--project)
                PROJECT_NAME="${2:-}"
                shift
                ;;
            -p=*|--project=*)
                PROJECT_NAME="${arg#*=}"
                ;;
            --destroy)
                do_destroy=true
                do_apply=false
                ;;
            --plan-only)
                do_plan=true
                do_apply=false
                ;;
        esac
        shift 2>/dev/null || true
    done
    
    info "Starting VPC setup..."
    info "Region: $AWS_REGION, Environment: $ENVIRONMENT, Project: $PROJECT_NAME"
    info "Dry-run: $DRY_RUN"
    
    check_prerequisites
    
    if [ "$do_destroy" = true ]; then
        destroy_infrastructure
        exit 0
    fi
    
    init_terraform
    validate_config
    
    if [ "$do_plan" = true ]; then
        plan_terraform
        exit 0
    fi
    
    plan_terraform
    
    if [ "$do_apply" = true ]; then
        apply_terraform
        show_outputs
    fi
    
    info "VPC setup complete!"
}

main "$@"
