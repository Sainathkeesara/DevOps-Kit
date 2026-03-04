#!/usr/bin/env bash
#
# PURPOSE: Check consumer group lag and offsets
# USAGE: ./consumer-lag-check.sh [--bootstrap-server <host:port>] [--group <group-id>] [--all-groups]
# REQUIREMENTS: Kafka client tools (kafka-consumer-groups.sh) in PATH
# SAFETY: Read-only operation, safe to run anytime
#
# EXAMPLES:
#   ./consumer-lag-check.sh --all-groups                      # Check all consumer groups
#   ./consumer-lag-check.sh --group my-consumer-group         # Check specific group
#   ./consumer-lag-check.sh --group my-group --lag-threshold 1000  # Warn if lag > 1000

set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
GROUP=""
ALL_GROUPS=0
LAG_THRESHOLD=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

usage() {
    grep '^#' "$0" | cut -c4- | head -n 9 | tail -n +3
    exit 1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --bootstrap-server) BOOTSTRAP_SERVER="$2"; shift ;;
            --group) GROUP="$2"; shift ;;
            --all-groups) ALL_GROUPS=1 ;;
            --lag-threshold) LAG_THRESHOLD="$2"; shift ;;
            -h|--help) usage ;;
            *) log_error "Unknown option: $1"; usage ;;
        esac
        shift
    done
}

check_kafka_tools() {
    if ! command -v kafka-consumer-groups.sh >/dev/null 2>&1; then
        log_error "kafka-consumer-groups.sh not found in PATH"
        exit 1
    fi
}

test_connectivity() {
    if ! kafka-consumer-groups.sh --bootstrap-server "$BOOTSTRAP_SERVER" --list >/dev/null 2>&1; then
        log_error "Cannot connect to Kafka broker at $BOOTSTRAP_SERVER"
        exit 1
    fi
}

check_group_lag() {
    local group="$1"
    local output
    
    output=$(kafka-consumer-groups.sh --bootstrap-server "$BOOTSTRAP_SERVER" --describe --group "$group" 2>/dev/null) || {
        log_warn "Failed to get info for group: $group"
        return 1
    }
    
    if echo "$output" | grep -q "Consumer group '$group' does not exist"; then
        log_warn "Group does not exist: $group"
        return 1
    fi
    
    if echo "$output" | grep -q "Consumer group '$group' has no active members"; then
        log_warn "Group has no active members: $group"
    fi
    
    echo "=== Consumer Group: $group ==="
    echo "$output" | grep -E "TOPIC|PARTITION|CURRENT-OFFSET|LAG|CONSUMER-ID" | head -1
    echo "$output" | grep -v "^GROUP\|^$\|has no active members\|does not exist" | tail -n +2
    
    if [[ -n "$LAG_THRESHOLD" ]]; then
        local max_lag
        max_lag=$(echo "$output" | awk '/[0-9]+/{print $5}' | grep -E '^[0-9]+$' | sort -rn | head -1 || echo "0")
        if [[ "$max_lag" -gt "$LAG_THRESHOLD" ]]; then
            log_warn "High lag detected: $max_lag (threshold: $LAG_THRESHOLD)"
        fi
    fi
    
    echo ""
}

check_all_groups() {
    local groups
    groups=$(kafka-consumer-groups.sh --bootstrap-server "$BOOTSTRAP_SERVER" --list 2>/dev/null) || {
        log_error "Failed to list consumer groups"
        exit 1
    }
    
    if [[ -z "$groups" ]]; then
        log_warn "No consumer groups found"
        return
    fi
    
    log_info "Found $(echo "$groups" | wc -l) consumer group(s)"
    
    while IFS= read -r group; do
        [[ -z "$group" ]] && continue
        check_group_lag "$group"
    done <<< "$groups"
}

main() {
    parse_args "$@"
    check_kafka_tools
    test_connectivity
    
    if [[ $ALL_GROUPS -eq 1 ]]; then
        check_all_groups
    elif [[ -n "$GROUP" ]]; then
        check_group_lag "$GROUP"
    else
        log_error "Must specify --group or --all-groups"
        usage
    fi
}

main "$@"
