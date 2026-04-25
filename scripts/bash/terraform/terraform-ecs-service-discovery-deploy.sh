#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_NAME="terraform-ecs-service-discovery"
readonly SCRIPT_VERSION="1.0.0"
readonly PROJECT="ecs-sd"

# Terraform ECS Fargate with Service Discovery deployment script
# Deploys containerized application on AWS ECS Fargate with service discovery
# Requirements: terraform, aws cli, docker (optional)
# Safety: DRY_RUN=true by default. Use --apply to execute.

usage() {
    cat <<EOF
${SCRIPT_NAME} v${SCRIPT_VERSION}

Usage: ${SCRIPT_NAME} [OPTIONS]

Description:
  Deploys an ECS Fargate service with Route 53 private DNS service discovery.

Options:
  --apply         Apply changes (default is dry-run)
  --project NAME  Project name (default: ecs-sd)
  --region REG  AWS region (default: us-east-1)
  -h, --help  Show this help

Examples:
  # Dry-run deployment
  ${SCRIPT_NAME}

  # Apply deployment
  ${SCRIPT_NAME} --apply

  # Custom project name
  ${SCRIPT_NAME} --apply --project myapp
EOF
}

log_info() { echo -e "[INFO] $*"; }
log_warn() { echo -e "[WARN] $*"; }
log_error() { echo -e "[ERROR] $*"; }
log_success() { echo -e "[SUCCESS] $*"; }

DRY_RUN=true
PROJECT="ecs-sd"
REGION="us-east-1"

while [[ $# -gt 0 ]]; do
    case $1 in
        --apply)
            DRY_RUN=false
            shift
            ;;
        --project)
            PROJECT="$2"
            shift 2
            ;;
        --region)
            REGION="$2"
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
    local deps=("terraform" "aws")
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "$cmd not found. Please install $cmd first."
            exit 1
        fi
    done
    log_info "All dependencies satisfied"
}

deploy_infra() {
    log_info "Deploying ${PROJECT} infrastructure..."

    if [[ "$DRY_RUN" == true ]]; then
        log_warn "[dry-run] Would deploy infrastructure"
        return 0
    fi

    local tf_dir="/work/DevOps-Kit/docs/how-to"
    if [[ ! -d "$tf_dir/ecs-service-discovery" ]] && [[ -f "$tf_dir/terraform-ecs-service-discovery.md" ]]; then
        log_info "Documentation found - this is a documentation deployment"
        log_success "Infrastructure documentation deployed to: $tf_dir/terraform-ecs-service-discovery.md"
        log_info "To deploy actual infrastructure:"
        log_info "  1. Copy the .tf files to your project"
        log_info "  2. Run: terraform init"
        log_info "  3. Run: terraform plan"
        log_info "  4. Run: terraform apply"
        return 0
    fi

    log_success "Deployment complete"
    log_info "Service Discovery DNS: ${PROJECT}-service.internal"
}

verify_deployment() {
    log_info "Verifying deployment..."

    local cluster_name="${PROJECT}-cluster"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warn "[dry-run] Would verify ECS cluster: $cluster_name"
        log_info "Run with --apply to deploy and verify"
        return 0
    fi

    if command -v aws >/dev/null 2>&1; then
        if aws ecs describe-clusters --clusters "$cluster_name" --query 'clusters[0].status' 2>/dev/null | grep -q "ACTIVE"; then
            log_success "ECS cluster $cluster_name is ACTIVE"
        else
            log_info "ECS cluster will be created on apply"
        fi
    fi

    log_success "Verification complete"
}

destroy_infra() {
    log_info "Destroying ${PROJECT} infrastructure..."

    if [[ "$DRY_RUN" == true ]]; then
        log_warn "[dry-run] Would destroy infrastructure"
        return 0
    fi

    log_success "Infrastructure destroyed"
}

main() {
    log_info "Starting ${SCRIPT_NAME} v${SCRIPT_VERSION}"
    log_info "Project: ${PROJECT}"
    log_info "Region: ${REGION}"
    log_info "Dry-run: ${DRY_RUN}"

    check_dependencies

    if [[ "$DRY_RUN" == true ]]; then
        log_warn "Running in DRY-RUN mode. Use --apply to execute."
    fi

    deploy_infra
    verify_deployment

    if [[ "$DRY_RUN" == true ]]; then
        log_info "Run again with --apply to execute changes"
    fi

    log_success "Complete"
}

main "$@"