#!/usr/bin/env bash
#
# Purpose: Manage Kafka partitions (increase, describe, verify)
# Usage: ./partition-mgmt.sh --topic NAME [--describe | --increase N]
# Requirements: kafka-topics.sh in PATH, connectivity to Kafka cluster
# Safety: Cannot decrease partitions; dry-run for modifications

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Defaults
BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
TOPIC=""
ACTION=""
PARTITION_COUNT=""
DRY_RUN=true
VERBOSE=false
COMMAND_CONFIG=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Manage Kafka partitions: describe, increase count, and verify distribution.

ACTIONS:
    -d, --describe                  Describe partition distribution
    -i, --increase N                Increase partition count to N
    -v, --verify                    Verify partition leader distribution

OPTIONS:
    -t, --topic TOPIC               Topic name (required)
    -b, --bootstrap-server SERVER   Kafka bootstrap server (default: localhost:9092)
    -c, --command-config FILE       Properties file for client configuration
    -n, --dry-run                   Show what would be changed (default)
    -e, --execute                   Execute modification (required for increase)
    -v, --verbose                   Enable verbose output
    -h, --help                      Show this help message

IMPORTANT NOTES:
    - Partitions can only be INCREASED, never decreased
    - Increasing partitions affects message ordering for keyed messages
    - New partitions will not have historical data

EXAMPLES:
    $(basename "$0") -t events -d
    $(basename "$0") -t events -i 24 -e
    $(basename "$0") -t events --verify
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
            -t|--topic)
                TOPIC="$2"
                shift 2
                ;;
            -b|--bootstrap-server)
                BOOTSTRAP_SERVER="$2"
                shift 2
                ;;
            -c|--command-config)
                COMMAND_CONFIG="$2"
                shift 2
                ;;
            -d|--describe)
                ACTION="describe"
                shift
                ;;
            -i|--increase)
                ACTION="increase"
                PARTITION_COUNT="$2"
                shift 2
                ;;
            --verify)
                ACTION="verify"
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
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
    if ! command -v kafka-topics.sh &>/dev/null; then
        die "kafka-topics.sh not found. Ensure Kafka bin/ is in PATH."
    fi

    if [[ -z "$TOPIC" ]]; then
        die "Topic name required (-t TOPIC)"
    fi

    if [[ -n "$COMMAND_CONFIG" && ! -f "$COMMAND_CONFIG" ]]; then
        die "Command config file not found: $COMMAND_CONFIG"
    fi

    if [[ "$ACTION" == "increase" && -z "$PARTITION_COUNT" ]]; then
        die "Partition count required for --increase"
    fi

    if [[ "$ACTION" == "increase" && "$PARTITION_COUNT" -le 0 ]]; then
        die "Partition count must be positive"
    fi
}

cmd_base() {
    local cmd="kafka-topics.sh --bootstrap-server $BOOTSTRAP_SERVER"
    if [[ -n "$COMMAND_CONFIG" ]]; then
        cmd="$cmd --command-config $COMMAND_CONFIG"
    fi
    echo "$cmd"
}

topic_exists() {
    local cmd
    cmd=$(cmd_base)
    
    if eval "$cmd --list 2>/dev/null" | grep -qx "$TOPIC"; then
        return 0
    else
        return 1
    fi
}

describe_partitions() {
    local cmd
    cmd=$(cmd_base)
    cmd="$cmd --describe --topic $TOPIC"

    log "Describing partitions for topic: $TOPIC"
    [[ "$VERBOSE" == true ]] && log "Executing: $cmd"

    echo ""
    eval "$cmd" 2>/dev/null || die "Failed to describe topic"
    
    # Extract partition summary
    echo ""
    echo "=== Partition Summary ==="
    local partition_info
    partition_info=$(eval "$cmd" 2>/dev/null)
    
    local partition_count
    partition_count=$(echo "$partition_info" | grep -c "^Topic:" || true)
    
    local replication_factor
    replication_factor=$(echo "$partition_info" | grep "Replicas:" | head -1 | awk '{print NF-1}')
    
    echo "Topic: $TOPIC"
    echo "Partition Count: $partition_count"
    echo "Replication Factor: $replication_factor"
}

increase_partitions() {
    local cmd
    cmd=$(cmd_base)
    cmd="$cmd --alter --topic $TOPIC --partitions $PARTITION_COUNT"

    # Get current partition count
    local current_count
    current_count=$(eval "$cmd --describe 2>/dev/null" | grep -c "^Topic:" || true)

    if [[ "$PARTITION_COUNT" -le "$current_count" ]]; then
        die "Cannot decrease partitions. Current: $current_count, Requested: $PARTITION_COUNT"
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log "DRY-RUN mode - would execute:"
        echo "  $cmd"
        echo ""
        log "Partition change:"
        echo "  Topic: $TOPIC"
        echo "  Current partitions: $current_count"
        echo "  New partition count: $PARTITION_COUNT"
        echo "  New partitions added: $((PARTITION_COUNT - current_count))"
        echo ""
        log "WARNING: New partitions will not contain historical data"
        log "WARNING: This may affect message ordering for keyed messages"
        return 0
    fi

    log "WARNING: Increasing partitions is irreversible"
    log "Current partitions: $current_count"
    log "New partition count: $PARTITION_COUNT"
    echo ""
    read -r -p "Type 'increase' to confirm: " confirm
    if [[ "$confirm" != "increase" ]]; then
        die "Aborted"
    fi

    log "Increasing partitions for topic: $TOPIC"
    [[ "$VERBOSE" == true ]] && log "Executing: $cmd"

    if eval "$cmd" 2>&1; then
        log "Partitions increased successfully"
        log "New partition count: $PARTITION_COUNT"
    else
        die "Failed to increase partitions"
    fi
}

verify_partition_distribution() {
    local cmd
    cmd=$(cmd_base)
    cmd="$cmd --describe --topic $TOPIC"

    log "Verifying partition leader distribution for topic: $TOPIC"

    local partition_info
    partition_info=$(eval "$cmd" 2>/dev/null) || die "Failed to describe topic"

    echo ""
    echo "=== Leader Distribution ==="
    
    # Extract leader info
    local leaders
    leaders=$(echo "$partition_info" | grep "Leader:" | awk -F'Leader: ' '{print $2}' | awk '{print $1}')
    
    local broker_counts
    broker_counts=$(echo "$leaders" | sort | uniq -c | sort -rn)
    
    echo "$broker_counts"
    echo ""
    
    # Check for imbalance
    local leader_count
    leader_count=$(echo "$leaders" | wc -l)
    local unique_leaders
    unique_leaders=$(echo "$leaders" | sort -u | wc -l)
    
    if [[ "$unique_leaders" -gt 0 ]]; then
        local ideal_per_broker=$((leader_count / unique_leaders))
        local max_count
        max_count=$(echo "$broker_counts" | head -1 | awk '{print $1}')
        local min_count
        min_count=$(echo "$broker_counts" | tail -1 | awk '{print $1}')
        
        echo "=== Distribution Analysis ==="
        echo "Total partitions: $leader_count"
        echo "Brokers with leadership: $unique_leaders"
        echo "Ideal partitions per broker: ~$ideal_per_broker"
        echo "Max partitions on a broker: $max_count"
        echo "Min partitions on a broker: $min_count"
        
        if [[ $((max_count - min_count)) -gt 2 ]]; then
            echo ""
            log "WARNING: Leader distribution may be imbalanced"
        else
            echo ""
            log "Leader distribution looks balanced"
        fi
    fi
}

main() {
    parse_args "$@"
    validate_prerequisites

    if ! topic_exists; then
        die "Topic does not exist: $TOPIC"
    fi

    echo "========================================"
    echo "Kafka Partition Management"
    echo "========================================"
    echo "Bootstrap: $BOOTSTRAP_SERVER"
    echo "Topic: $TOPIC"
    echo "Time: $(date -Iseconds)"
    echo ""

    case "$ACTION" in
        describe)
            describe_partitions
            ;;
        increase)
            increase_partitions
            ;;
        verify)
            verify_partition_distribution
            ;;
        *)
            die "No action specified. Use --describe, --increase, or --verify"
            ;;
    esac
}

main "$@"
