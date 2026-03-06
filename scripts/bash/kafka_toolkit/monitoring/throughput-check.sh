#!/usr/bin/env bash
#
# Purpose: Monitor Kafka topic throughput and message rates
# Usage: ./throughput-check.sh [--topic NAME] [--duration N] [--interval N]
# Requirements: kafka-run-class.sh, kafka-consumer-perf-test.sh in PATH
# Safety: Read-only operation; uses short sampling window

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Defaults
BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
TOPIC_FILTER=""
DURATION_SEC=10
INTERVAL_SEC=2
VERBOSE=false
COMMAND_CONFIG=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Monitor Kafka topic throughput and message rates.

OPTIONS:
    -b, --bootstrap-server SERVER   Kafka bootstrap server (default: localhost:9092)
    -t, --topic TOPIC               Filter by topic name
    -d, --duration N                Sampling duration in seconds (default: 10)
    -i, --interval N                Report interval in seconds (default: 2)
    -c, --command-config FILE       Properties file for client config
    -v, --verbose                   Enable verbose output
    -h, --help                      Show this help message

MEASUREMENT METHOD:
    - Uses kafka-consumer-perf-test.sh with --timeout
    - Consumes from latest offset (does not affect consumer groups)
    - Reports messages/sec and bytes/sec

EXAMPLES:
    # Check throughput for all topics (sample)
    $(basename "$0") -d 5

    # Check specific topic
    $(basename "$0") -t events -d 10

    # Longer sampling for accurate baseline
    $(basename "$0") -t high-volume-topic -d 30 -i 5
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
                TOPIC_FILTER="$2"
                shift 2
                ;;
            -d|--duration)
                DURATION_SEC="$2"
                shift 2
                ;;
            -i|--interval)
                INTERVAL_SEC="$2"
                shift 2
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
    if ! command -v kafka-consumer-perf-test.sh &>/dev/null; then
        die "kafka-consumer-perf-test.sh not found. Ensure Kafka bin/ is in PATH."
    fi

    if [[ -n "$COMMAND_CONFIG" && ! -f "$COMMAND_CONFIG" ]]; then
        die "Command config file not found: $COMMAND_CONFIG"
    fi

    if ! [[ "$DURATION_SEC" =~ ^[0-9]+$ ]] || [[ "$DURATION_SEC" -lt 1 ]]; then
        die "Duration must be a positive integer"
    fi

    if ! [[ "$INTERVAL_SEC" =~ ^[0-9]+$ ]] || [[ "$INTERVAL_SEC" -lt 1 ]]; then
        die "Interval must be a positive integer"
    fi
}

get_topics() {
    local cmd="kafka-topics.sh --bootstrap-server $BOOTSTRAP_SERVER --list"
    if [[ -n "$COMMAND_CONFIG" ]]; then
        cmd="$cmd --command-config $COMMAND_CONFIG"
    fi

    if [[ -n "$TOPIC_FILTER" ]]; then
        echo "$TOPIC_FILTER"
    else
        eval "$cmd" 2>/dev/null | head -20 || true
    fi
}

measure_throughput() {
    local topic="$1"
    local timeout_ms=$((DURATION_SEC * 1000))

    local cmd="kafka-consumer-perf-test.sh"
    cmd="$cmd --topic '$topic'"
    cmd="$cmd --bootstrap-server $BOOTSTRAP_SERVER"
    cmd="$cmd --timeout $timeout_ms"
    cmd="$cmd --reporting-interval $((INTERVAL_SEC * 1000))"

    # Use a random group to avoid affecting real consumers
    local random_group
    random_group="throughput-check-$(date +%s)-$$"
    cmd="$cmd --group '$random_group'"

    # Start from latest (don't read historical data)
    cmd="$cmd --from-latest"

    if [[ -n "$COMMAND_CONFIG" ]]; then
        cmd="$cmd --consumer.config $COMMAND_CONFIG"
    fi

    [[ "$VERBOSE" == true ]] && log "Executing: $cmd"

    # Run and capture output
    local output
    output=$(eval "$cmd" 2>&1) || true

    # Parse throughput from output
    # Format: throughput: 1000.00 records/sec, 102400.00 bytes/sec
    local records_sec bytes_sec
    records_sec=$(echo "$output" | grep -oP 'throughput: \K[0-9.]+(?= records/sec)' | tail -1 || echo "0")
    bytes_sec=$(echo "$output" | grep -oP 'throughput: [0-9.]+ records/sec, \K[0-9.]+(?= bytes/sec)' || echo "0")

    echo "$topic|$records_sec|$bytes_sec"
}

format_bytes() {
    local bytes="$1"
    if [[ "$bytes" -ge 1073741824 ]]; then
        echo "$(echo "scale=2; $bytes / 1073741824" | bc) GB/s"
    elif [[ "$bytes" -ge 1048576 ]]; then
        echo "$(echo "scale=2; $bytes / 1048576" | bc) MB/s"
    elif [[ "$bytes" -ge 1024 ]]; then
        echo "$(echo "scale=2; $bytes / 1024" | bc) KB/s"
    else
        echo "$bytes B/s"
    fi
}

output_report() {
    local data="$1"

    echo ""
    echo "=== Kafka Throughput Report ==="
    echo "Bootstrap: $BOOTSTRAP_SERVER"
    [[ -n "$TOPIC_FILTER" ]] && echo "Topic Filter: $TOPIC_FILTER"
    echo "Duration: ${DURATION_SEC}s"
    echo "Interval: ${INTERVAL_SEC}s"
    echo ""

    printf "%-40s %-20s %-20s\n" "TOPIC" "MESSAGES/SEC" "BYTES/SEC"
    printf "%s\n" "$(printf '=%.0s' {1..85})"

    echo "$data" | while IFS='|' read -r topic records_sec bytes_sec; do
        [[ -z "$topic" ]] && continue
        [[ "$records_sec" == "0" || -z "$records_sec" ]] && continue

        local formatted_bytes
        formatted_bytes=$(format_bytes "${bytes_sec%.*}")

        printf "%-40s %-20s %-20s\n" \
            "$topic" \
            "$(printf "%.2f" "$records_sec")" \
            "$formatted_bytes"
    done

    echo ""
    echo "Note: Measurements are from latest offset (no historical data read)"
}

main() {
    parse_args "$@"
    validate_prerequisites

    log "Starting throughput measurement (${DURATION_SEC}s sampling)..."

    local topics
    topics=$(get_topics)

    if [[ -z "$topics" ]]; then
        log "No topics found"
        exit 0
    fi

    local results=""
    for topic in $topics; do
        log "Measuring: $topic"
        local result
        result=$(measure_throughput "$topic")
        results="${results}${result}"$'\n'
    done

    output_report "$results"
}

main "$@"
