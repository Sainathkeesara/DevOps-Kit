#!/usr/bin/env bash
#
# PURPOSE: Generate a safe keepalive pull plan for OCI artifacts
# USAGE: ./keepalive-pull-plan.sh <repository> [--output=<script-path>] [--pattern=<regex>] [--min-age-days=<N>] [--max-age-days=<N>] [--target-dir=<path>] [--insecure] [--dry-run]
# REQUIREMENTS: oras CLI (v1.3+) installed and configured
# SAFETY: Generates a script; actual pulls executed only when generated script is run. Review generated plan before execution.
#
# OUTPUT: A bash script containing oras pull commands for selected tags
#
# EXAMPLES:
#   ./keepalive-pull-plan.sh myorg/app --output=pull-plan.sh --target-dir=./backup
#   ./keepalive-pull-plan.sh myorg/app --pattern="^v[0-9]+\.[0-9]+\.[0-9]+$" --max-age-days=365
#   ./keepalive-pull-plan.sh myorg/app --dry-run
#
# REFERENCES:
# - ORAS pull: https://oras.land/docs/commands/oras_pull/
# - OCI Image Layout: https://github.com/opencontainers/image-spec/blob/main/image-layout.md

set -euo pipefail
IFS=$'\n\t'

# Defaults
OUTPUT_FILE=""
PATTERN=""
MIN_AGE_DAYS=0
MAX_AGE_DAYS=365
TARGET_DIR="./oci-layout"
INSECURE=0
DRY_RUN=0

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
    grep '^#' "$0" | cut -c4- | head -n 40 | tail -n +3
    exit 1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --output=*)
                OUTPUT_FILE="${1#*=}"
                ;;
            --pattern=*)
                PATTERN="${1#*=}"
                ;;
            --min-age-days=*)
                MIN_AGE_DAYS="${1#*=}"
                ;;
            --max-age-days=*)
                MAX_AGE_DAYS="${1#*=}"
                ;;
            --target-dir=*)
                TARGET_DIR="${1#*=}"
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

validate_tools() {
    if ! command -v oras &>/dev/null; then
        log_error "oras CLI not found. Install from: https://oras.land/docs/installation/"
        exit 1
    fi
}

get_tags() {
    local repo="$1"
    oras repo tags --exclude-digest-tag "$repo" 2>/dev/null || echo ""
}

get_manifest_created() {
    local repo_tag="$1"
    oras manifest fetch "$repo_tag" --format=json 2>/dev/null | \
        jq -r '.config.created // empty' 2>/dev/null || echo ""
}

is_within_age_range() {
    local created="$1"
    local min_days="$2"
    local max_days="$3"

    if [[ -z "$created" ]]; then
        return 1
    fi

    local created_epoch
    created_epoch=$(date -d "$created" +%s 2>/dev/null || echo 0)
    if [[ $created_epoch -eq 0 ]]; then
        return 1
    fi

    local now_epoch
    now_epoch=$(date +%s)
    local age_days=$(( (now_epoch - created_epoch) / 86400 ))

    if [[ $age_days -ge $min_days && $age_days -le $max_days ]]; then
        return 0
    else
        return 1
    fi
}

generate_pull_script() {
    local repo="$1"
    local tags=("${@:2}")
    local script_content
    local insecure_flag=""
    local target_dir="$TARGET_DIR"

    if [[ $INSECURE -eq 1 ]]; then
        insecure_flag="--insecure"
    fi

    script_content="#!/usr/bin/env bash
#
# AUTO-GENERATED keepalive pull plan
# Repository: $repo
# Generated: $(date -u +%Y-%m-%d\ %H:%M:%S\ UTC)
# Target directory: $target_dir
#
# PURPOSE: Pull selected OCI artifacts to local OCI layout for offline/cached access.
# SAFETY: Review tags and destination before execution.
#
# Usage: bash $(basename "$OUTPUT_FILE")

set -euo pipefail

mkdir -p \"$target_dir\"

echo \"Pulling artifacts to $target_dir...\"
"

    for tag in "${tags[@]}"; do
        local repo_tag="$repo:$tag"
        script_content+="echo \"Pulling $repo_tag...\"\n"
        script_content+="oras pull $insecure_flag -o \"$target_dir\" \"$repo_tag\" 2>/dev/null || echo \"Failed: $repo_tag\"\n"
    done

    script_content+="echo \"Pull plan completed.\"\n"

    echo "$script_content"
}

main() {
    parse_args "$@"

    if [[ -z "$REPOSITORY" ]]; then
        log_error "Repository argument is required"
        usage
    fi

    validate_tools

    log_info "Generating keepalive pull plan for: $REPOSITORY"
    log_info "Target directory: $TARGET_DIR"
    log_info "Age filter: tags between $MIN_AGE_DAYS and $MAX_AGE_DAYS days old"
    if [[ -n "$PATTERN" ]]; then
        log_info "Pattern filter: $PATTERN"
    fi

    local tags
    tags=$(get_tags "$REPOSITORY")

    if [[ -z "$tags" ]]; then
        log_error "No tags found or unable to list tags"
        exit 1
    fi

    local selected_tags=()
    local tag

    log_info "Evaluating $(echo "$tags" | wc -l) tags..."

    while IFS= read -r tag; do
        [[ -z "$tag" ]] && continue

        if [[ -n "$PATTERN" && ! "$tag" =~ $PATTERN ]]; then
            continue
        fi

        local created
        created=$(get_manifest_created "$REPOSITORY:$tag")

        if is_within_age_range "$created" "$MIN_AGE_DAYS" "$MAX_AGE_DAYS"; then
            selected_tags+=("$tag")
        fi
    done <<< "$tags"

    local selected_count=${#selected_tags[@]}
    log_info "Selected $selected_count tag(s) for pull plan."

    if [[ $selected_count -eq 0 ]]; then
        log_warn "No tags matched criteria. Adjust filters."
        exit 0
    fi

    local plan_script
    plan_script=$(generate_pull_script "$REPOSITORY" "${selected_tags[@]}")

    if [[ -z "$OUTPUT_FILE" ]]; then
        echo "$plan_script"
        log_info "Plan written to stdout. Redirect to a file to save."
    else
        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "[DRY RUN] Would write plan to: $OUTPUT_FILE"
            log_info "Plan content preview (first 20 lines):"
            echo "$plan_script" | head -n 20
        else
            echo "$plan_script" > "$OUTPUT_FILE"
            chmod +x "$OUTPUT_FILE"
            log_info "Pull plan saved to: $OUTPUT_FILE"
            log_info "Review the script, then run: bash $OUTPUT_FILE"
        fi
    fi

    exit 0
}

main "$@"
