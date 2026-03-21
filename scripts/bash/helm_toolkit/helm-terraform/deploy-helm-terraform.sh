#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
NAMESPACE="${NAMESPACE:-applications}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
TERRAFORM_DIR="${TERRAFORM_DIR:-./terraform}"
HELM_DIR="${HELM_DIR:-./helm}"
HELM_RELEASE="webapp"

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [COMMAND] [OPTIONS]

Helm + Terraform Full-Stack Deployment Script

Commands:
    plan           Run Terraform plan
    apply          Apply Terraform configuration
    destroy        Destroy Terraform resources
    deploy         Deploy Helm chart to cluster
    rollback       Rollback Helm release
    status         Show deployment status
    validate       Validate all configurations
    clean          Clean up local files

Options:
    -n, --namespace     Kubernetes namespace (default: applications)
    -e, --environment   Environment: dev, staging, prod (default: dev)
    -r, --region        AWS region (default: us-east-1)
    -h, --help         Show this help message

Examples:
    $SCRIPT_NAME plan -e prod
    $SCRIPT_NAME apply -e staging -r us-west-2
    $SCRIPT_NAME deploy -n myapp -e prod
    $SCRIPT_NAME rollback -n myapp

EOF
    exit 1
}

log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

check_prerequisites() {
    local missing_tools=()
    
    for tool in terraform kubectl helm aws; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    
    log_info "All prerequisites satisfied"
}

validate_environment() {
    log_info "Validating environment configuration..."
    
    if [[ ! -d "$TERRAFORM_DIR" ]]; then
        log_error "Terraform directory not found: $TERRAFORM_DIR"
        exit 1
    fi
    
    if [[ ! -d "$HELM_DIR" ]]; then
        log_error "Helm chart directory not found: $HELM_DIR"
        exit 1
    fi
    
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        log_error "AWS credentials not configured"
        exit 1
    fi
    
    log_info "Environment validation passed"
}

run_terraform() {
    local action="$1"
    log_info "Running Terraform $action for environment: $ENVIRONMENT"
    
    cd "$TERRAFORM_DIR"
    
    if [[ "$action" == "init" ]]; then
        terraform init -upgrade
    elif [[ "$action" == "plan" ]]; then
        terraform plan \
            -var="environment=$ENVIRONMENT" \
            -var="region=$AWS_REGION" \
            -out=tfplan
    elif [[ "$action" == "apply" ]]; then
        terraform apply -auto-approve
    elif [[ "$action" == "destroy" ]]; then
        terraform destroy -auto-approve
    fi
    
    cd - >/dev/null
}

deploy_helm() {
    log_info "Deploying Helm chart to namespace: $NAMESPACE"
    
    if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        log_info "Creating namespace: $NAMESPACE"
        kubectl create namespace "$NAMESPACE"
    fi
    
    local values_file="$HELM_DIR/values-${ENVIRONMENT}.yaml"
    local extra_args=()
    
    if [[ -f "$values_file" ]]; then
        extra_args+=(--values "$values_file")
        log_info "Using values file: $values_file"
    fi
    
    helm upgrade --install "$HELM_RELEASE" "$HELM_DIR" \
        --namespace "$NAMESPACE" \
        --create-namespace \
        "${extra_args[@]}" \
        --wait \
        --timeout 5m \
        --debug
        
    log_info "Helm deployment complete"
}

rollback_helm() {
    log_info "Rolling back Helm release: $HELM_RELEASE"
    
    local revision="${1:-1}"
    helm rollback "$HELM_RELEASE" "$revision" --namespace "$NAMESPACE"
    
    log_info "Rollback complete"
}

show_status() {
    log_info "Deployment Status"
    echo "========================"
    
    echo -e "\n--- Helm Releases ---"
    helm list -n "$NAMESPACE" -a
    
    echo -e "\n--- Kubernetes Deployments ---"
    kubectl get deployments -n "$NAMESPACE"
    
    echo -e "\n--- Kubernetes Pods ---"
    kubectl get pods -n "$NAMESPACE"
    
    echo -e "\n--- Kubernetes Services ---"
    kubectl get svc -n "$NAMESPACE"
    
    echo -e "\n--- Helm Release History ---"
    helm history "$HELM_RELEASE" -n "$NAMESPACE"
}

clean_local() {
    log_info "Cleaning up local files..."
    
    find "$TERRAFORM_DIR" -name "*.tfplan" -delete 2>/dev/null || true
    find "$TERRAFORM_DIR" -name ".terraform*" -type d -exec rm -rf {} + 2>/dev/null || true
    rm -f "$TERRAFORM_DIR"/.terraform.lock.hcl 2>/dev/null || true
    
    log_info "Cleanup complete"
}

main() {
    if [[ $# -eq 0 ]]; then
        usage
    fi
    
    check_prerequisites
    
    local command=""
    local aws_region="${AWS_REGION:-us-east-1}"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                ;;
            -n|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -r|--region)
                aws_region="$2"
                shift 2
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                ;;
            *)
                command="$1"
                shift
                ;;
        esac
    done
    
    if [[ -z "$command" ]]; then
        log_error "No command specified"
        usage
    fi
    
    export AWS_REGION="$aws_region"
    
    validate_environment
    
    case "$command" in
        plan)
            run_terraform plan
            ;;
        apply)
            run_terraform apply
            ;;
        destroy)
            run_terraform destroy
            ;;
        deploy)
            deploy_helm
            ;;
        rollback)
            rollback_helm "${1:-}"
            ;;
        status)
            show_status
            ;;
        validate)
            log_info "Running validation..."
            validate_environment
            log_info "Validation complete"
            ;;
        clean)
            clean_local
            ;;
        *)
            log_error "Unknown command: $command"
            usage
            ;;
    esac
}

main "$@"
