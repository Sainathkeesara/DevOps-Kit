#!/usr/bin/env bash
#
# Purpose: Check Kafka consumer group lag using kafka-consumer-groups.sh
# Usage: ./check-lag.sh [--group NAME] [--bootstrap-server HOST] [--threshold N]
# Requirements: kafka-consumer-groups.sh in PATH, network access to Kafka
# Safety: Read-only operation - no modifications to offsets or data

set -euo pipefail

BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
GROUP=""
THRESHOLD=10000
COMMAND_CONFIG=""
VERBOSE=false
OUTPUT_FORMAT="table"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Check Kafka consumer group lag with threshold-based alerts.

OPTIONS:
    -b, --bootstrap-server SERVER   Kafka bootstrap server (default: localhost:9092)
    -g, --group GROUP               Consumer group name (optional, lists all if omitted)
    -T, --threshold N               Lag threshold for warning (default: 10000)
    -c, --command-config FILE       Properties file for client config
    -f, --format FORMAT             Output: table, json, csv (default: table)
    -v, --verbose                   Verbose output
    -h, --help                      Show this help

EXAMPLES:
    $(basename "$0")
    $(basename "$0") -g my-consumer-group
    $(basename "$0") -b kafka.example.com:9092 -T 5000
    $(basename "$0") -f json -g processor-group
EOF
}

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
error() { echo "[ERROR] $*" >&2; }
die() { error "$*"; exit 1; }

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -b|--bootstrap-server) BOOTSTRAP_SERVER="$2"; shift 2 ;;
            -g|--group) GROUP="$2"; shift 2 ;;
            -T|--threshold) THRESHOLD="$2"; shift 2 ;;
            -c|--command-config) COMMAND_CONFIG="$2"; shift 2 ;;
            -f|--format) OUTPUT_FORMAT="$2"; shift 2 ;;
            -v|--verbose) VERBOSE=true; shift ;;
            -h|--help) usage; exit 0 ;;
            *) die "Unknown option: $1" ;;
        esac
    done
}

validate_prereqs() {
    command -v kafka-consumer-groups.sh &>/dev/null || \
        die "kafka-consumer-groups.sh not in PATH. Install Kafka and add bin/ to PATH."
    [[ -n "$COMMAND_CONFIG" && ! -f "$COMMAND_CONFIG" ]] && \
        die "Config file not found: $COMMAND_CONFIG"
}

build_cmd() {
    local cmd="kafka-consumer-groups.sh --bootstrap-server $BOOTSTRAP_SERVER"
    [[ -n "$COMMAND_CONFIG" ]] && cmd="$cmd --command-config $COMMAND_CONFIG"
    echo "$cmd"
}

list_groups() {
    local cmd
    cmd=$(build_cmd)
    cmd="$cmd --list"
    [[ "$VERBOSE" == true ]] && log "Running: $cmd"
    eval "$cmd" 2>/dev/null || die "Failed to list consumer groups"
}

get_lag() {
    local group="$1"
    local cmd
    cmd=$(build_cmd)
    cmd="$cmd --describe --group $group"
    [[ "$VERBOSE" == true ]] && log "Running: $cmd"
    eval "$cmd" 2>/dev/null || die "Failed to describe group: $group"
}

parse_lag_output() {
    local group="$1"
    local output
    output=$(get_lag "$group")

    echo "$output" | tail -n +3 | while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        [[ "$line" == "GROUP"* ]] && continue
        [[ "$line" =~ ^TOPIC ]] && continue

        read -ra fields <<< "$line"
        [[ ${#fields[@]} -lt 7 ]] && continue

        local topic="${fields[1]}"
        local partition="${fields[2]}"
        local current_offset="${fields[3]}"
        local log_end_offset="${fields[4]}"
        local lag="${fields[5]}"

        [[ "$current_offset" == "-" ]] && current_offset=0
        [[ "$log_end_offset" == "-" ]] && log_end_offset=0
        [[ "$lag" == "-" ]] && lag=0

        echo "$group|$topic|$partition|$current_offset|$log_end_offset|$lag"
    done
}

output_table() {
    local data="$1"
    echo ""
    echo "=== Consumer Group Lag Report ==="
    echo "Bootstrap: $BOOTSTRAP_SERVER"
    [[ -n "$GROUP" ]] && echo "Group: $GROUP"
    echo "Threshold: $THRESHOLD"
    echo ""
    printf "%-20s %-25s %-10s %-15s %-12s %-10s %s\n" \
        "GROUP" "TOPIC" "PARTITION" "CURRENT-OFFSET" "LOG-END" "LAG" "STATUS"
    printf "%s\n" "$(printf '=%.0s' {1..110})"

    local total_lag=0 partitions=0 high_lag=0

    while IFS='|' read -r grp topic partition current log_end lag; do
        [[ -z "$grp" ]] && continue
        local status="OK"
        if [[ "$lag" -gt "$THRESHOLD" ]]; then
            status="WARN"
            ((high_lag++))
        fi
        printf "%-20s %-25s %-10s %-15s %-12s %-10s %s\n" \
            "$grp" "$topic" "$partition" "$current" "$log_end" "$lag" "$status"
        ((partitions++))
        ((total_lag += lag))
    done <<< "$data"

    echo ""
    echo "=== Summary ==="
    echo "Total partitions: $partitions"
    echo "Total lag: $total_lag"
    echo "Partitions over threshold: $high_lag"

    if [[ "$high_lag" -gt 0 ]]; then
        echo ""
        echo "ACTION REQUIRED: Consumer lag exceeds threshold. Check stuck consumers."
        exit 1
    fi
}

output_json() {
    local data="$1"
    echo "{"
    echo "  \"bootstrap_server\": \"$BOOTSTRAP_SERVER\","
    echo "  \"group\": \"${GROUP:-all}\","
    echo "  \"threshold\": $THRESHOLD,"
    echo "  \"partitions\": ["

    local first=true
    while IFS='|' read -r grp topic partition current log_end lag; do
        [[ -z "$grp" ]] && continue
        [[ "$first" != true ]] && echo ","
        first=false
        local status="ok"
        [[ "$lag" -gt "$THRESHOLD" ]] && status="high"
        printf '    {"group": "%s", "topic": "%s", "partition": %s, "lag": %s, "status": "%s"}' \
            "$grp" "$topic" "$partition" "$lag" "$status"
    done <<< "$data"

    echo ""
    echo "  ]"
    echo "}"
}

output_csv() {
    local data="$1"
    echo "group,topic,partition,current_offset,log_end_offset,lag,status"
    while IFS='|' read -r grp topic partition current log_end lag; do
        [[ -z "$grp" ]] && continue
        local status="ok"
        [[ "$lag" -gt "$THRESHOLD" ]] && status="high"
        echo "$grp,$topic,$partition,$current,$log_end,$lag,$status"
    done <<< "$data"
}

main() {
    parse_args "$@"
    validate_prereqs

    local all_data=""
    local groups

    if [[ -n "$GROUP" ]]; then
        groups="$GROUP"
    else
        log "Fetching consumer groups..."
        groups=$(list_groups)
    fi

    if [[ -z "$groups" ]]; then
        log "No consumer groups found"
        exit 0
    fi

    for grp in $groups; do
        local grp_data
        grp_data=$(parse_lag_output "$grp")
        all_data="${all_data}${grp_data}"$'\n'
    done

    case "$OUTPUT_FORMAT" in
        table) output_table "$all_data" ;;
        json) output_json "$all_data" ;;
        csv) output_csv "$all_data" ;;
    esac
}

main "$@"