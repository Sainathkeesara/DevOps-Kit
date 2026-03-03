#!/usr/bin/env bash
#
# PURPOSE: List all repositories in an OCI registry
# USAGE: ./list-repos.sh <registry> [--namespace=<ns>] [--format=<fmt>] [--insecure] [--dry-run]
# REQUIREMENTS: oras CLI (v1.3+) installed and configured
# SAFETY: Read-only operation. Use --dry-run to preview command without execution.
#
# OUTPUT: List of repository names under the registry/namespace
#
# EXAMPLES:
#   ./list-repos.sh localhost:5000
#   ./list-repos.sh docker.io/library --format=json
#   ./list-repos.sh ghcr.io/myorg --insecure
#   ./list-repos.sh myregistry.com --dry-run
#
# REFERENCES:
# - ORAS CLI: https://oras.land/docs/commands/oras_repo_ls/

set -euo pipefail
IFS=$'\n\t'

# Defaults
NAMESPACE=""
FORMAT="text"
INSECURE=0
DRY_RUN=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
    grep '^#' "$0" | cut -c4- | head -n 20 | tail -n +3
    exit 1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --namespace=*| -n=*)
                NAMESPACE="${1#*=}"
                ;;
            --format=*)
                FORMAT="${1#*=}"
                ;;
            --insecure) INSECURE=1 ;;
            --dry-run) DRY_RUN=1 ;;
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

    local version
    version=$(oras version --output=short 2>/dev/null | cut -d'v' -f2 || echo "0")
    if [[ $(echo "$version < 1.3" | bc -l 2>/dev/null || echo 1) -eq 1 ]]; then
        log_warn "ORAS version 1.3+ recommended. Current: v$version"
    fi
}

build_target() {
    local target="$REGISTRY"
    if [[ -n "$NAMESPACE" ]]; then
        if [[ "$NAMESPACE" == */ ]]; then
            target="${NAMESPACE}${REGISTRY}"
        else
            target="${NAMESPACE}/${REGISTRY}"
        fi
    fi
    echo "$target"
}

main() {
    parse_args "$@"

    if [[ -z "$REGISTRY" ]]; then
        log_error "Registry argument is required"
        usage
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "DRY RUN MODE - No changes will be made"
    fi

    validate_oras

    local target
    target=$(build_target)

    local oras_cmd="oras repo ls"
    if [[ $FORMAT != "text" ]]; then
        oras_cmd="$oras_cmd --format $FORMAT"
    fi
    if [[ $INSECURE -eq 1 ]]; then
        oras_cmd="$oras_cmd --insecure"
    fi
    oras_cmd="$oras_cmd $target"

    log_info "Listing repositories in: $target"
    log_info "Command: $oras_cmd"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would execute: $oras_cmd"
        exit 0
    fi

    if eval "$oras_cmd"; then
        log_info "Repository listing completed successfully"
        exit 0
    else
        log_error "Failed to list repositories"
        exit 1
    fi
}

main "$@"
