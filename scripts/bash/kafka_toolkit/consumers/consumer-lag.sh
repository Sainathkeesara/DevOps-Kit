#!/usr/bin/env bash
#
# Purpose: Monitor Kafka consumer lag with threshold alerts
# Usage: ./consumer-lag.sh --group group-name [--threshold N] [--watch]
# Requirements: kafka-consumer-groups.sh in PATH
# Safety: Read-only operation; safe for monitoring

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
GROUP=""
THRESHOLD=0
WATCH_MODE=false
VERBOSE=false
COMMAND_CONFIG=""
OUTPUT_FORMAT="table"

usage() {
    cat <<EOF
Usage: $(basename "$0") --group GROUP [OPTIONS]

Monitor Kafka consumer lag with threshold alerts.

REQUIRED:
    -g, --group GROUP          Consumer group name to monitor

OPTIONS:
    -b, --bootstrap-server     Kafka bootstrap server (default: localhost:9092)
    -t, --threshold N          Alert threshold for total lag (default: 0)
    -w, --watch               Continuously monitor with interval
    -i, --interval SEC        Watch interval in seconds (default: 10)
    -f, --format FORMAT       Output format: table|json (default: table)
    -c, --command-config FILE Properties file for client configuration
    -v, --verbose             Enable verbose output
    -h, --help                Show this help message

EXAMPLES:
    $(basename "$0") --group order-processor
    $(basename "$0") -g my-group -t 1000
    $(basename "$0") -g my-group -w -i 30
    $(basename "$0") -g my-group -f json

OUTPUT COLUMNS:
    TOPIC           - Topic name
    PARTITION       - Partition number
    CURRENT-OFFSET  - Last committed offset
    LOG-END-OFFSET  - Latest available offset
    LAG             - Messages behind (highlighted if > threshold)
    CONSUMER-ID     - Consumer identifier
    HOST            - Consumer host
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
            -g|--group)
                GROUP="$2"
                shift 2
                ;;
            -b|--bootstrap-server)
                BOOTSTRAP_SERVER="$2"
                shift 2
                ;;
            -t|--threshold)
                THRESHOLD="$2"
                shift 2
                ;;
            -w|--watch)
                WATCH_MODE=true
                shift
                ;;
            -i|--interval)
                INTERVAL="$2"
                shift 2
                ;;
            -f|--format)
                OUTPUT_FORMAT="$2"
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
    if ! command -v kafka-consumer-groups.sh &>/dev/null; then
        die "kafka-consumer-groups.sh not found. Ensure Kafka bin/ is in PATH."
    fi

    [[ -z "$GROUP" ]] && die "Consumer group is required (--group)"
}

get_lag_data() {
    local cmd="kafka-consumer-groups.sh --bootstrap-server $BOOTSTRAP_SERVER --describe --group $GROUP"
    if [[ -n "$COMMAND_CONFIG" ]]; then
        cmd="$cmd --command-config $COMMAND_CONFIG"
    fi

    eval "$cmd" 2>/dev/null || die "Failed to get consumer group info for: $GROUP"
}

calculate_total_lag() {
    get_lag_data | awk 'NR>3 && $1 != "" && $1 != "GROUP" && $5 ~ /^[0-9]+$/ {sum+=$5} END {print sum+0}'
}

print_table() {
    local data
    data=$(get_lag_data)
    
    echo ""
    echo "Consumer Group: $GROUP | Bootstrap: $BOOTSTRAP_SERVER"
    echo "================================================================================"
    
    local header
    header=$(echo "$data" | head -3 | tail -1)
    echo "$header" | awk '{printf "%-30s %-10s %-15s %-15s %-10s %-30s %s\n", $1, $2, $3, $4, $5, $6, $7}'
    echo "----------------------------------------------------------------------------------------------------------"
    
    local total_lag=0
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^GROUP|^TOPIC|^$ ]] && continue
        
        local topic partition current_offset log_end_offset lag consumer_id host
        topic=$(echo "$line" | awk '{print $1}')
        partition=$(echo "$line" | awk '{print $2}')
        current_offset=$(echo "$line" | awk '{print $3}')
        log_end_offset=$(echo "$line" | awk '{print $4}')
        lag=$(echo "$line" | awk '{print $5}')
        consumer_id=$(echo "$line" | awk '{print $6}')
        host=$(echo "$line" | awk '{print $7}')
        
        [[ -z "$topic" ]] && continue
        
        if [[ "$lag" =~ ^[0-9]+$ ]]; then
            total_lag=$((total_lag + lag))
        fi
        
        if [[ "$lag" -gt "$THRESHOLD" ]]; then
            printf "%-30s %-10s %-15s %-15s \033[31m%-10s\033[0m %-30s %s\n" \
                "$topic" "$partition" "$current_offset" "$log_end_offset" "$lag" "$consumer_id" "$host"
        else
            printf "%-30s %-10s %-15s %-15s %-10s %-30s %s\n" \
                "$topic" "$partition" "$current_offset" "$log_end_offset" "$lag" "$consumer_id" "$host"
        fi
    done <<< "$data"
    
    echo "================================================================================"
    echo "Total Lag: $total_lag"
    
    if [[ "$total_lag" -gt "$THRESHOLD" ]]; then
        echo ""
        echo "WARNING: Total lag ($total_lag) exceeds threshold ($THRESHOLD)"
    fi
}

print_json() {
    local data
    data=$(get_lag_data)
    
    echo "{"
    echo "  \"group\": \"$GROUP\","
    echo "  \"bootstrap_server\": \"$BOOTSTRAP_SERVER\","
    echo "  \"timestamp\": \"$(date -Iseconds)\","
    echo "  \"partitions\": ["
    
    local first=true
    local total_lag=0
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^GROUP|^TOPIC|^$ ]] && continue
        
        local topic partition current_offset log_end_offset lag consumer_id host
        topic=$(echo "$line" | awk '{print $1}')
        partition=$(echo "$line" | awk '{print $2}')
        current_offset=$(echo "$line" | awk '{print $3}')
        log_end_offset=$(echo "$line" | awk '{print $4}')
        lag=$(echo "$line" | awk '{print $5}')
        consumer_id=$(echo "$line" | awk '{print $6}')
        host=$(echo "$line" | awk '{print $7}')
        
        [[ -z "$topic" ]] && continue
        
        if [[ "$lag" =~ ^[0-9]+$ ]]; then
            total_lag=$((total_lag + lag))
        fi
        
        if [[ "$first" == true ]]; then
            first=false
        else
            echo ","
        fi
        
        echo "    {"
        echo "      \"topic\": \"$topic\","
        echo "      \"partition\": $partition,"
        echo "      \"current_offset\": ${current_offset:--1},"
        echo "      \"log_end_offset\": ${log_end_offset:--1},"
        echo "      \"lag\": ${lag:--1},"
        echo "      \"consumer_id\": \"${consumer_id:--}\","
        echo "      \"host\": \"${host:--}\""
        echo -n "    }"
    done <<< "$data"
    
    echo ""
    echo "  ],"
    echo "  \"total_lag\": $total_lag"
    echo "}"
}

watch_mode() {
    INTERVAL="${INTERVAL:-10}"
    
    while true; do
        clear
        log "Monitoring consumer group: $GROUP (threshold: $THRESHOLD, interval: ${INTERVAL}s)"
        
        if [[ "$OUTPUT_FORMAT" == "json" ]]; then
            print_json
        else
            print_table
        fi
        
        if [[ "$total_lag" -gt "$THRESHOLD" ]]; then
            echo ""
            error "ALERT: Lag exceeds threshold!"
        fi
        
        sleep "$INTERVAL"
    done
}

main() {
    INTERVAL=10
    
    parse_args "$@"
    validate_prerequisites
    
    local total_lag
    total_lag=$(calculate_total_lag)
    
    if [[ "$WATCH_MODE" == true ]]; then
        watch_mode
    else
        if [[ "$OUTPUT_FORMAT" == "json" ]]; then
            print_json
        else
            print_table
        fi
        
        if [[ "$total_lag" -gt "$THRESHOLD" ]]; then
            exit 1
        fi
    fi
}

main "$@"
