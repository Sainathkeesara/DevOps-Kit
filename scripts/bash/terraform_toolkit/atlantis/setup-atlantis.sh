#!/usr/bin/env bash
set -euo pipefail

ATLANTIS_VERSION="v0.25.2"
ATLANTIS_PORT=4141
ATLANTIS_DATA_DIR="/tmp/atlantis-data"
TERRAFORM_VERSION="1.6.0"
DRY_RUN=${DRY_RUN:-false}

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
warn() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $*"; }
error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }

check_binary() {
    command -v "$1" >/dev/null 2>&1 || { error "$1 not found"; exit 1; }
}

check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker is required but not installed"
        exit 1
    fi
    if ! docker info >/dev/null 2>&1; then
        error "Docker daemon is not running"
        exit 1
    fi
}

install_terraform() {
    if command -v terraform >/dev/null 2>&1; then
        log "Terraform already installed: $(terraform version --json | grep -oP '(?<="terraform_version": ")[^"]+')"
        return
    fi
    
    log "Installing Terraform ${TERRAFORM_VERSION}..."
    if [ "$DRY_RUN" = true ]; then
        log "[dry-run] Would download and install Terraform ${TERRAFORM_VERSION}"
        return
    fi
    
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64) ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
    esac
    
    wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${OS}_${ARCH}.zip" -O /tmp/terraform.zip
    unzip -o /tmp/terraform.zip -d /usr/local/bin/
    rm -f /tmp/terraform.zip
    chmod +x /usr/local/bin/terraform
    log "Terraform installed: $(terraform version -short)"
}

setup_atlantis_directories() {
    log "Setting up Atlantis directories..."
    if [ "$DRY_RUN" = true ]; then
        log "[dry-run] Would create directories: ${ATLANTIS_DATA_DIR}, /tmp/repos"
        return
    fi
    
    mkdir -p "${ATLANTIS_DATA_DIR}"
    mkdir -p /tmp/repos
    mkdir -p /tmp/atlantis-config
    
    log "Directories created successfully"
}

generate_atlantis_config() {
    local config_file="/tmp/atlantis-config/atlantis.yaml"
    log "Generating Atlantis configuration..."
    
    if [ "$DRY_RUN" = true ]; then
        log "[dry-run] Would generate ${config_file}"
        return
    fi
    
    cat > "$config_file" <<'EOF'
version: 1
projects:
- name: dev-environment
  dir: .
  workflow: dev-workflow
  terraform_version: 1.6.0
  autoplan:
    when_modified:
      - "*.tf"
      - "*.tfvars"
      - "*.tfvars.json"
      - ".terraform.lock.hcl"
    enabled: true
  apply_requirements: [approved]

- name: staging-environment
  dir: environments/staging
  workflow: staging-workflow
  terraform_version: 1.6.0

- name: prod-environment
  dir: environments/prod
  workflow: prod-workflow
  terraform_version: 1.6.0

workflows:
  dev-workflow:
    plan:
      steps:
        - init
        - plan
    apply:
      steps:
        - apply
  staging-workflow:
    plan:
      steps:
        - init
        - plan -var-file=staging.tfvars
    apply:
      steps:
        - apply -var-file=staging.tfvars
  prod-workflow:
    plan:
      steps:
        - init
        - plan -var-file=prod.tfvars
    apply:
      steps:
        - apply -var-file=prod.tfvars
EOF
    log "Atlantis configuration generated at ${config_file}"
}

generate_webhook_config() {
    local config_file="/tmp/atlantis-config/webhook-config.yaml"
    log "Generating webhook configuration..."
    
    if [ "$DRY_RUN" = true ]; then
        log "[dry-run] Would generate webhook configuration"
        return
    fi
    
    cat > "$config_file" <<'EOF'
# GitHub Webhook Configuration
# Add this URL to your repository's webhook settings:
# http://<atlantis-server>:4141/events
#
# Required webhook events:
# - Push
# - Pull Request
EOF
    log "Webhook configuration generated"
}

run_atlantis_docker() {
    log "Starting Atlantis in Docker..."
    
    if [ "$DRY_RUN" = true ]; then
        log "[dry-run] Would run Atlantis container with:"
        log "  Image: ghcr.io/runatlantis/atlantis:${ATLANTIS_VERSION}"
        log "  Port: ${ATLANTIS_PORT}"
        log "  Data Dir: ${ATLANTIS_DATA_DIR}"
        log "  GitHub Token: \${GITHUB_TOKEN:0:4}..."
        return
    fi
    
    docker run -d \
        --name atlantis \
        -p "${ATLANTIS_PORT}:4141" \
        -v "${ATLANTIS_DATA_DIR}:/atlantis/data" \
        -v "/tmp/repos:/tmp/repos" \
        -v "/tmp/atlantis-config:/etc/atlantis" \
        -e "ATLANTIS_GH_USER=${ATLANTIS_GH_USER:-atlantis}" \
        -e "ATLANTIS_GH_TOKEN=${GITHUB_TOKEN:-}" \
        -e "ATLANTIS_GH_WEBHOOK_SECRET=${ATLANTIS_WEBHOOK_SECRET:-atlantis-secret}" \
        -e "ATLANTIS_REPO_CONFIG=/etc/atlantis/atlantis.yaml" \
        -e "ATLANTIS_ALLOW_WORKFLOWS=true" \
        ghcr.io/runatlantis/atlantis:${ATLANTIS_VERSION} \
        server
    
    log "Atlantis container started"
    log "Access Atlantis UI at http://localhost:${ATLANTIS_PORT}"
}

verify_installation() {
    log "Verifying Atlantis installation..."
    
    if [ "$DRY_RUN" = true ];
then
        log "[dry-run] Would verify Atlantis is running"
        return
    fi
    
    sleep 5
    
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:${ATLANTIS_PORT}/healthz" | grep -q "200"; then
        log "Atlantis is healthy and running"
    else
        warn "Atlantis health check failed - check logs with: docker logs atlantis"
    fi
}

print_usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Setup Atlantis for Terraform CI/CD with GitOps workflow.

OPTIONS:
    --dry-run           Show what would be done without executing
    --version           Show Atlantis version
    -h, --help          Show this help message

ENVIRONMENT VARIABLES:
    DRY_RUN             Set to 'true' for dry-run mode
    GITHUB_TOKEN        GitHub personal access token (required for GitHub integration)
    ATLANTIS_GH_USER    Atlantis GitHub username (default: atlantis)
    ATLANTIS_WEBHOOK_SECRET    Webhook secret for GitHub

EXAMPLES:
    # Dry-run to see what would be created
    DRY_RUN=true $0

    # Full setup with GitHub integration
    GITHUB_TOKEN=ghp_xxx $0

    # Custom port
    ATLANTIS_PORT=8080 $0
EOF
}

main() {
    log "Atlantis Setup Script"
    log "====================="
    log "Version: ${ATLANTIS_VERSION}"
    log "Dry Run: ${DRY_RUN}"
    
    check_docker
    install_terraform
    setup_atlantis_directories
    generate_atlantis_config
    generate_webhook_config
    run_atlantis_docker
    verify_installation
    
    log "Setup complete!"
    log ""
    log "Next steps:"
    log "1. Configure GitHub webhook: http://localhost:${ATLANTIS_PORT}/events"
    log "2. Add repository to Atlantis configuration"
    log "3. Create pull request to trigger plan"
    log "4. Comment 'atlantis apply' to apply changes"
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    print_usage
    exit 0
fi

main "$@"
