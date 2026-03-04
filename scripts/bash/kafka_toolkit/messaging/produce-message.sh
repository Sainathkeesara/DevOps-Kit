#!/usr/bin/env bash
#
# Purpose: Produce test messages to a Kafka topic
# Usage: ./produce-message.sh -t topic [-m "message"] [-f file] [--stdin]
# Requirements: kafka-console-producer.sh in PATH
# Safety: Validates input; shows sample before producing from file

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Defaults
BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
TOPIC=""
MESSAGE=""
FILE=""
USE_STDIN=false
KEY=""
PROPERTIES=()
VERBOSE=false
COMMAND_CONFIG=""

usage() {
    cat <<EOF
Usage: $(basename "$0") -t TOPIC [OPTIONS]

Produce messages to a Kafka topic.

REQUIRED:
    -t, --topic TOPIC               Target topic name

INPUT OPTIONS (one required):
    -m, --message TEXT              Single message text
    -f, --file FILE                 Read messages from file (one per line)
    -s, --stdin                     Read messages from stdin

OPTIONS:
    -b, --bootstrap-server SERVER   Kafka bootstrap server
    -k, --key KEY                   Message key (for single message)
    -p, --property PROP             Producer property (can repeat)
    -c, --command-config FILE       Properties file for client config
    -v, --verbose                   Enable verbose output
    -h, --help                      Show this help message

EXAMPLES:
    $(basename "$0") -t events -m "test message"
    $(basename "$0") -t events -k "user123" -m "login event"
    echo "message" | $(basename "$0") -t events -s
    $(basename "$0") -t events -f messages.txt

PROPERTIES:
    acks=all
    retries=3
    compression.type=snappy
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
            -m|--message)
                MESSAGE="$2"
                shift 2
                ;;
            -f|--file)
                FILE="$2"
                shift 2
                ;;
            -s|--stdin)
                USE_STDIN=true
                shift
                ;;
            -b|--bootstrap-server)
                BOOTSTRAP_SERVER="$2"
                shift 2
                ;;
            -k|--key)
                KEY="$2"
                shift 2
                ;;
            -p|--property)
                PROPERTIES+=("$2")
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
    if ! command -v kafka-console-producer.sh &>/dev/null; then
        die "kafka-console-producer.sh not found. Ensure Kafka bin/ is in PATH."
    fi

    [[ -z "$TOPIC" ]] && die "Topic name is required (-t)"

    local input_count=0
    [[ -n "$MESSAGE" ]] && ((input_count++))
    [[ -n "$FILE" ]] && ((input_count++))
    [[ "$USE_STDIN" == true ]] && ((input_count++))

    if [[ $input_count -eq 0 ]]; then
        die "Input required: use -m, -f, or -s"
    fi

    if [[ $input_count -gt 1 ]]; then
        die "Only one input method allowed (-m, -f, or -s)"
    fi

    if [[ -n "$FILE" && ! -f "$FILE" ]]; then
        die "File not found: $FILE"
    fi

    if [[ -n "$COMMAND_CONFIG" && ! -f "$COMMAND_CONFIG" ]]; then
        die "Command config file not found: $COMMAND_CONFIG"
    fi
}

build_base_cmd() {
    local cmd="kafka-console-producer.sh --bootstrap-server $BOOTSTRAP_SERVER --topic $TOPIC"

    if [[ -n "$COMMAND_CONFIG" ]]; then
        cmd="$cmd --producer.config $COMMAND_CONFIG"
    fi

    for prop in "${PROPERTIES[@]}"; do
        cmd="$cmd --property $prop"
    done

    echo "$cmd"
}

produce_single() {
    local cmd
    cmd=$(build_base_cmd)

    if [[ -n "$KEY" ]]; then
        cmd="$cmd --property parse.key=true --property key.separator=,:"
        echo "$KEY:$MESSAGE" | eval "$cmd"
    else
        echo "$MESSAGE" | eval "$cmd"
    fi
}

produce_from_file() {
    local cmd
    cmd=$(build_base_cmd)

    log "Producing messages from: $FILE"
    local count
    count=$(wc -l < "$FILE" | tr -d ' ')
    log "Message count: $count"

    # Show sample
    echo "Sample (first 3 lines):"
    head -3 "$FILE" | sed 's/^/  /'
    echo ""

    eval "$cmd" < "$FILE"
}

produce_from_stdin() {
    local cmd
    cmd=$(build_base_cmd)

    log "Reading messages from stdin (Ctrl+D to finish)..."
    eval "$cmd"
}

main() {
    parse_args "$@"
    validate_prerequisites

    log "Producing to topic: $TOPIC"

    if [[ -n "$MESSAGE" ]]; then
        produce_single
    elif [[ -n "$FILE" ]]; then
        produce_from_file
    elif [[ "$USE_STDIN" == true ]]; then
        produce_from_stdin
    fi

    log "Producer completed"
}

main "$@"
