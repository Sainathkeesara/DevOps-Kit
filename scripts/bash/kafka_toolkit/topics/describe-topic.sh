#!/usr/bin/env bash
#
# PURPOSE: Get detailed information about a Kafka topic including partitions, replicas, and configs
# USAGE: ./describe-topic.sh <topic-name> [--bootstrap-server <host:port>] [--json]
# REQUIREMENTS: Kafka client tools (kafka-topics.sh) in PATH
# SAFETY: Read-only operation, safe to run anytime
#
# EXAMPLES:
#   ./describe-topic.sh my-topic
#   ./describe-topic.sh my-topic --json                    # Output as JSON-like format
#   ./describe-topic.sh my-topic --bootstrap-server kafka:9092

set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
TOPIC_NAME=""
JSON_OUTPUT=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
            --json) JSON_OUTPUT=1 ;;
            -h|--help) usage ;;
            -*)
                if [[ -z "$TOPIC_NAME" ]]; then
                    log_error "Topic name must be specified before options"
                    usage
                fi
                log_error "Unknown option: $1"
                usage
                ;;
            *)
                if [[ -z "$TOPIC_NAME" ]]; then
                    TOPIC_NAME="$1"
                else
                    log_error "Multiple topic names provided"
                    usage
                fi
                ;;
        esac
        shift
    done
}

check_kafka_tools() {
    if ! command -v kafka-topics.sh >/dev/null 2>&1; then
        log_error "kafka-topics.sh not found in PATH"
        exit 1
    fi
}

validate_topic() {
    if [[ -z "$TOPIC_NAME" ]]; then
        log_error "Topic name is required"
        usage
    fi
    
    if ! kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --list 2>/dev/null | grep -qx "$TOPIC_NAME"; then
        log_error "Topic '$TOPIC_NAME' does not exist"
        exit 1
    fi
}

print_summary() {
    local desc
    desc=$(kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --describe --topic "$TOPIC_NAME" 2>/dev/null)
    
    local partition_count
    partition_count=$(echo "$desc" | grep -c "^Topic: $TOPIC_NAME" || echo "0")
    
    local rf_line
    rf_line=$(echo "$desc" | grep "ReplicationFactor:" | head -1)
    local replication_factor
    replication_factor=$(echo "$rf_line" | grep -oP 'ReplicationFactor: \K[0-9]+' || echo "-")
    
    echo ""
    echo -e "${BLUE}=== Topic Summary: $TOPIC_NAME ===${NC}"
    echo "  Bootstrap Server: $BOOTSTRAP_SERVER"
    echo "  Partitions: $partition_count"
    echo "  Replication Factor: $replication_factor"
    echo ""
}

print_partition_details() {
    local desc
    desc=$(kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --describe --topic "$TOPIC_NAME" 2>/dev/null)
    
    echo -e "${BLUE}=== Partition Details ===${NC}"
    printf "%-12s %-8s %-20s %-30s %-30s\n" "Partition" "Leader" "Replicas" "ISR" "Offline"
    printf "%.0s-" {1..100}; echo
    
    echo "$desc" | grep "^Topic: $TOPIC_NAME" | while read -r line; do
        local partition leader replicas isr offline
        partition=$(echo "$line" | grep -oP 'Partition: \K[0-9]+' || echo "-")
        leader=$(echo "$line" | grep -oP 'Leader: \K[0-9]+' || echo "none")
        replicas=$(echo "$line" | grep -oP 'Replicas: \K[0-9,]+' || echo "-")
        isr=$(echo "$line" | grep -oP 'Isr: \K[0-9,]+' || echo "-")
        offline=$(echo "$line" | grep -oP 'Offline: \K[0-9,]*' || echo "-")
        
        if [[ "$leader" == "none" ]]; then
            printf "%-12s ${RED}%-8s${NC} %-20s %-30s %-30s\n" "$partition" "$leader" "$replicas" "$isr" "$offline"
        else
            printf "%-12s %-8s %-20s %-30s %-30s\n" "$partition" "$leader" "$replicas" "$isr" "$offline"
        fi
    done
    echo ""
}

print_configs() {
    local desc
    desc=$(kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --describe --topic "$TOPIC_NAME" 2>/dev/null)
    
    local configs
    configs=$(echo "$desc" | grep "Configs:" | head -1 | cut -d':' -f4- | tr ',' '\n' | grep -v '^$' || true)
    
    echo -e "${BLUE}=== Configuration ===${NC}"
    if [[ -n "$configs" ]]; then
        echo "$configs" | while read -r config; do
            echo "  $config"
        done
    else
        echo "  (no custom configurations)"
    fi
    echo ""
}

print_json_output() {
    local desc
    desc=$(kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --describe --topic "$TOPIC_NAME" 2>/dev/null)
    
    local partition_count
    partition_count=$(echo "$desc" | grep -c "^Topic: $TOPIC_NAME" || echo "0")
    
    local rf_line
    rf_line=$(echo "$desc" | grep "ReplicationFactor:" | head -1)
    local replication_factor
    replication_factor=$(echo "$rf_line" | grep -oP 'ReplicationFactor: \K[0-9]+' || echo "null")
    
    echo "{"
    echo "  \"topic\": \"$TOPIC_NAME\","
    echo "  \"bootstrapServer\": \"$BOOTSTRAP_SERVER\","
    echo "  \"partitionCount\": $partition_count,"
    echo "  \"replicationFactor\": $replication_factor,"
    echo "  \"partitions\": ["
    
    local first=1
    echo "$desc" | grep "^Topic: $TOPIC_NAME" | while read -r line; do
        local partition leader replicas isr
        partition=$(echo "$line" | grep -oP 'Partition: \K[0-9]+' || echo "null")
        leader=$(echo "$line" | grep -oP 'Leader: \K[0-9]+' || echo "null")
        replicas=$(echo "$line" | grep -oP 'Replicas: \K[0-9,]+' || echo "")
        isr=$(echo "$line" | grep -oP 'Isr: \K[0-9,]+' || echo "")
        
        [[ $first -eq 0 ]] && echo ","
        first=0
        
        echo -n "    {\"partition\": $partition, \"leader\": $leader, \"replicas\": \"$replicas\", \"isr\": \"$isr\"}"
    done
    
    echo ""
    echo "  ]"
    echo "}"
}

main() {
    parse_args "$@"
    check_kafka_tools
    validate_topic
    
    if [[ $JSON_OUTPUT -eq 1 ]]; then
        print_json_output
    else
        print_summary
        print_partition_details
        print_configs
    fi
}

main "$@"
