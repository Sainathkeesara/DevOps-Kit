#!/usr/bin/env bash
#
# Purpose: Detect outdated GitHub Actions in workflow files
# Usage: ./check-action-updates.sh [--auto-patch] [--dry-run]
# Requirements: yq, curl, jq
# Safety: Read-only by default; --auto-patch creates backups

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Defaults
WORKFLOW_DIR=".github/workflows"
AUTO_PATCH=false
DRY_RUN=true
VERBOSE=false
GITHUB_API="https://api.github.com"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Check for outdated GitHub Actions and optionally update them.

OPTIONS:
    -d, --workflow-dir DIR          Workflow directory (default: .github/workflows)
    -p, --auto-patch                Automatically update patch/minor versions
    -e, --execute                   Execute updates (disables dry-run)
    -v, --verbose                   Enable verbose output
    -h, --help                      Show this help message

EXAMPLES:
    $(basename "$0")                    # Dry-run check only
    $(basename "$0") -p -e              # Update patch versions
    $(basename "$0") -d ./ci -v

OUTPUT:
    Lists actions with available updates
    Shows current version -> latest version

NOTES:
    - Major version updates are never auto-applied
    - Always review changes before committing
    - Uses GitHub API (may be rate limited)
EOF
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[ERROR] $*" >&2
}

die() {
    error "$*"
    exit 1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--workflow-dir)
                WORKFLOW_DIR="$2"
                shift 2
                ;;
            -p|--auto-patch)
                AUTO_PATCH=true
                shift
                ;;
            -e|--execute)
                DRY_RUN=false
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                die "Unknown option: $1"
                ;;
        esac
    done
}

validate_prerequisites() {
    if ! command -v yq &>/dev/null; then
        die "yq not found. Install from https://github.com/mikefarah/yq"
    fi

    if ! command -v jq &>/dev/null; then
        die "jq not found. Install jq."
    fi

    if [[ ! -d "$WORKFLOW_DIR" ]]; then
        die "Workflow directory not found: $WORKFLOW_DIR"
    fi
}

extract_actions() {
    local file="$1"
    yq '.. | .uses? | select(. != null)' "$file" 2>/dev/null | sort | uniq
}

parse_action() {
    local uses="$1"

    # Format: owner/repo@version or owner/repo/path@version
    if [[ ! "$uses" =~ @ ]]; then
        return 1
    fi

    local ref="${uses##*@}"
    local repo_path="${uses%@*}"

    # Handle marketplace actions vs local
    if [[ ! "$repo_path" =~ / ]]; then
        return 1
    fi

    echo "$repo_path|$ref"
}

get_latest_release() {
    local repo="$1"

    # Use GitHub API to get latest release
    local response
    response=$(curl -s "${GITHUB_API}/repos/${repo}/releases/latest" 2>/dev/null || true)

    if [[ -n "$response" ]] && echo "$response" | jq -e '.tag_name' &>/dev/null; then
        echo "$response" | jq -r '.tag_name'
        return 0
    fi

    # Fallback to tags
    response=$(curl -s "${GITHUB_API}/repos/${repo}/tags?per_page=1" 2>/dev/null || true)
    if [[ -n "$response" ]] && echo "$response" | jq -e '.[0].name' &>/dev/null; then
        echo "$response" | jq -r '.[0].name'
        return 0
    fi

    return 1
}

version_type() {
    local current="$1"
    local latest="$2"

    # Normalize
    current="${current#v}"
    latest="${latest#v}"

    local curr_major curr_minor curr_patch
    local latest_major latest_minor latest_patch

    curr_major=$(echo "$current" | cut -d. -f1)
    curr_minor=$(echo "$current" | cut -d. -f2 2>/dev/null || echo "0")
    curr_patch=$(echo "$current" | cut -d. -f3 2>/dev/null || echo "0")

    latest_major=$(echo "$latest" | cut -d. -f1)
    latest_minor=$(echo "$latest" | cut -d. -f2 2>/dev/null || echo "0")
    latest_patch=$(echo "$latest" | cut -d. -f3 2>/dev/null || echo "0")

    if [[ "$curr_major" != "$latest_major" ]]; then
        echo "major"
    elif [[ "$curr_minor" != "$latest_minor" ]]; then
        echo "minor"
    elif [[ "$curr_patch" != "$latest_patch" ]]; then
        echo "patch"
    else
        echo "current"
    fi
}

check_workflow() {
    local file="$1"
    log "Checking: $file"

    local actions
    actions=$(extract_actions "$file")

    if [[ -z "$actions" ]]; then
        [[ "$VERBOSE" == true ]] && log "  No external actions found"
        return 0
    fi

    local outdated=()

    while IFS= read -r uses; do
        [[ -z "$uses" ]] && continue

        local parsed
        parsed=$(parse_action "$uses" || true)
        [[ -z "$parsed" ]] && continue

        local repo ref
        repo="${parsed%|*}"
        ref="${parsed#*|}"

        [[ "$VERBOSE" == true ]] && log "  Checking: $repo@$ref"

        local latest
        latest=$(get_latest_release "$repo" || true)

        if [[ -z "$latest" ]]; then
            [[ "$VERBOSE" == true ]] && log "    Could not determine latest version"
            continue
        fi

        local vtype
        vtype=$(version_type "$ref" "$latest")

        if [[ "$vtype" != "current" ]]; then
            echo "    $uses -> $repo@$latest ($vtype)"
            outdated+=("$uses|$repo@$latest|$vtype")
        fi
    done <<< "$actions"

    if [[ ${#outdated[@]} -gt 0 ]] && [[ "$AUTO_PATCH" == true ]] && [[ "$DRY_RUN" == false ]]; then
        backup_and_patch "$file" "${outdated[@]}"
    fi
}

backup_and_patch() {
    local file="$1"
    shift
    local updates=("$@")

    # Create backup
    cp "$file" "${file}.bak.$(date +%s)"
    log "  Created backup: ${file}.bak.*"

    for update in "${updates[@]}"; do
        local current new vtype
        current="${update%%|*}"
        new="${update#*|}"
        new="${new%|*}"
        vtype="${update##*|}"

        # Only auto-patch minor/patch, never major
        if [[ "$vtype" != "major" ]]; then
            sed -i "s|$current|$new|g" "$file"
            log "  Updated: $current -> $new"
        fi
    done
}

main() {
    parse_args "$@"
    validate_prerequisites

    log "Checking for outdated GitHub Actions in: $WORKFLOW_DIR"
    [[ "$DRY_RUN" == true ]] && log "Running in dry-run mode (use -e to apply changes)"
    echo ""

    local files
    files=$(find "$WORKFLOW_DIR" -type f \( -name "*.yml" -o -name "*.yaml" \) | sort)

    if [[ -z "$files" ]]; then
        log "No workflow files found"
        exit 0
    fi

    while IFS= read -r file; do
        check_workflow "$file"
        echo ""
    done <<< "$files"

    log "Check complete"
}

main "$@"
