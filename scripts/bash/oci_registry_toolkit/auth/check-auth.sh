#!/usr/bin/env bash
#
# PURPOSE: Check OCI registry authentication status and provide diagnostic info
# USAGE: ./check-auth.sh <registry> [--verbose] [--insecure]
# REQUIREMENTS: oras CLI (v1.3+) installed
# SAFETY: Read-only diagnostic. No changes made.
#
# OUTPUT: Authentication status and remediation suggestions
#
# EXAMPLES:
#   ./check-auth.sh docker.io
#   ./check-auth.sh ghcr.io --verbose
#   ./check-auth.sh myregistry.com:5000 --insecure
#
# REFERENCES:
# - ORAS authentication: https://oras.land/docs/authentication/
# - Docker credential helper: https://docs.docker.com/engine/reference/commandline/login/

set -euo pipefail
IFS=$'\n\t'

# Defaults
VERBOSE=0
INSECURE=0

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

usage() {
    grep '^#' "$0" | cut -c4- | head -n 25 | tail -n +3
    exit 1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose) VERBOSE=1 ;;
            --insecure) INSECURE=1 ;;
            -h|--help) usage ;;
            -*)
                log_error "Unknown option: $1"
                usage
                ;;
            *)
                if [[ -z "$REGISTRY" ]]; then
                    REGISTRY="$1"
                else
                    log_error "Multiple registry arguments provided"
                    usage
                fi
                ;;
        esac
        shift
    done
}

validate_oras() {
    if ! command -v oras &>/dev/null; then
        log_error "oras CLI not found. Install from: https://oras.land/docs/installation/"
        exit 1
    fi

    if [[ $VERBOSE -eq 1 ]]; then
        local version
        version=$(oras version --output=short 2>/dev/null || echo "unknown")
        log_info "oras version: $version"
    fi
}

check_config_files() {
    if [[ $VERBOSE -eq 1 ]]; then
        log_info "Checking credential storage locations..."
        if [[ -f "$HOME/.docker/config.json" ]]; then
            log_info "Found Docker config: $HOME/.docker/config.json"
            if [[ -f "$HOME/.oras/config.json" ]]; then
                log_info "Found ORAS config: $HOME/.oras/config.json"
            fi
        else
            log_warn "No Docker or ORAS config found. You may need to login."
        fi
    fi
}

test_registry_access() {
    local registry="$1"
    local insecure_flag=""
    if [[ $INSECURE -eq 1 ]]; then
        insecure_flag="--insecure"
    fi

    log_info "Testing access to: $registry"
    log_info "Command: oras repo ls $insecure_flag $registry"

    # Try listing repositories (may require auth)
    if output=$(oras repo ls $insecure_flag "$registry" 2>&1); then
        local repo_count
        repo_count=$(echo "$output" | wc -l)
        log_info "Registry accessible. Repositories found: $repo_count"
        if [[ $repo_count -gt 0 ]]; then
            log_info "Sample repositories:"
            echo "$output" | head -n 5 | sed 's/^/  /'
        fi
        return 0
    else
        log_error "Failed to access registry"
        return 1
    fi
}

analyze_error() {
    local exit_code=$?
    local error_output="$1"
    local registry="$2"

    log_warn "Diagnosing failure (exit code: ${exit_code})..."

    if echo "$error_output" | grep -qi "unauthorized\|401\|403"; then
        log_error "Authentication required or credentials invalid."
        echo ""
        echo "Remediation:"
        echo "1. Login to the registry: oras login $registry"
        echo "2. Provide username/password or token when prompted."
        echo "3. For Docker Hub: use your Docker Hub credentials."
        echo "4. For GHCR: use a GitHub Personal Access Token (classic) with 'read:packages' scope."
        echo "5. For AWS ECR: run 'aws ecr get-login-password' and pipe to oras login."
        echo ""
        echo "Alternative: Set ORAS_USERNAME and ORAS_PASSWORD environment variables."
        return 1
    elif echo "$error_output" | grep -qi "connection refused\|timeout\|no route"; then
        log_error "Network connectivity issue."
        echo ""
        echo "Remediation:"
        echo "1. Verify registry hostname and port: $registry"
        echo "2. Check network/firewall allows HTTPS (or HTTP if using --insecure)."
        echo "3. Test with curl: curl -v https://$registry/v2/_catalog"
        echo "4. For self-signed certificates: use --insecure or add CA to trust store."
        return 1
    elif echo "$error_output" | grep -qi "not found\|404"; then
        log_error "Registry endpoint not found."
        echo ""
        echo "Remediation:"
        echo "1. Ensure registry URL is correct (include port if non-standard)."
        echo "2. Verify registry service is running and accessible."
        return 1
    else
        log_error "Unknown error. Possible causes:"
        echo "- Malformed registry URL"
        echo "- TLS/SSL issue (use --insecure to bypass for testing)"
        echo "- Registry does not implement OCI Distribution API"
        echo ""
        echo "For verbose debugging, run with --verbose."
        return 1
    fi
}

main() {
    parse_args "$@"

    if [[ -z "$REGISTRY" ]]; then
        log_error "Registry argument is required"
        usage
    fi

    validate_oras
    check_config_files

    local error_output
    if ! error_output=$(test_registry_access "$REGISTRY" 2>&1); then
        analyze_error "$error_output" "$REGISTRY"
        exit 1
    else
        log_info "Authentication status: OK"
        exit 0
    fi
}

main "$@"
