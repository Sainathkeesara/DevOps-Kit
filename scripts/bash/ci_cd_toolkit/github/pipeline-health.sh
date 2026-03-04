#!/usr/bin/env bash
#
# Purpose: Check CI/CD pipeline status and diagnostics for GitHub Actions
# Usage: ./pipeline-health.sh [--repo owner/repo] [--workflow name]
# Requirements: gh CLI, jq
# Safety: Read-only operations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Defaults
REPO=""
WORKFLOW=""
LIMIT=10
VERBOSE=false
CHECK_RUNNERS=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Check GitHub Actions pipeline health and recent runs.

OPTIONS:
    -r, --repo OWNER/REPO           Repository (default: auto-detect from git)
    -w, --workflow NAME             Filter by workflow name
    -l, --limit N                   Number of runs to check (default: 10)
    -R, --check-runners             Check runner status
    -v, --verbose                   Enable verbose output
    -h, --help                      Show this help message

EXAMPLES:
    $(basename "$0")
    $(basename "$0") -r myorg/myrepo
    $(basename "$0") -r myorg/myrepo -w "CI" -l 5
    $(basename "$0") --check-runners

REQUIREMENTS:
    - gh CLI installed and authenticated (gh auth login)
    - jq for JSON parsing
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
            -r|--repo)
                REPO="$2"
                shift 2
                ;;
            -w|--workflow)
                WORKFLOW="$2"
                shift 2
                ;;
            -l|--limit)
                LIMIT="$2"
                shift 2
                ;;
            -R|--check-runners)
                CHECK_RUNNERS=true
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
    if ! command -v gh &>/dev/null; then
        die "gh CLI not found. Install from https://cli.github.com/"
    fi

    if ! command -v jq &>/dev/null; then
        die "jq not found. Install jq."
    fi

    if ! gh auth status &>/dev/null; then
        die "Not authenticated with GitHub. Run: gh auth login"
    fi

    if [[ -z "$REPO" ]]; then
        REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || true)
        [[ -z "$REPO" ]] && die "Could not detect repository. Use -r OWNER/REPO"
    fi
}

check_recent_runs() {
    log "Checking recent workflow runs for: $REPO"
    echo ""

    local cmd="gh run list -R $REPO -L $LIMIT"
    [[ -n "$WORKFLOW" ]] && cmd="$cmd -w '$WORKFLOW'"

    [[ "$VERBOSE" == true ]] && log "Command: $cmd"

    local runs
    runs=$(eval "$cmd --json databaseId,workflowName,status,conclusion,headBranch,createdAt 2>/dev/null" || true)

    if [[ -z "$runs" ]] || [[ "$runs" == "[]" ]]; then
        log "No workflow runs found"
        return 0
    fi

    # Summary
    local total success failed cancelled
    total=$(echo "$runs" | jq 'length')
    success=$(echo "$runs" | jq '[.[] | select(.conclusion == "success")] | length')
    failed=$(echo "$runs" | jq '[.[] | select(.conclusion == "failure")] | length')
    cancelled=$(echo "$runs" | jq '[.[] | select(.conclusion == "cancelled")] | length')

    echo "=== Summary (last $LIMIT runs) ==="
    echo "  Total: $total"
    echo "  Success: $success"
    echo "  Failed: $failed"
    echo "  Cancelled: $cancelled"
    echo ""

    # Recent failures
    local failures
    failures=$(echo "$runs" | jq -r '.[] | select(.conclusion == "failure") | "\(.workflowName) - \(.headBranch) - \(.createdAt)"' | head -5)

    if [[ -n "$failures" ]]; then
        echo "=== Recent Failures ==="
        echo "$failures" | sed 's/^/  /'
        echo ""
    fi

    # In progress
    local in_progress
    in_progress=$(echo "$runs" | jq -r '.[] | select(.status != "completed") | "\(.workflowName) - \(.headBranch) - \(.status)"')

    if [[ -n "$in_progress" ]]; then
        echo "=== In Progress ==="
        echo "$in_progress" | sed 's/^/  /'
        echo ""
    fi
}

check_runners() {
    log "Checking GitHub-hosted runner status..."
    echo ""

    # GitHub status page check (simplified)
    local status
    status=$(curl -s "https://www.githubstatus.com/api/v2/status.json" 2>/dev/null | jq -r '.status.description' || echo "unknown")

    echo "GitHub Status: $status"
    echo ""

    # Organization runners (if applicable)
    local org
    org=$(echo "$REPO" | cut -d'/' -f1)

    log "Checking self-hosted runners for: $org"

    local runners
    runners=$(gh api "orgs/$org/actions/runners" 2>/dev/null | jq -r '.runners[]? | "\(.name): \(.status) (\(.os))"' || true)

    if [[ -n "$runners" ]]; then
        echo "Self-hosted runners:"
        echo "$runners" | sed 's/^/  /'
    else
        echo "  No self-hosted runners found or insufficient permissions"
    fi
    echo ""
}

show_workflow_stats() {
    log "Workflow statistics for: $REPO"
    echo ""

    local workflows
    workflows=$(gh workflow list -R "$REPO" --json name,state 2>/dev/null || true)

    if [[ -z "$workflows" ]] || [[ "$workflows" == "[]" ]]; then
        log "No workflows found"
        return 0
    fi

    echo "=== Workflows ==="
    echo "$workflows" | jq -r '.[] | "  \(.name) - \(.state)"'
    echo ""
}

main() {
    parse_args "$@"
    validate_prerequisites

    echo "========================================"
    echo "CI/CD Pipeline Health Check"
    echo "========================================"
    echo "Repository: $REPO"
    echo "Time: $(date -Iseconds)"
    echo ""

    show_workflow_stats
    check_recent_runs

    if [[ "$CHECK_RUNNERS" == true ]]; then
        check_runners
    fi

    log "Health check complete"
}

main "$@"
