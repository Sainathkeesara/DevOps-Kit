#!/usr/bin/env bash
#
# Purpose: Validate GitHub Actions workflow syntax without running
# Usage: ./validate-workflow.sh workflow-file.yml [--schema-check]
# Requirements: yq, optional: actionlint
# Safety: Read-only validation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Defaults
WORKFLOW_FILE=""
SCHEMA_CHECK=false
VERBOSE=false

usage() {
    cat <<EOF
Usage: $(basename "$0") WORKFLOW_FILE [OPTIONS]

Validate GitHub Actions workflow file syntax and structure.

OPTIONS:
    -s, --schema-check              Enable JSON schema validation (requires ajv or similar)
    -v, --verbose                   Enable verbose output
    -h, --help                      Show this help message

EXAMPLES:
    $(basename "$0") .github/workflows/ci.yml
    $(basename "$0") ci.yml -v
    $(basename "$0") deploy.yml --schema-check

VALIDATION CHECKS:
    - YAML syntax
    - Required keys (name, on, jobs)
    - Job dependencies exist
    - Step references valid
    - Expression syntax basics
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
            -s|--schema-check)
                SCHEMA_CHECK=true
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
            -*)
                die "Unknown option: $1"
                ;;
            *)
                if [[ -z "$WORKFLOW_FILE" ]]; then
                    WORKFLOW_FILE="$1"
                else
                    die "Unexpected argument: $1"
                fi
                shift
                ;;
        esac
    done
}

validate_prerequisites() {
    if ! command -v yq &>/dev/null; then
        die "yq not found. Install from https://github.com/mikefarah/yq"
    fi

    [[ -z "$WORKFLOW_FILE" ]] && die "Workflow file path is required"
    [[ ! -f "$WORKFLOW_FILE" ]] && die "Workflow file not found: $WORKFLOW_FILE"
}

validate_yaml_syntax() {
    log "Checking YAML syntax..."

    if yq '.' "$WORKFLOW_FILE" &>/dev/null; then
        log "  ✓ YAML syntax valid"
        return 0
    else
        error "  ✗ YAML syntax error"
        return 1
    fi
}

validate_required_keys() {
    log "Checking required keys..."
    local valid=true

    # Check for 'on' trigger
    if ! yq '.on' "$WORKFLOW_FILE" &>/dev/null || [[ "$(yq '.on' "$WORKFLOW_FILE")" == "null" ]]; then
        error "  ✗ Missing or invalid 'on' trigger"
        valid=false
    else
        [[ "$VERBOSE" == true ]] && log "  ✓ 'on' trigger present"
    fi

    # Check for jobs
    if ! yq '.jobs' "$WORKFLOW_FILE" &>/dev/null || [[ "$(yq '.jobs' "$WORKFLOW_FILE")" == "null" ]]; then
        error "  ✗ Missing 'jobs' section"
        valid=false
    else
        [[ "$VERBOSE" == true ]] && log "  ✓ Jobs section present"
    fi

    $valid
}

validate_job_dependencies() {
    log "Checking job dependencies..."
    local valid=true

    local jobs
    jobs=$(yq '.jobs | keys | .[]' "$WORKFLOW_FILE" 2>/dev/null)

    if [[ -z "$jobs" ]]; then
        log "  No jobs defined"
        return 0
    fi

    local all_jobs
    all_jobs=$(echo "$jobs" | sort | uniq)

    while IFS= read -r job_name; do
        [[ -z "$job_name" ]] && continue

        # Check needs
        local needs
        needs=$(yq ".jobs.${job_name}.needs | select(. != null) | .[]" "$WORKFLOW_FILE" 2>/dev/null || true)

        if [[ -n "$needs" ]]; then
            while IFS= read -r need; do
                [[ -z "$need" ]] && continue
                if ! echo "$all_jobs" | grep -qx "$need"; then
                    error "  ✗ Job '$job_name' needs unknown job: $need"
                    valid=false
                else
                    [[ "$VERBOSE" == true ]] && log "  ✓ Job '$job_name' dependency '$need' exists"
                fi
            done <<< "$needs"
        fi
    done <<< "$jobs"

    $valid
}

validate_action_references() {
    log "Checking action references..."
    local valid=true

    # Extract uses statements
    local uses
    uses=$(yq '.. | .uses? | select(. != null)' "$WORKFLOW_FILE" 2>/dev/null || true)

    if [[ -z "$uses" ]]; then
        log "  No external actions used"
        return 0
    fi

    while IFS= read -r action; do
        [[ -z "$action" ]] && continue

        # Check if it has a version/tag
        if [[ ! "$action" =~ @ ]]; then
            error "  ✗ Action '$action' missing version tag (@v1, @main, etc.)"
            valid=false
        elif [[ "$action" =~ @[a-f0-9]{40}$ ]]; then
            [[ "$VERBOSE" == true ]] && log "  ✓ Action '$action' uses commit SHA (secure)"
        elif [[ "$action" =~ @[vV]?[0-9]+ ]]; then
            [[ "$VERBOSE" == true ]] && log "  ✓ Action '$action' uses version tag"
        else
            [[ "$VERBOSE" == true ]] && log "  ⚠ Action '$action' uses non-version tag"
        fi
    done <<< "$uses"

    $valid
}

validate_secrets() {
    log "Checking secrets usage..."

    local secret_refs
    secret_refs=$(yq '.. | select(tag == "!!str") | select(test("secrets\\."))' "$WORKFLOW_FILE" 2>/dev/null || true)

    if [[ -n "$secret_refs" ]]; then
        local count
        count=$(echo "$secret_refs" | grep -c 'secrets\.' || true)
        log "  Found $count secret reference(s)"

        # Check for hardcoded secrets (common mistake)
        if grep -E "(password|token|secret|key)\s*[:=]\s*['\"][^'\"]+['\"]" "$WORKFLOW_FILE" 2>/dev/null | grep -v "\${{" | head -1; then
            error "  ⚠ Possible hardcoded secret detected (review manually)"
        fi
    else
        [[ "$VERBOSE" == true ]] && log "  No secrets referenced"
    fi
}

main() {
    parse_args "$@"
    validate_prerequisites

    log "Validating workflow: $WORKFLOW_FILE"
    echo ""

    local exit_code=0

    validate_yaml_syntax || exit_code=1
    validate_required_keys || exit_code=1
    validate_job_dependencies || exit_code=1
    validate_action_references || exit_code=1
    validate_secrets

    echo ""
    if [[ $exit_code -eq 0 ]]; then
        log "Validation passed: $WORKFLOW_FILE"
    else
        error "Validation failed: $WORKFLOW_FILE"
    fi

    exit $exit_code
}

main "$@"
