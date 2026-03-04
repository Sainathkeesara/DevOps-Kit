#!/usr/bin/env bash
#
# PURPOSE: Produce and consume test messages to verify topic connectivity
# USAGE: ./test-produce-consume.sh <topic-name> [--bootstrap-server <host:port>] [--messages <n>] [--cleanup]
# REQUIREMENTS: Kafka client tools (kafka-console-producer.sh, kafka-console-consumer.sh) in PATH
# SAFETY: Creates temporary topic if specified topic doesn't exist. Use --cleanup to remove test topic.
#
# EXAMPLES:
#   ./test-produce-consume.sh test-topic                    # Test with default 10 messages
#   ./test-produce-consume.sh test-topic --messages 100     # Test with 100 messages
#   ./test-produce-consume.sh temp-test --cleanup           # Cleanup test topic after

set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
TOPIC_NAME=""
MESSAGE_COUNT=10
CLEANUP=0
TIMEOUT_SEC=30

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

usage() {
    grep '^#' "$0" | cut -c4- | head -n 10 | tail -n +3
    exit 1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --bootstrap-server) BOOTSTRAP_SERVER="$2"; shift ;;
            --messages) MESSAGE_COUNT="$2"; shift ;;
            --cleanup) CLEANUP=1 ;;
            --timeout) TIMEOUT_SEC="$2"; shift ;;
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
    local missing=()
    if ! command -v kafka-console-producer.sh >/dev/null 2>&1; then
        missing+=("kafka-console-producer.sh")
    fi
    if ! command -v kafka-console-consumer.sh >/dev/null 2>&1; then
        missing+=("kafka-console-consumer.sh")
    fi
    if ! command -v kafka-topics.sh >/dev/null 2>&1; then
        missing+=("kafka-topics.sh")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing Kafka tools: ${missing[*]}"
        exit 1
    fi
}

topic_exists() {
    local topic="$1"
    kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --list 2>/dev/null | grep -qx "$topic"
}

create_temp_topic() {
    local topic="$1"
    log_info "Creating temporary topic: $topic"
    kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --create --topic "$topic" --partitions 1 --replication-factor 1 --if-not-exists 2>/dev/null
}

cleanup_topic() {
    local topic="$1"
    log_info "Cleaning up topic: $topic"
    kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --delete --topic "$topic" 2>/dev/null || true
}

produce_messages() {
    local topic="$1"
    local count="$2"
    
    log_info "Producing $count test messages to topic: $topic"
    
    local messages=""
    for i in $(seq 1 "$count"); do
        messages+="test-message-$i-$(date +%s%N)\n"
    done
    
    echo -e "$messages" | kafka-console-producer.sh \
        --bootstrap-server "$BOOTSTRAP_SERVER" \
        --topic "$topic" \
        --property "parse.key=false" 2>/dev/null &
    
    local producer_pid=$!
    sleep 2
    kill $producer_pid 2>/dev/null || true
    wait $producer_pid 2>/dev/null || true
    
    log_info "Produced messages"
}

consume_messages() {
    local topic="$1"
    local expected="$2"
    
    log_info "Consuming messages from topic: $topic (timeout: ${TIMEOUT_SEC}s)"
    
    local consumed_file
    consumed_file=$(mktemp)
    
    timeout "$TIMEOUT_SEC" kafka-console-consumer.sh \
        --bootstrap-server "$BOOTSTRAP_SERVER" \
        --topic "$topic" \
        --from-beginning \
        --max-messages "$expected" \
        --timeout-ms $((TIMEOUT_SEC * 1000)) 2>/dev/null > "$consumed_file" || true
    
    local received
    received=$(wc -l < "$consumed_file" | tr -d ' ')
    
    if [[ "$received" -eq "$expected" ]]; then
        log_info "SUCCESS: Received $received/$expected messages"
        rm -f "$consumed_file"
        return 0
    else
        log_warn "PARTIAL: Received $received/$expected messages"
        rm -f "$consumed_file"
        return 1
    fi
}

main() {
    parse_args "$@"
    
    if [[ -z "$TOPIC_NAME" ]]; then
        log_error "Topic name is required"
        usage
    fi
    
    check_kafka_tools
    
    local created_temp=0
    
    if ! topic_exists "$TOPIC_NAME"; then
        log_warn "Topic '$TOPIC_NAME' does not exist"
        create_temp_topic "$TOPIC_NAME"
        created_temp=1
    fi
    
    produce_messages "$TOPIC_NAME" "$MESSAGE_COUNT"
    sleep 1
    consume_messages "$TOPIC_NAME" "$MESSAGE_COUNT"
    local result=$?
    
    if [[ $CLEANUP -eq 1 ]] || [[ $created_temp -eq 1 ]]; then
        cleanup_topic "$TOPIC_NAME"
    fi
    
    if [[ $result -eq 0 ]]; then
        log_info "Test completed successfully"
        exit 0
    else
        log_error "Test failed"
        exit 1
    fi
}

main "$@"
