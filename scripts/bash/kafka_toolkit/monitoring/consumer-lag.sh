#!/usr/bin/env bash
#
# Purpose: Monitor Kafka consumer lag across groups and topics
# Usage: ./consumer-lag.sh [--group NAME] [--topic NAME] [--threshold N]
# Requirements: kafka-consumer-groups.sh in PATH
# Safety: Read-only operation; generates lag report with alerts

set -euo pipefail

# Defaults
BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
GROUP_FILTER=""
TOPIC_FILTER=""
LAG_THRESHOLD=10000
OUTPUT_FORMAT="table"
COMMAND_CONFIG=""
SORT_BY="lag"
VERBOSE="${KAFKA_VERBOSE:-false}"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Monitor Kafka consumer lag with alerting and reporting.

OPTIONS:
    -b, --bootstrap-server SERVER   Kafka bootstrap server (default: localhost:9092)
    -g, --group GROUP               Filter by consumer group
    -t, --topic TOPIC               Filter by topic
    -T, --threshold N               Lag threshold for warnings (default: 10000)
    -f, --format FORMAT             Output format: table, json, csv (default: table)
    -s, --sort FIELD                Sort by: lag, group, topic (default: lag)
    -c, --command-config FILE       Properties file for client config
    -v, --verbose                   Enable verbose output (also via KAFKA_VERBOSE=true)
    -h, --help                      Show this help message

OUTPUT:
    - Shows consumer group, topic, partition, current offset,
      log end offset, lag, and consumer status
    - Highlights partitions exceeding lag threshold
    - Provides summary statistics

EXAMPLES:
    # Check all consumer groups
    $(basename "$0")

    # Check specific group
    $(basename "$0") -g order-processor

    # Check specific topic across all groups
    $(basename "$0") -t events

    # Alert on lower threshold
    $(basename "$0") -T 5000

    # JSON output for automation
    $(basename "$0") -f json

    # Sort by group name
    $(basename "$0") -s group
EOF
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log_verbose() {
    [[ "$VERBOSE" == "true" ]] && echo "[VERBOSE] $*"
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
            -g|--group)
                GROUP_FILTER="$2"
                shift 2
                ;;
            -t|--topic)
                TOPIC_FILTER="$2"
                shift 2
                ;;
            -T|--threshold)
                LAG_THRESHOLD="$2"
                shift 2
                ;;
            -f|--format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -s|--sort)
                SORT_BY="$2"
                shift 2
                ;;
            -c|--command-config)
                COMMAND_CONFIG="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                export VERBOSE
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
    if ! command -v kafka-consumer-groups.sh &>/dev/null; then
        die "kafka-consumer-groups.sh not found. Ensure Kafka bin/ is in PATH."
    fi

    if [[ -n "$COMMAND_CONFIG" && ! -f "$COMMAND_CONFIG" ]]; then
        die "Command config file not found: $COMMAND_CONFIG"
    fi

    if ! [[ "$LAG_THRESHOLD" =~ ^[0-9]+$ ]]; then
        die "Lag threshold must be a positive integer"
    fi

    local valid_formats=("table" "json" "csv")
    if [[ ! " ${valid_formats[*]} " =~ ${OUTPUT_FORMAT} ]]; then
        die "Invalid format: $OUTPUT_FORMAT. Valid: ${valid_formats[*]}"
    fi

    local valid_sorts=("lag" "group" "topic")
    if [[ ! " ${valid_sorts[*]} " =~ ${SORT_BY} ]]; then
        die "Invalid sort field: $SORT_BY. Valid: ${valid_sorts[*]}"
    fi
}

cmd_base() {
    local cmd="kafka-consumer-groups.sh --bootstrap-server $BOOTSTRAP_SERVER"
    if [[ -n "$COMMAND_CONFIG" ]]; then
        cmd="$cmd --command-config $COMMAND_CONFIG"
    fi
    echo "$cmd"
}

get_consumer_groups() {
    local cmd
    cmd=$(cmd_base)

    if [[ -n "$GROUP_FILTER" ]]; then
        echo "$GROUP_FILTER"
    else
        eval "$cmd --list" 2>/dev/null || true
    fi
}

describe_group() {
    local group="$1"
    local cmd
    cmd=$(cmd_base)

    eval "$cmd --describe --group '$group'" 2>/dev/null || true
}

parse_lag_data() {
    local group="$1"
    local output
    output=$(describe_group "$group")

    # Skip header lines and parse data
    echo "$output" | tail -n +3 | while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        [[ "$line" == "GROUP"* ]] && continue
        [[ "$line" == TOPIC* ]] && continue

        # Parse columns: GROUP TOPIC PARTITION CURRENT-OFFSET LOG-END-OFFSET LAG CONSUMER-ID HOST CLIENT-ID
        local fields
        read -ra fields <<< "$line"

        [[ ${#fields[@]} -lt 7 ]] && continue

        local topic="${fields[1]}"
        local partition="${fields[2]}"
        local current_offset="${fields[3]}"
        local log_end_offset="${fields[4]}"
        local lag="${fields[5]}"

        # Apply topic filter
        if [[ -n "$TOPIC_FILTER" && "$topic" != "$TOPIC_FILTER" ]]; then
            continue
        fi

        # Handle "-" values (no active consumer)
        [[ "$current_offset" == "-" ]] && current_offset=0
        [[ "$log_end_offset" == "-" ]] && log_end_offset=0
        [[ "$lag" == "-" ]] && lag=0

        echo "$group|$topic|$partition|$current_offset|$log_end_offset|$lag"
    done
}

output_table() {
    local data="$1"

    echo ""
    echo "=== Consumer Lag Report ==="
    echo "Bootstrap: $BOOTSTRAP_SERVER"
    [[ -n "$GROUP_FILTER" ]] && echo "Group Filter: $GROUP_FILTER"
    [[ -n "$TOPIC_FILTER" ]] && echo "Topic Filter: $TOPIC_FILTER"
    echo "Lag Threshold: $LAG_THRESHOLD"
    echo ""

    # Header
    printf "%-25s %-30s %-10s %-15s %-15s %-12s %s\n" \
        "GROUP" "TOPIC" "PARTITION" "CURRENT-OFFSET" "LOG-END" "LAG" "STATUS"
    printf "%s\n" "$(printf '=%.0s' {1..130})"

    local total_lag=0
    local partition_count=0
    local high_lag_count=0

    echo "$data" | while IFS='|' read -r group topic partition current_offset log_end lag; do
        [[ -z "$group" ]] && continue

        local status="OK"
        if [[ "$lag" -gt "$LAG_THRESHOLD" ]]; then
            status="⚠ HIGH"
            ((high_lag_count++))
        fi

        printf "%-25s %-30s %-10s %-15s %-15s %-12s %s\n" \
            "$group" "$topic" "$partition" "$current_offset" "$log_end" "$lag" "$status"

        ((partition_count++))
        ((total_lag += lag))
    done

    echo ""
    echo "=== Summary ==="
    echo "Total Partitions: $partition_count"
    echo "Total Lag: $total_lag"
    echo "High Lag Partitions: $high_lag_count"
}

output_json() {
    local data="$1"

    echo "{"
    echo "  \"bootstrap_server\": \"$BOOTSTRAP_SERVER\","
    echo "  \"group_filter\": \"${GROUP_FILTER:-none}\","
    echo "  \"topic_filter\": \"${TOPIC_FILTER:-none}\","
    echo "  \"lag_threshold\": $LAG_THRESHOLD,"
    echo "  \"partitions\": ["

    local first=true
    echo "$data" | while IFS='|' read -r group topic partition current_offset log_end lag; do
        [[ -z "$group" ]] && continue

        [[ "$first" != true ]] && echo ","
        first=false

        local status="ok"
        [[ "$lag" -gt "$LAG_THRESHOLD" ]] && status="high"

        printf '    {"group": "%s", "topic": "%s", "partition": %s, "current_offset": %s, "log_end_offset": %s, "lag": %s, "status": "%s"}' \
            "$group" "$topic" "$partition" "$current_offset" "$log_end" "$lag" "$status"
    done

    echo ""
    echo "  ]"
    echo "}"
}

output_csv() {
    local data="$1"

    echo "group,topic,partition,current_offset,log_end_offset,lag,status"

    echo "$data" | while IFS='|' read -r group topic partition current_offset log_end lag; do
        [[ -z "$group" ]] && continue

        local status="ok"
        [[ "$lag" -gt "$LAG_THRESHOLD" ]] && status="high"

        echo "$group,$topic,$partition,$current_offset,$log_end,$lag,$status"
    done
}

main() {
    parse_args "$@"
    validate_prerequisites

    log "Collecting consumer lag data..."

    local all_data=""
    local groups
    groups=$(get_consumer_groups)

    if [[ -z "$groups" ]]; then
        log "No consumer groups found"
        exit 0
    fi

    for group in $groups; do
        local group_data
        group_data=$(parse_lag_data "$group")
        all_data="${all_data}${group_data}"$'\n'
    done

    # Sort data
    local sorted_data
    case "$SORT_BY" in
        lag)
            sorted_data=$(echo "$all_data" | sort -t'|' -k6 -rn)
            ;;
        group)
            sorted_data=$(echo "$all_data" | sort -t'|' -k1)
            ;;
        topic)
            sorted_data=$(echo "$all_data" | sort -t'|' -k2)
            ;;
    esac

    # Output in requested format
    case "$OUTPUT_FORMAT" in
        table)
            output_table "$sorted_data"
            ;;
        json)
            output_json "$sorted_data"
            ;;
        csv)
            output_csv "$sorted_data"
            ;;
    esac
}

main "$@"
