#!/usr/bin/env bash
#
# PURPOSE: Generate and apply a production-ready Kubernetes deployment with HPA and PDB
# USAGE: ./deploy-prod-app.sh <app-name> <image> [namespace] [options]
# REQUIREMENTS: kubectl configured with cluster access
# SAFETY: Dry-run mode available. Does not auto-apply - user must confirm.
#
# OPTIONS:
#   --replicas=N       Initial replicas (default: 3)
#   --min-replicas=N   HPA min replicas (default: 2)
#   --max-replicas=N   HPA max replicas (default: 10)
#   --cpu-request=CPU  CPU request (default: 100m)
#   --cpu-limit=CPU    CPU limit (default: 500m)
#   --mem-request=MEM  Memory request (default: 128Mi)
#   --mem-limit=MEM    Memory limit (default: 512Mi)
#   --port=PORT        Container port (default: 8080)
#   --dry-run          Show generated YAML without applying
#   --apply            Apply after generation (default: false)
#   --namespace=NS     Override namespace (default: production)
#
# EXAMPLES:
#   ./deploy-prod-app.sh myapp nginx:latest
#   ./deploy-prod-app.sh api myregistry.io/api:v1.2.3 production --replicas=5 --apply
#   ./deploy-prod-app.sh worker docker.io/worker:v1 --dry-run

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/production-deployment.yaml"

APP_NAME=""
IMAGE=""
NAMESPACE="production"
REPLICAS=3
MIN_REPLICAS=2
MAX_REPLICAS=10
CPU_REQUEST="100m"
CPU_LIMIT="500m"
MEMORY_REQUEST="128Mi"
MEMORY_LIMIT="512Mi"
PORT=8080
MAX_UNAVAILABLE=1
MIN_AVAILABLE=1
DRY_RUN=0
APPLY=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

usage() {
    grep '^#' "$0" | cut -c4- | head -n 25 | tail -n +3
    exit 1
}

parse_args() {
    if [[ $# -lt 2 ]]; then
        log_error "Missing required arguments"
        usage
    fi

    APP_NAME="$1"
    IMAGE="$2"

    shift 2

    while [[ $# -gt 0 ]]; do
        case $1 in
            --namespace=*) NAMESPACE="${1#*=}" ;;
            --replicas=*) REPLICAS="${1#*=}" ;;
            --min-replicas=*) MIN_REPLICAS="${1#*=}" ;;
            --max-replicas=*) MAX_REPLICAS="${1#*=}" ;;
            --cpu-request=*) CPU_REQUEST="${1#*=}" ;;
            --cpu-limit=*) CPU_LIMIT="${1#*=}" ;;
            --mem-request=*) MEMORY_REQUEST="${1#*=}" ;;
            --mem-limit=*) MEMORY_LIMIT="${1#*=}" ;;
            --port=*) PORT="${1#*=}" ;;
            --dry-run) DRY_RUN=1 ;;
            --apply) APPLY=1 ;;
            -h|--help) usage ;;
            *) log_error "Unknown option: $1"; usage ;;
        esac
        shift
    done
}

validate() {
    if [[ ! "$APP_NAME" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]]; then
        log_error "Invalid app name. Use lowercase alphanumeric with hyphens (must start/end with alphanumeric)"
        exit 1
    fi

    if [[ -z "$IMAGE" ]]; then
        log_error "Image is required"
        exit 1
    fi

    if [[ $REPLICAS -lt 1 ]]; then
        log_error "Replicas must be at least 1"
        exit 1
    fi

    if [[ $MIN_REPLICAS -lt 1 ]]; then
        log_error "Min replicas must be at least 1"
        exit 1
    fi

    if [[ $MAX_REPLICAS -lt $MIN_REPLICAS ]]; then
        log_error "Max replicas must be >= min replicas"
        exit 1
    fi
}

generate_yaml() {
    sed -e "s|APP_NAME_PLACEHOLDER|$APP_NAME|g" \
        -e "s|APP_VERSION_PLACEHOLDER|latest|g" \
        -e "s|APP_NAMESPACE_PLACEHOLDER|$NAMESPACE|g" \
        -e "s|IMAGE_PLACEHOLDER|$IMAGE|g" \
        -e "s|REPLICAS_PLACEHOLDER|$REPLICAS|g" \
        -e "s|MIN_REPLICAS_PLACEHOLDER|$MIN_REPLICAS|g" \
        -e "s|MAX_REPLICAS_PLACEHOLDER|$MAX_REPLICAS|g" \
        -e "s|CPU_REQUEST_PLACEHOLDER|$CPU_REQUEST|g" \
        -e "s|CPU_LIMIT_PLACEHOLDER|$CPU_LIMIT|g" \
        -e "s|MEMORY_REQUEST_PLACEHOLDER|$MEMORY_REQUEST|g" \
        -e "s|MEMORY_LIMIT_PLACEHOLDER|$MEMORY_LIMIT|g" \
        -e "s|MAX_UNAVAILABLE_PLACEHOLDER|$MAX_UNAVAILABLE|g" \
        -e "s|MIN_AVAILABLE_PLACEHOLDER|$MIN_AVAILABLE|g" \
        "$TEMPLATE_FILE"
}

main() {
    parse_args "$@"
    validate

    log_info "Generating production deployment for: $APP_NAME"
    log_info "Image: $IMAGE"
    log_info "Namespace: $NAMESPACE"
    log_info "Replicas: $REPLICAS (HPA: $MIN_REPLICAS-$MAX_REPLICAS)"
    log_info "Resources: CPU $CPU_REQUEST/$CPU_LIMIT, Memory $MEMORY_REQUEST/$MEMORY_LIMIT"

    local yaml_content
    yaml_content=$(generate_yaml)

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "--- DRY RUN: Generated YAML ---"
        echo "$yaml_content"
        log_info "--- END DRY RUN ---"
        exit 0
    fi

    local output_file="${APP_NAME}-deployment.yaml"
    echo "$yaml_content" > "$output_file"
    log_info "Generated: $output_file"

    if [[ $APPLY -eq 1 ]]; then
        log_info "Applying to cluster..."
        kubectl apply -f "$output_file"
        log_info "Deployment applied. Use 'kubectl get hpa $APP_NAME -n $NAMESPACE' to monitor."
    else
        log_info "To apply: kubectl apply -f $output_file"
    fi
}

main "$@"
