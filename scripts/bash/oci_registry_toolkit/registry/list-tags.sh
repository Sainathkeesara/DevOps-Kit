#!/usr/bin/env bash
#
# PURPOSE: List all tags for a repository in an OCI registry
# USAGE: ./list-tags.sh <repository> [--last=<tag>] [--exclude-digest] [--format=<fmt>] [--insecure] [--dry-run]
# REQUIREMENTS: oras CLI (v1.3+) installed and configured
# SAFETY: Read-only operation. Use --dry-run to preview command without execution.
#
# OUTPUT: List of tags for the specified repository
#
# EXAMPLES:
#   ./list-tags.sh myorg/myapp
#   ./list-tags.sh docker.io/library/ubuntu --last=24.04
#   ./list-tags.sh ghcr.io/myorg/app --exclude-digest --format=json
#   ./list-tags.sh myregistry.com/repo --dry-run
#
# REFERENCES:
# - ORAS CLI: https://oras.land/docs/commands/oras_repo_tags/

set -euo pipefail
IFS=$'\n\t'

# Defaults
LAST_TAG=""
EXCLUDE_DIGEST=0
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
    grep '^#' "$0" | cut -c4- | head -n 25 | tail -n +3
    exit 1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --last=*)
                LAST_TAG="${1#*=}"
                ;;
            --exclude-digest) EXCLUDE_DIGEST=1 ;;
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
                if [[ -z "$REPOSITORY" ]]; then
                    REPOSITORY="$1"
                else
                    log_error "Multiple repository arguments provided"
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
}

main() {
    parse_args "$@"

    if [[ -z "$REPOSITORY" ]]; then
        log_error "Repository argument is required (format: registry/namespace/repo or namespace/repo)"
        usage
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "DRY RUN MODE - No changes will be made"
    fi

    validate_oras

    local oras_cmd="oras repo tags"
    if [[ $EXCLUDE_DIGEST -eq 1 ]]; then
        oras_cmd="$oras_cmd --exclude-digest-tag"
    fi
    if [[ -n "$LAST_TAG" ]]; then
        oras_cmd="$oras_cmd --last \"$LAST_TAG\""
    fi
    if [[ $FORMAT != "text" ]]; then
        oras_cmd="$oras_cmd --format $FORMAT"
    fi
    if [[ $INSECURE -eq 1 ]]; then
        oras_cmd="$oras_cmd --insecure"
    fi
    oras_cmd="$oras_cmd $REPOSITORY"

    log_info "Listing tags for repository: $REPOSITORY"
    log_info "Command: $oras_cmd"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would execute: $oras_cmd"
        exit 0
    fi

    if eval "$oras_cmd"; then
        log_info "Tag listing completed successfully"
        exit 0
    else
        log_error "Failed to list tags"
        exit 1
    fi
}

main "$@"
