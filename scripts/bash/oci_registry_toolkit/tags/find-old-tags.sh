#!/usr/bin/env bash
#
# PURPOSE: Find old or unused tags in a repository based on age or pattern
# USAGE: ./find-old-tags.sh <repository> [--days=<N>] [--pattern=<regex>] [--exclude-digest] [--insecure] [--dry-run]
# REQUIREMENTS: oras CLI (v1.3+), jq installed
# SAFETY: Read-only by default. Use --delete to actually remove tags (requires confirmation). --dry-run shows what would be done.
#
# OUTPUT: List of tags matching criteria with creation dates (if available)
#
# EXAMPLES:
#   ./find-old-tags.sh myorg/app --days=90
#   ./find-old-tags.sh myorg/app --pattern="^test-.*" --days=30
#   ./find-old-tags.sh myorg/app --exclude-digest --insecure
#   ./find-old-tags.sh myorg/app --delete --dry-run
#
# REFERENCES:
# - OCI Manifest Specification: https://docs.oracle.com/en/operating-systems/container-registry/oci-manifest-spec.html
# - ORAS manifest fetch: https://oras.land/docs/commands/oras_manifest_fetch/

set -euo pipefail
IFS=$'\n\t'

# Defaults
DAYS_THRESHOLD=90
PATTERN=""
EXCLUDE_DIGEST=0
INSECURE=0
DRY_RUN=0
DELETE_MODE=0

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
    grep '^#' "$0" | cut -c4- | head -n 35 | tail -n +3
    exit 1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --days=*)
                DAYS_THRESHOLD="${1#*=}"
                ;;
            --pattern=*)
                PATTERN="${1#*=}"
                ;;
            --exclude-digest) EXCLUDE_DIGEST=1 ;;
            --insecure) INSECURE=1 ;;
            --delete) DELETE_MODE=1 ;;
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

    if ! command -v jq &>/dev/null; then
        log_error "jq is required. Install from: https://jqlang.github.io/jq/"
        exit 1
    fi
}

get_tags() {
    local repo="$1"
    local exclude_flag=""
    if [[ $EXCLUDE_DIGEST -eq 1 ]]; then
        exclude_flag="--exclude-digest-tag"
    fi
    local insecure_flag=""
    if [[ $INSECURE -eq 1 ]]; then
        insecure_flag="--insecure"
    fi

    oras repo tags $exclude_flag $insecure_flag "$repo" 2>/dev/null || echo ""
}

get_manifest_created() {
    local repo_tag="$1"
    local insecure_flag=""
    if [[ $INSECURE -eq 1 ]]; then
        insecure_flag="--insecure"
    fi

    # Fetch manifest and extract created timestamp from config
    oras manifest fetch "$repo_tag" --format=json $insecure_flag 2>/dev/null | \
        jq -r '.config.created // empty' || echo ""
}

is_old_tag() {
    local created="$1"
    local threshold_days="$2"

    if [[ -z "$created" ]]; then
        return 1  # unknown age, can't determine
    fi

    # Convert created time to epoch seconds
    local created_epoch
    created_epoch=$(date -d "$created" +%s 2>/dev/null || echo 0)
    if [[ $created_epoch -eq 0 ]]; then
        return 1
    fi

    local now_epoch
    now_epoch=$(date +%s)
    local age_days=$(( (now_epoch - created_epoch) / 86400 ))

    if [[ $age_days -ge $threshold_days ]]; then
        return 0  # true, it's old
    else
        return 1  # false, it's not old
    fi
}

matches_pattern() {
    local tag="$1"
    local pattern="$2"

    if [[ -z "$pattern" ]]; then
        return 0  # no pattern means match all
    fi

    if [[ "$tag" =~ $pattern ]]; then
        return 0
    else
        return 1
    fi
}

main() {
    parse_args "$@"

    if [[ -z "$REPOSITORY" ]]; then
        log_error "Repository argument is required (format: registry/namespace/repo or namespace/repo)"
        usage
    fi

    if [[ $DRY_RUN -eq 1 && $DELETE_MODE -eq 1 ]]; then
        log_warn "Both --dry-run and --delete specified. Will only show what would be deleted."
        DELETE_MODE=0
    fi

    if [[ $DELETE_MODE -eq 1 ]]; then
        log_warn "DELETE MODE ENABLED - tags will be permanently removed"
        read -p "Are you absolutely sure? Type 'YES' to continue: " confirm
        if [[ "$confirm" != "YES" ]]; then
            log_info "Aborted."
            exit 0
        fi
    fi

    validate_tools

    log_info "Scanning repository: $REPOSITORY"
    log_info "Threshold: tags older than $DAYS_THRESHOLD days"
    if [[ -n "$PATTERN" ]]; then
        log_info "Pattern filter: $PATTERN"
    fi

    local tags
    tags=$(get_tags "$REPOSITORY")

    if [[ -z "$tags" ]]; then
        log_warn "No tags found or unable to list tags"
        exit 0
    fi

    local old_tags=()
    local tag

    log_info "Checking $(echo "$tags" | wc -l) tags..."

    while IFS= read -r tag; do
        [[ -z "$tag" ]] && continue

        if ! matches_pattern "$tag" "$PATTERN"; then
            continue
        fi

        local repo_tag="$REPOSITORY:$tag"
        local created
        created=$(get_manifest_created "$repo_tag")

        if is_old_tag "$created" "$DAYS_THRESHOLD"; then
            old_tags+=("$tag|$created")
        fi
    done <<< "$tags"

    local old_count=${#old_tags[@]}
    if [[ $old_count -eq 0 ]]; then
        log_info "No old tags found matching criteria."
        exit 0
    fi

    log_warn "Found $old_count old tag(s):"
    printf "%-40s %-25s\n" "TAG" "CREATED"
    echo "----------------------------------------------------------------"
    for entry in "${old_tags[@]}"; do
        tag="${entry%|*}"
        created="${entry#*|}"
        printf "%-40s %-25s\n" "$tag" "$created"
    done

    if [[ $DELETE_MODE -eq 1 ]]; then
        log_error "DELETING old tags:"
        for entry in "${old_tags[@]}"; do
            tag="${entry%|*}"
            repo_tag="$REPOSITORY:$tag"
            log_warn "Deleting: $repo_tag"
            if [[ $DRY_RUN -eq 0 ]]; then
                oras manifest delete "$repo_tag" --insecure 2>/dev/null || log_warn "Failed to delete $repo_tag (may not exist or insufficient permissions)"
            else
                log_info "[DRY RUN] Would delete: $repo_tag"
            fi
        done
        log_info "Cleanup complete."
    else
        log_info "To delete these tags, run: $0 $REPOSITORY --days=$DAYS_THRESHOLD --delete ${PATTERN:+--pattern=$PATTERN} --insecure"
    fi

    exit 0
}

main "$@"
