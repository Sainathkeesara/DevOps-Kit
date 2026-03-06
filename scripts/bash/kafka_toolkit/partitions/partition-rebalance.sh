#!/usr/bin/env bash
#
# Purpose: Rebalance Kafka partition leadership (preferred replica election)
# Usage: ./partition-rebalance.sh [--topic TOPIC] [--all] [--dry-run]
# Requirements: kafka-leader-election.sh or kafka-preferred-replica-election.sh in PATH
# Safety: Dry-run supported; affects partition leadership but not data

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
TOPIC=""
ALL_PARTITIONS=false
DRY_RUN=true
VERBOSE=false
COMMAND_CONFIG=""
ELECTION_TYPE="preferred"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Rebalance Kafka partition leadership to preferred replicas.

OPTIONS:
    -b, --bootstrap-server     Kafka bootstrap server (default: localhost:9092)
    -t, --topic TOPIC          Specific topic to rebalance (optional)
    -a, --all                  Rebalance all topic partitions
    -e, --election-type        Election type: preferred|unclean (default: preferred)
    -n, --dry-run              Show what would be done (default: true)
    -x, --execute              Execute the rebalancing
    -c, --command-config FILE Properties file for client configuration
    -v, --verbose              Enable verbose output
    -h, --help                 Show this help message

EXAMPLES:
    $(basename "$0") --topic orders
    $(basename "$0") --all
    $(basename "$0") --topic events --execute
    $(basename "$0") --topic logs -v

NOTES:
    - Preferred election moves leadership to the first replica in the partition's replica list
    - Unclean election allows leadership to move to out-of-sync replicas (may lose data)
    - Use --dry-run first to see the impact
    - Leadership changes are instant and do not cause data movement
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
            -b|--bootstrap-server)
                BOOTSTRAP_SERVER="$2"
                shift 2
                ;;
            -t|--topic)
                TOPIC="$2"
                shift 2
                ;;
            -a|--all)
                ALL_PARTITIONS=true
                shift
                ;;
            -e|--election-type)
                ELECTION_TYPE="$2"
                shift 2
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -x|--execute)
                DRY_RUN=false
                shift
                ;;
            -c|--command-config)
                COMMAND_CONFIG="$2"
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
            *)
                die "Unknown option: $1"
                ;;
        esac
    done
}

validate_prerequisites() {
    if ! command -v kafka-leader-election.sh &>/dev/null && \
       ! command -v kafka-preferred-replica-election.sh &>/dev/null; then
        die "kafka-leader-election.sh or kafka-preferred-replica-election.sh not found"
    fi

    if [[ "$ALL_PARTITIONS" == false && -z "$TOPIC" ]]; then
        die "Either --topic or --all is required"
    fi

    if [[ "$ELECTION_TYPE" != "preferred" && "$ELECTION_TYPE" != "unclean" ]]; then
        die "Election type must be 'preferred' or 'unclean'"
    fi
}

find_election_tool() {
    if command -v kafka-leader-election.sh &>/dev/null; then
        echo "kafka-leader-election.sh"
    else
        echo "kafka-preferred-replica-election.sh"
    fi
}

get_partitions_to_rebalance() {
    local tool
    tool=$(find_election_tool)
    
    if [[ "$ALL_PARTITIONS" == true ]]; then
        log "Getting all partitions..."
    else
        log "Getting partitions for topic: $TOPIC"
    fi
}

build_election_command() {
    local tool
    tool=$(find_election_tool)
    
    local cmd
    if [[ "$tool" == "kafka-leader-election.sh" ]]; then
        cmd="kafka-leader-election.sh --bootstrap-server $BOOTSTRAP_SERVER --election-type $ELECTION_TYPE"
        
        if [[ -n "$COMMAND_CONFIG" ]]; then
            cmd="$cmd --command-config $COMMAND_CONFIG"
        fi
        
        if [[ -n "$TOPIC" ]]; then
            local json_file="/tmp/election-${TOPIC}-$$.json"
            cat > "$json_file" <<EOF
{
  "partitions": [
    {
      "topic": "$TOPIC",
      "partition": 0
    }
  ]
}
EOF
            cmd="$cmd --path-to-json-file $json_file"
        else
            cmd="$cmd --all-topic-partitions"
        fi
    else
        cmd="kafka-preferred-replica-election.sh --zookeeper ${ZOOKEEPER_CONNECT:-localhost:2181}"
        
        if [[ -n "$TOPIC" ]]; then
            local json_file="/tmp/election-${TOPIC}-$$.json"
            cat > "$json_file" <<EOF
{
  "partitions": [
    {
      "topic": "$TOPIC",
      "partition": 0
    }
  ]
}
EOF
            cmd="$cmd --path-to-json-file $json_file"
        else
            cmd="$cmd --path-to-json-file /tmp/all-partitions-$$.json"
            kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --list 2>/dev/null | while read -r t; do
                kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --describe --topic "$t" 2>/dev/null | \
                    awk 'NR>3 && $1 != "" {print "{\"topic\":\""$1"\",\"partition\","$2"}"}' | \
                    sed 's/partition/\"partition\":/' >> /tmp/all-partitions-$$.json
            done
        fi
    fi
    
    echo "$cmd"
}

show_current_leadership() {
    echo ""
    echo "Current Partition Leadership:"
    echo "================================================================================"
    
    if [[ -n "$TOPIC" ]]; then
        local cmd="kafka-topics.sh --bootstrap-server $BOOTSTRAP_SERVER --describe --topic $TOPIC"
        if [[ -n "$COMMAND_CONFIG" ]]; then
            cmd="$cmd --command-config $COMMAND_CONFIG"
        fi
        eval "$cmd"
    else
        log "Listing all topics (use --topic for specific topic)..."
    fi
    
    echo "================================================================================"
}

main() {
    parse_args "$@"
    validate_prerequisites

    log "Partition Rebalance Request"
    echo "  Bootstrap: $BOOTSTRAP_SERVER"
    echo "  Election Type: $ELECTION_TYPE"
    echo "  Topic: ${TOPIC:-all}"
    echo "  Dry-run: $DRY_RUN"
    echo ""

    show_current_leadership

    local cmd
    cmd=$(build_election_command)

    if [[ "$DRY_RUN" == true ]]; then
        log "DRY-RUN: Would execute:"
        echo "  $cmd"
        echo ""
        log "To execute rebalancing, run with --execute flag"
        
        if [[ "$ELECTION_TYPE" == "unclean" ]]; then
            error "WARNING: Unclean election may cause data loss!"
            error "Preferred election is recommended for production."
        fi
        
        exit 0
    fi

    if [[ "$ELECTION_TYPE" == "unclean" ]]; then
        error "WARNING: Unclean election may cause data loss!"
        read -r -p "Continue with unclean election? (yes/no): " confirm
        if [[ "$confirm" != "yes" ]]; then
            die "Aborted"
        fi
    fi

    log "Starting partition rebalancing..."
    [[ "$VERBOSE" == true ]] && log "Executing: $cmd"

    if eval "$cmd"; then
        log "Partition rebalancing initiated successfully"
        echo ""
        echo "Leadership changes are applied immediately."
        echo "Verify: kafka-topics.sh --bootstrap-server $BOOTSTRAP_SERVER --describe --topic $TOPIC"
    else
        die "Failed to initiate partition rebalancing"
    fi
}

main "$@"
