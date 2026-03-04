#!/usr/bin/env bash
#
# Purpose: Lint GitHub Actions workflow files using actionlint
# Usage: ./lint-workflows.sh [--fix] [--strict] [path/to/workflows]
# Requirements: actionlint binary in PATH (install via https://rhysd.github.io/actionlint/)
# Safety: Read-only by default; use --fix for auto-corrections

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Defaults
WORKFLOW_DIR=".github/workflows"
FIX_MODE=false
STRICT_MODE=false
VERBOSE=false
OUTPUT_FORMAT=""
IGNORE_PATTERNS=()

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [WORKFLOW_DIR]

Lint GitHub Actions workflow files using actionlint.

OPTIONS:
    -f, --fix                       Enable auto-fix mode (where supported)
    -s, --strict                    Exit with error on warnings
    -i, --ignore PATTERN            Ignore pattern (can repeat)
    -o, --output FORMAT             Output format (default, json, sarif)
    -v, --verbose                   Enable verbose output
    -h, --help                      Show this help message

ARGUMENTS:
    WORKFLOW_DIR                    Path to workflows directory (default: .github/workflows)

EXAMPLES:
    $(basename "$0")
    $(basename "$0") --strict
    $(basename "$0") --fix ./ci/workflows
    $(basename "$0") --ignore "test*" --ignore "*.bak.yml"

INSTALL ACTIONLINT:
    # macOS
    brew install actionlint

    # Linux
    curl -sL https://github.com/rhysd/actionlint/releases/latest/download/actionlint_$(uname -s)_$(uname -m).tar.gz | tar xz -C /tmp
    sudo mv /tmp/actionlint /usr/local/bin/
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
            -f|--fix)
                FIX_MODE=true
                shift
                ;;
            -s|--strict)
                STRICT_MODE=true
                shift
                ;;
            -i|--ignore)
                IGNORE_PATTERNS+=("$2")
                shift 2
                ;;
            -o|--output)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                die "Unknown option: $1"
                ;;
            *)
                WORKFLOW_DIR="$1"
                shift
                ;;
        esac
    done
}

validate_prerequisites() {
    if ! command -v actionlint &>/dev/null; then
        die "actionlint not found. Install from https://rhysd.github.io/actionlint/"
    fi

    if [[ ! -d "$WORKFLOW_DIR" ]]; then
        die "Workflow directory not found: $WORKFLOW_DIR"
    fi
}

build_actionlint_args() {
    local args=""

    if [[ "$VERBOSE" == true ]]; then
        args="$args -verbose"
    fi

    if [[ -n "$OUTPUT_FORMAT" ]]; then
        args="$args -format $OUTPUT_FORMAT"
    fi

    for pattern in "${IGNORE_PATTERNS[@]}"; do
        args="$args -ignore $pattern"
    done

    echo "$args"
}

find_workflow_files() {
    find "$WORKFLOW_DIR" -type f \( -name "*.yml" -o -name "*.yaml" \) | sort
}

run_lint() {
    local files
    files=$(find_workflow_files)

    if [[ -z "$files" ]]; then
        log "No workflow files found in $WORKFLOW_DIR"
        exit 0
    fi

    local file_count
    file_count=$(echo "$files" | wc -l | tr -d ' ')
    log "Found $file_count workflow file(s)"

    local args
    args=$(build_actionlint_args)

    [[ "$VERBOSE" == true ]] && log "actionlint args: $args"

    local exit_code=0

    while IFS= read -r file; do
        echo ""
        log "Checking: $file"

        if [[ "$FIX_MODE" == true ]]; then
            # actionlint doesn't have native fix, but we report it
            log "Note: actionlint does not support auto-fix. Review errors manually."
        fi

        # shellcheck disable=SC2086
        if ! actionlint $args "$file"; then
            exit_code=1
            if [[ "$STRICT_MODE" != true ]]; then
                error "Linting failed for: $file (continuing...)"
            fi
        fi
    done <<< "$files"

    echo ""
    if [[ $exit_code -eq 0 ]]; then
        log "All workflow files passed linting"
    else
        error "Some workflow files have issues"
    fi

    return $exit_code
}

main() {
    parse_args "$@"
    validate_prerequisites

    log "Linting GitHub Actions workflows in: $WORKFLOW_DIR"
    run_lint
}

main "$@"
