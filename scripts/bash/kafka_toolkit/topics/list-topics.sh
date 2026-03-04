#!/usr/bin/env bash
#
# PURPOSE: List Kafka topics with optional detailed information
# USAGE: ./list-topics.sh [--bootstrap-server <host:port>] [--detailed] [--under-replicated]
# REQUIREMENTS: Kafka client tools (kafka-topics.sh) in PATH, broker connectivity
# SAFETY: Read-only operation, safe to run anytime
#
# EXAMPLES:
#   ./list-topics.sh                                    # Basic list
#   ./list-topics.sh --detailed                         # With partition/replica info
#   ./list-topics.sh --under-replicated                 # Only under-replicated topics
#   ./list-topics.sh --bootstrap-server kafka:9092

set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
DETAILED=0
UNDER_REPLICATED_ONLY=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

usage() {
    grep '^#' "$0" | cut -c4- | head -n 8 | tail -n +3
    exit 1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --bootstrap-server) BOOTSTRAP_SERVER="$2"; shift ;;
            --detailed) DETAILED=1 ;;
            --under-replicated) UNDER_REPLICATED_ONLY=1 ;;
            -h|--help) usage ;;
            *) log_error "Unknown option: $1"; usage ;;
        esac
        shift
    done
}

check_kafka_tools() {
    if ! command -v kafka-topics.sh >/dev/null 2>&1; then
        log_error "kafka-topics.sh not found in PATH"
        log_error "Ensure Kafka client tools are installed and in PATH"
        exit 1
    fi
}

test_connectivity() {
    if ! kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --list >/dev/null 2>&1; then
        log_error "Cannot connect to Kafka broker at $BOOTSTRAP_SERVER"
        exit 1
    fi
}

list_basic() {
    log_info "Listing topics on $BOOTSTRAP_SERVER..."
    kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --list 2>/dev/null | sort || {
        log_error "Failed to list topics"
        exit 1
    }
}

list_detailed() {
    log_info "Listing topics with details..."
    local topics
    topics=$(kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --list 2>/dev/null | sort)
    
    if [[ -z "$topics" ]]; then
        log_warn "No topics found"
        return
    fi
    
    printf "%-40s %10s %10s %s\n" "TOPIC" "PARTITIONS" "REPLICAS" "CONFIGS"
    printf "%s\n" "$(printf '=%.0s' {1..80})"
    
    while IFS= read -r topic; do
        [[ -z "$topic" ]] && continue
        local desc
        desc=$(kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --describe --topic "$topic" 2>/dev/null)
        
        local partition_count
        partition_count=$(echo "$desc" | grep -c "^Topic: $topic" || true)
        
        local replica_factor
        replica_factor=$(echo "$desc" | head -1 | grep -oP 'ReplicationFactor: \K[0-9]+' || echo "-")
        
        local configs
        configs=$(echo "$desc" | grep "Configs:" | head -1 | cut -d':' -f4- | tr -d ' ' | cut -c1-30 || echo "-")
        
        printf "%-40s %10s %10s %s\n" "${topic:0:40}" "$partition_count" "$replica_factor" "$configs"
    done <<< "$topics"
}

list_under_replicated() {
    log_info "Checking for under-replicated partitions..."
    local topics
    topics=$(kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --list 2>/dev/null)
    
    local found=0
    while IFS= read -r topic; do
        [[ -z "$topic" ]] && continue
        local desc
        desc=$(kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --describe --topic "$topic" 2>/dev/null)
        
        if echo "$desc" | grep -q "Leader: none\|Isr:.*Isr:"; then
            echo "$desc" | grep -E "Topic: $topic|Leader:|Replicas:|Isr:" | head -20
            found=1
            echo "---"
        fi
    done <<< "$topics"
    
    if [[ $found -eq 0 ]]; then
        log_info "No under-replicated partitions found"
    fi
}

main() {
    parse_args "$@"
    check_kafka_tools
    test_connectivity
    
    if [[ $UNDER_REPLICATED_ONLY -eq 1 ]]; then
        list_under_replicated
    elif [[ $DETAILED -eq 1 ]]; then
        list_detailed
    else
        list_basic
    fi
}

main "$@"
