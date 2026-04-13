#!/usr/bin/env bash
set -euo pipefail

# terraform-lambda-deploy.sh — Deploy Lambda function with API Gateway via Terraform
# Purpose: Automate deployment of serverless API using Lambda and API Gateway
# Usage: ./terraform-lambda-deploy.sh [init|plan|apply|destroy|status|test]
# Requirements: Terraform >= 1.0, AWS CLI, appropriate IAM permissions
# Safety: Dry-run mode supported for plan and apply operations
# Tested OS: Ubuntu 22.04, macOS 13, Amazon Linux 2023

DRY_RUN=${DRY_RUN:-false}
TERRAFORM_DIR="${TERRAFORM_DIR:-.}"
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENVIRONMENT:-dev}"

log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*"; }
log_warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $*" >&2; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }

command -v terraform >/dev/null 2>&1 || { log_error "terraform not found. Install from https://www.terraform.io/downloads.html"; exit 1; }
command -v aws >/dev/null 2>&1 || { log_error "aws CLI not found. Install from https://aws.amazon.com/cli/"; exit 1; }

show_usage() {
  cat <<EOF
Usage: $0 [command] [options]

Commands:
  init        Initialize Terraform backend
  plan        Show deployment plan
  apply       Deploy resources to AWS
  destroy     Remove all resources
  status      Show current deployment status
  test        Test the deployed API endpoint

Options:
  --dry-run   Show what would be done without executing
  --region    AWS region (default: us-east-1)
  --env       Environment name (default: dev)
  -h, --help  Show this help message

Examples:
  $0 init                # Initialize Terraform
  $0 plan --dry-run      # Preview changes
  $0 apply               # Deploy to AWS
  $0 apply --dry-run      # Dry-run deploy
  $0 destroy             # Remove all resources
  $0 test                # Test the API endpoint

EOF
}

parse_args() {
  if [[ $# -eq 0 ]]; then
    show_usage
    exit 0
  fi

  case "$1" in
    init|plan|apply|destroy|status|test)
      COMMAND="$1"
      shift
      ;;
    -h|--help)
      show_usage
      exit 0
      ;;
    --dry-run)
      DRY_RUN=true
      COMMAND="${2:-plan}"
      shift 2
      ;;
    --region)
      AWS_REGION="$2"
      shift 2
      ;;
    --env)
      ENVIRONMENT="$2"
      shift 2
      ;;
    *)
      log_error "Unknown command: $1"
      show_usage
      exit 1
      ;;
  esac
}

check_aws_credentials() {
  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    log_error "AWS credentials not configured. Run 'aws configure' or set AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY"
    exit 1
  fi
  log_info "AWS credentials validated"
}

terraform_init() {
  log_info "Initializing Terraform in $TERRAFORM_DIR"
  
  if [[ "$DRY_RUN" == true ]]; then
    log_info "[dry-run] Would run: terraform init"
    return 0
  fi
  
  cd "$TERRAFORM_DIR"
  terraform init
  log_info "Terraform initialized successfully"
}

terraform_plan() {
  log_info "Planning Terraform deployment for environment: $ENVIRONMENT"
  
  if [[ "$DRY_RUN" == true ]]; then
    log_info "[dry-run] Would run: terraform plan -var=environment=$ENVIRONMENT -var=aws_region=$AWS_REGION"
    return 0
  fi
  
  cd "$TERRAFORM_DIR"
  terraform plan -var="environment=$ENVIRONMENT" -var="aws_region=$AWS_REGION" -out=tfplan
  log_info "Plan saved to tfplan"
}

terraform_apply() {
  log_info "Applying Terraform configuration"
  
  if [[ "$DRY_RUN" == true ]]; then
    log_info "[dry-run] Would run: terraform apply tfplan"
    return 0
  fi
  
  cd "$TERRAFORM_DIR"
  
  if [[ -f tfplan ]]; then
    terraform apply tfplan
  else
    terraform apply -var="environment=$ENVIRONMENT" -var="aws_region=$AWS_REGION" -auto-approve
  fi
  
  log_info "Deployment completed"
}

terraform_destroy() {
  log_info "Destroying all resources in environment: $ENVIRONMENT"
  
  if [[ "$DRY_RUN" == true ]]; then
    log_info "[dry-run] Would run: terraform destroy -var=environment=$ENVIRONMENT"
    return 0
  fi
  
  read -p "Are you sure you want to destroy all resources? (yes/no): " confirm
  if [[ "$confirm" != "yes" ]]; then
    log_info "Destroy cancelled"
    return 0
  fi
  
  cd "$TERRAFORM_DIR"
  terraform destroy -var="environment=$ENVIRONMENT" -var="aws_region=$AWS_REGION" -auto-approve
  log_info "Resources destroyed"
}

show_status() {
  log_info "Checking deployment status"
  
  cd "$TERRAFORM_DIR"
  
  echo "=== Terraform State ==="
  terraform show
  
  echo ""
  echo "=== Lambda Functions ==="
  aws lambda list-functions --region "$AWS_REGION" --output table 2>/dev/null || echo "No Lambda functions found"
  
  echo ""
  echo "=== API Gateways ==="
  aws apigateway get-rest-apis --region "$AWS_REGION" --output table 2>/dev/null || echo "No API Gateways found"
  
  echo ""
  echo "=== Recent Deployments ==="
  terraform output -json 2>/dev/null | jq -r '.api_gateway_endpoint.value' 2>/dev/null && echo "" || echo "No outputs available"
}

test_api() {
  log_info "Testing API endpoint"
  
  cd "$TERRAFORM_DIR"
  
  local endpoint
  endpoint=$(terraform output -raw api_gateway_endpoint 2>/dev/null)
  
  if [[ -z "$endpoint" ]]; then
    log_error "No API endpoint found. Run 'apply' first."
    exit 1
  fi
  
  log_info "Testing endpoint: $endpoint"
  
  local response
  response=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$endpoint" 2>/dev/null) || {
    log_error "Failed to connect to endpoint"
    exit 1
  }
  
  local http_code
  http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
  local body
  body=$(echo "$response" | sed '/HTTP_CODE:/d')
  
  echo "Response Code: $http_code"
  echo "Response Body: $body"
  
  if [[ "$http_code" == "200" ]]; then
    log_info "API test passed"
  else
    log_warn "API test returned non-200 status"
  fi
}

main() {
  parse_args "$@"
  check_aws_credentials
  
  case "$COMMAND" in
    init)
      terraform_init
      ;;
    plan)
      terraform_plan
      ;;
    apply)
      terraform_apply
      ;;
    destroy)
      terraform_destroy
      ;;
    status)
      show_status
      ;;
    test)
      test_api
      ;;
    *)
      log_error "Unknown command: $COMMAND"
      show_usage
      exit 1
      ;;
  esac
  
  log_info "Done"
}

main "$@"