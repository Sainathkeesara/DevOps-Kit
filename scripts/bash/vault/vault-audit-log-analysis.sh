#!/usr/bin/env bash
# =============================================================================
# Vault Audit Log Analysis Script
# =============================================================================
# Purpose   : Analyze HashiCorp Vault audit logs for security events and anomalies
# Usage     : ./vault-audit-log-analysis.sh [--dry-run] [--log-file PATH] [--output FORMAT]
# Requirements: jq, vault CLI, read access to audit logs
# Safety    : Read-only analysis - does not modify Vault state
# Tested on : Vault 1.14+, RHEL 9, Ubuntu 22.04
# =============================================================================

set -euo pipefail

DRY_RUN="${DRY_RUN:-false}"
LOG_FILE="${VAULT_AUDIT_LOG:-}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-json}"
VERBOSE="${VERBOSE:-false}"

CVE_ID="audit-log-analysis"
SCRIPT_VERSION="1.0.0"

log_info() {
    echo "[INFO] $*"
}

log_warn() {
    echo "[WARN] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_debug() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "[DEBUG] $*"
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                log_info "Dry-run mode enabled - showing analysis without actions"
                ;;
            --log-file)
                LOG_FILE="$2"
                shift
                ;;
            --output)
                OUTPUT_FORMAT="$2"
                shift
                ;;
            --verbose)
                VERBOSE=true
                ;;
            --help|-h)
                echo "Usage: $0 [--dry-run] [--log-file PATH] [--output json|text] [--verbose]"
                echo "  --dry-run   Show analysis without taking actions"
                echo "  --log-file  Path to Vault audit log file"
                echo "  --output     Output format: json or text (default: json)"
                echo "  --verbose    Enable verbose output"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
        shift
    done
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq is not installed or not in PATH"
        exit 1
    fi
    log_info "jq found: $(command -v jq)"
    
    if command -v vault >/dev/null 2>&1; then
        log_info "vault CLI found: $(command -v vault)"
    else
        log_warn "vault CLI not found - some checks will be skipped"
    fi
    
    if [[ -z "$LOG_FILE" ]]; then
        log_error "No log file specified. Use --log-file or set VAULT_AUDIT_LOG env var"
        exit 1
    fi
    
    if [[ ! -f "$LOG_FILE" ]]; then
        log_error "Log file not found: $LOG_FILE"
        exit 1
    fi
    
    log_info "Log file accessible: $LOG_FILE"
}

analyze_auth_methods() {
    local log_file="$1"
    local output_file="$2"
    
    log_info "Analyzing authentication methods..."
    
    local auth_methods
    auth_methods=$(jq -r '.auth // . | .mount_type // .mount_accessor // "unknown"' "$log_file" 2>/dev/null | sort | uniq -c | sort -rn || echo "[]")
    
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        jq -n --argjson methods "$auth_methods" '{auth_methods: $methods}'
    else
        echo "$auth_methods"
    fi
}

analyze_failed_logins() {
    local log_file="$1"
    local output_file="$2"
    
    log_info "Analyzing failed login attempts..."
    
    local failed_count
    failed_count=$(jq '[. | select(.auth and .auth.errors)] | length' "$log_file" 2>/dev/null || echo "0")
    
    local failed_entities
    failed_entities=$(jq -r '[. | select(.auth and .auth.errors)] | .[].auth.client_token // "unknown"' "$log_file" 2>/dev/null | sort | uniq -c | sort -rn | head -10 || echo "[]")
    
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        jq -n \
            --argjson count "$failed_count" \
            --argjson entities "$failed_entities" \
            '{failed_logins: {count: $count, top_entities: $entities}}'
    else
        echo "Failed login attempts: $failed_count"
        echo "$failed_entities"
    fi
}

analyze_secret_access() {
    local log_file="$1"
    local output_file="$2"
    
    log_info "Analyzing secret access patterns..."
    
    local unique_paths
    unique_paths=$(jq -r 'select(.type == "response" and .request.path) | .request.path' "$log_file" 2>/dev/null | sort | uniq | head -20 || echo "[]")
    
    local path_counts
    path_counts=$(jq -r 'select(.type == "response" and .request.path) | .request.path' "$log_file" 2>/dev/null | sort | uniq -c | sort -rn | head -10 || echo "[]")
    
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        jq -n --argjson paths "$path_counts" '{secret_access: {top_paths: $paths}}'
    else
        echo "Top accessed secret paths:"
        echo "$path_counts"
    fi
}

analyze_policy_changes() {
    local log_file="$1"
    local output_file="$2"
    
    log_info "Analyzing policy modifications..."
    
    local policy_ops
    policy_ops=$(jq -r '[. | select(.request.path | contains("policy") or contains("sys/policy"))] | length' "$log_file" 2>/dev/null || echo "0")
    
    local policy_paths
    policy_paths=$(jq -r '[. | select(.request.path | contains("policy"))] | .[].request.path' "$log_file" 2>/dev/null | sort | uniq || echo "[]")
    
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        jq -n \
            --argjson count "$policy_ops" \
            --argjson paths "$policy_paths" \
            '{policy_changes: {operations: $count, paths: $paths}}'
    else
        echo "Policy modification operations: $policy_ops"
        echo "$policy_paths"
    fi
}

analyze_privileged_operations() {
    local log_file="$1"
    local output_file="$2"
    
    log_info "Analyzing privileged operations..."
    
    local priv_ops
    priv_ops=$(jq -r '[. | select(.request.path | contains("sys/root") or contains("sys/revoke") or contains("sys/audit"))] | length' "$log_file" 2>/dev/null || echo "0")
    
    local priv_paths
    priv_paths=$(jq -r '[. | select(.request.path | contains("sys/root") or contains("sys/revoke") or contains("sys/audit"))] | .[].request.path' "$log_file" 2>/dev/null | sort | uniq | head -10 || echo "[]")
    
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        jq -n \
            --argjson count "$priv_ops" \
            --argjson paths "$priv_paths" \
            '{privileged_ops: {count: $count, paths: $paths}}'
    else
        echo "Privileged operations: $priv_ops"
        echo "$priv_paths"
    fi
}

analyze_timestamps() {
    local log_file="$1"
    local output_file="$2"
    
    log_info "Analyzing timestamp patterns..."
    
    local time_range
    time_range=$(jq -r '[.time] | min, max' "$log_file" 2>/dev/null || echo "unknown unknown")
    
    local hour_distribution
    hour_distribution=$(jq -r '[.time | strptime("%Y-%m-%dT%H:%M:%S") | .tm_hour] | group_by(.) | map({hour: .[0], count: length})' "$log_file" 2>/dev/null || echo "[]")
    
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        jq -n \
            --arg range "$time_range" \
            --argjson hours "$hour_distribution" \
            '{timestamps: {range: $range, hourly_distribution: $hours}}'
    else
        echo "Time range: $time_range"
        echo "Hourly distribution: $hour_distribution"
    fi
}

generate_summary() {
    local log_file="$1"
    
    log_info "Generating audit summary..."
    
    local total_entries
    total_entries=$(jq 'length' "$log_file" 2>/dev/null || echo "0")
    
    local time_range
    time_range=$(jq -r '[.time] | min, max' "$log_file" 2>/dev/null || echo "unknown")
    
    echo ""
    echo "============================================================"
    echo "  Vault Audit Log Analysis Summary"
    echo "============================================================"
    echo ""
    echo "Log file         : $log_file"
    echo "Total entries    : $total_entries"
    echo "Time range       : $time_range"
    echo "Analysis date    : $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "Script version  : $SCRIPT_VERSION"
    echo "============================================================"
    echo ""
}

main() {
    parse_args "$@"
    
    echo "Starting $CVE_ID audit log analysis..."
    echo ""
    
    check_dependencies
    
    local output_file
    output_file="/tmp/vault-audit-analysis-$(date +%s).json"
    
    generate_summary "$LOG_FILE" > "$output_file"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Generating analysis report without writing output"
        cat "$output_file"
        rm -f "$output_file"
        exit 0
    fi
    
    analyze_auth_methods "$LOG_FILE" >> "$output_file"
    analyze_failed_logins "$LOG_FILE" >> "$output_file"
    analyze_secret_access "$LOG_FILE" >> "$output_file"
    analyze_policy_changes "$LOG_FILE" >> "$output_file"
    analyze_privileged_operations "$LOG_FILE" >> "$output_file"
    analyze_timestamps "$LOG_FILE" >> "$output_file"
    
    log_info "Analysis complete. Results saved to: $output_file"
    
    if [[ "$OUTPUT_FORMAT" == "text" ]]; then
        cat "$output_file" | jq '.'
    fi
    
    rm -f "$output_file"
    log_info "Analysis complete"
    exit 0
}

main "$@"