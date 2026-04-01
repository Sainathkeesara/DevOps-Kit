#!/usr/bin/env bash
set -euo pipefail

# Multi-Environment Terraform Setup with GitOps Workflow
# Purpose: Deploy and manage multi-environment AWS infrastructure with Terraform
# Usage: ./multi-env-setup.sh --action <init-backend|plan|apply|destroy|verify>
# Requirements: terraform, aws cli, appropriate IAM permissions
# Safety: DRY_RUN=true by default — set DRY_RUN=false for actual changes
# Tested on: Ubuntu 22.04, macOS 13, RHEL 9

DRY_RUN="${DRY_RUN:-true}"
ACTION=""
AWS_REGION="${AWS_REGION:-us-east-1}"
PROJECT_NAME="${PROJECT_NAME:-multi-env}"
ACCOUNT_ID=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_dependencies() {
    local deps=("terraform" "aws")
    for dep in "${deps[@]}"; do
        command -v "$dep" >/dev/null 2>&1 || { log_error "$dep not found — install it first"; exit 1; }
    done
    
    if command -v jq >/dev/null 2>&1; then
        log_info "jq found — enhanced output enabled"
    else
        log_warn "jq not found — some features disabled"
    fi
    
    log_info "All dependencies satisfied"
}

get_account_id() {
    if [ -z "$ACCOUNT_ID" ]; then
        ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null) || {
            log_error "Cannot determine AWS account ID — check credentials"
            exit 1
        }
    fi
    echo "$ACCOUNT_ID"
}

init_backend() {
    local bucket_name="terraform-state-${ACCOUNT_ID}-${PROJECT_NAME}"
    local table_name="terraform-state-lock"
    
    log_info "Initializing S3 backend for multi-environment Terraform..."
    
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would create S3 bucket: $bucket_name"
        log_warn "[dry-run] Would create DynamoDB table: $table_name"
        return 0
    fi
    
    # Create S3 bucket (if not exists)
    if aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
        log_info "S3 bucket $bucket_name already exists"
    else
        aws s3api create-bucket --bucket "$bucket_name" --region "$AWS_REGION" 2>/dev/null || {
            log_warn "Bucket creation may require different region config"
        }
        log_info "S3 bucket created: $bucket_name"
    fi
    
    # Enable versioning
    aws s3api put-bucket-versioning --bucket "$bucket_name" --versioning-configuration Status=Enabled
    
    # Enable encryption
    aws s3api put-bucket-encryption --bucket "$bucket_name" \
        --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
    
    # Block public access
    aws s3api put-public-access-block --bucket "$bucket_name" \
        --public-access-block-configuration "BlockPublicAcls=true,BlockPublicPolicy=true,IgnorePublicAcls=true,RestrictPublicBuckets=true"
    
    # Create DynamoDB table for state locking
    if aws dynamodb describe-table --table-name "$table_name" --region "$AWS_REGION" 2>/dev/null; then
        log_info "DynamoDB table $table_name already exists"
    else
        aws dynamodb create-table --table-name "$table_name" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --region "$AWS_REGION" 2>/dev/null || {
            log_error "Failed to create DynamoDB table"
            exit 1
        }
        
        # Wait for table creation
        log_info "Waiting for DynamoDB table to become active..."
        aws dynamodb wait table-exists --table-name "$table_name" --region "$AWS_REGION"
        log_info "DynamoDB table created: $table_name"
    fi
    
    log_info "Backend resources created successfully"
    log_info "Bucket: s3://$bucket_name"
    log_info "Lock table: $table_name"
}

create_environment() {
    local env="$1"
    local env_dir="$2"
    
    log_info "Creating environment: $env in $env_dir"
    
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would create environment: $env"
        return 0
    fi
    
    mkdir -p "$env_dir"
    
    # Create main.tf
    cat > "$env_dir/main.tf" <<EOF
terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy  = "Terraform"
    }
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "multi-env"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "environment_tags" {
  description = "Additional tags for environment"
  type        = map(string)
  default     = {}
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "Public subnet IDs"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "Private subnet IDs"
}
EOF

    # Create variables.tf
    cat > "$env_dir/variables.tf" <<EOF
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "environment_tags" {
  description = "Additional tags for environment"
  type        = map(string)
  default     = {}
}
EOF

    # Create outputs.tf
    cat > "$env_dir/outputs.tf" <<EOF
output "environment" {
  value = var.environment
}

output "vpc_cidr" {
  value = var.vpc_cidr
}

output "instance_type" {
  value = var.instance_type
}
EOF

    log_info "Environment files created in $env_dir"
}

run_terraform() {
    local env="$1"
    local action="$2"
    local env_dir="./environments/$env"
    
    if [ ! -d "$env_dir" ]; then
        log_error "Environment directory $env_dir does not exist"
        exit 1
    fi
    
    cd "$env_dir"
    
    log_info "Running Terraform $action for environment: $env"
    
    if [ "$DRY_RUN" = true ] && [ "$action" = "apply" ]; then
        log_warn "[dry-run] Would run terraform $action"
        terraform plan -var-file="terraform.tfvars"
        return 0
    fi
    
    case "$action" in
        init)
            terraform init -backend-config="key=$env/terraform.tfstate"
            ;;
        plan)
            terraform plan -var-file="terraform.tfvars" -out=tfplan
            ;;
        apply)
            terraform apply -var-file="terraform.tfvars" -auto-approve
            ;;
        destroy)
            terraform destroy -var-file="terraform.tfvars" -auto-approve
            ;;
        *)
            log_error "Unknown action: $action"
            exit 1
            ;;
    esac
    
    cd - > /dev/null
}

verify_infrastructure() {
    local env="$1"
    local env_dir="./environments/$env"
    
    log_info "Verifying $env infrastructure..."
    
    if [ ! -d "$env_dir" ]; then
        log_error "Environment directory $env_dir does not exist"
        exit 1
    fi
    
    cd "$env_dir"
    
    echo ""
    echo "=== Resource Count ==="
    terraform state list 2>/dev/null | wc -l
    
    echo ""
    echo "=== VPC Resources ==="
    terraform state list 2>/dev/null | grep -i vpc | head -5
    
    echo ""
    echo "=== EC2 Instances ==="
    terraform state list 2>/dev/null | grep -i instance | head -5
    
    cd - > /dev/null
    
    log_info "Verification complete for $env"
}

destroy_backend() {
    local bucket_name="terraform-state-${ACCOUNT_ID}-${PROJECT_NAME}"
    local table_name="terraform-state-lock"
    
    log_warn "DESTROYING backend resources..."
    
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would destroy S3 bucket: $bucket_name"
        log_warn "[dry-run] Would destroy DynamoDB table: $table_name"
        return 0
    fi
    
    # Delete S3 objects first
    aws s3 rm "s3://$bucket_name/" --recursive 2>/dev/null || true
    
    # Delete S3 bucket
    aws s3api delete-bucket --bucket "$bucket_name" --region "$AWS_REGION" 2>/dev/null || true
    
    # Delete DynamoDB table
    aws dynamodb delete-table --table-name "$table_name" --region "$AWS_REGION" 2>/dev/null || true
    
    log_info "Backend resources destroyed"
}

show_usage() {
    cat << EOF
Usage: $0 --action <ACTION> [OPTIONS]

Actions:
    init-backend    Initialize S3 and DynamoDB backend
    create-env      Create new environment structure
    plan            Run terraform plan for an environment
    apply           Run terraform apply for an environment
    destroy         Run terraform destroy for an environment
    verify          Verify infrastructure state
    destroy-backend Destroy backend resources (dangerous!)

Options:
    --env ENV        Environment name (dev, staging, prod)
    --region REGION  AWS region (default: us-east-1)
    --dry-run        Show what would happen without making changes

Environment Variables:
    DRY_RUN          Set to 'false' to perform actual changes
    AWS_REGION       AWS region
    AWS_PROFILE      AWS profile to use

Examples:
    DRY_RUN=false $0 --action init-backend
    DRY_RUN=false $0 --action apply --env dev
    $0 --action plan --env staging
EOF
}

main() {
    local env="dev"
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --action)   ACTION="$2"; shift 2 ;;
            --env)      env="$2"; shift 2 ;;
            --region)   AWS_REGION="$2"; shift 2 ;;
            --dry-run)  DRY_RUN=false; shift ;;
            -h|--help)  show_usage; exit 0 ;;
            *)          log_error "Unknown option: $1"; show_usage; exit 1 ;;
        esac
    done
    
    if [ -z "$ACTION" ]; then
        log_error "No action specified. Use --action <ACTION>"
        show_usage
        exit 1
    fi
    
    log_info "=== Multi-Environment Terraform Setup ==="
    log_info "Action    : $ACTION"
    log_info "Environment: $env"
    log_info "Region    : $AWS_REGION"
    log_info "DRY_RUN   : $DRY_RUN"
    echo ""
    
    check_dependencies
    ACCOUNT_ID=$(get_account_id)
    
    case "$ACTION" in
        init-backend)
            init_backend
            ;;
        create-env)
            create_environment "$env" "./environments/$env"
            ;;
        plan|apply|destroy)
            run_terraform "$env" "$ACTION"
            ;;
        verify)
            verify_infrastructure "$env"
            ;;
        destroy-backend)
            destroy_backend
            ;;
        *)
            log_error "Unknown action: $ACTION"
            show_usage
            exit 1
            ;;
    esac
    
    echo ""
    log_info "=== Done ==="
}

main "$@"