#!/usr/bin/env bash
#
# Purpose: Consume messages from Kafka topic with safety limits
# Usage: ./consume-message.sh -t topic [--from-beginning] [--max-messages N] [--timeout N]
# Requirements: kafka-console-consumer.sh in PATH
# Safety: Auto-exits after max-messages or timeout; never commits offsets

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Defaults
BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
TOPIC=""
FROM_BEGINNING=false
MAX_MESSAGES=""
TIMEOUT_SEC=30
GROUP=""
CONSUMER_CONFIG=""
VERBOSE=false
COMMAND_CONFIG=""

usage() {
    cat <<EOF
Usage: $(basename "$0") -t TOPIC [OPTIONS]

Consume messages from a Kafka topic with safety guardrails.

REQUIRED:
    -t, --topic TOPIC               Topic to consume from

OPTIONS:
    -b, --bootstrap-server SERVER   Kafka bootstrap server
    -g, --group GROUP               Consumer group (default: random)
    -f, --from-beginning            Consume from earliest offset
    -m, --max-messages N            Stop after N messages
    -T, --timeout N                 Stop after N seconds (default: 30)
    -c, --consumer-config FILE      Consumer properties file
    -C, --command-config FILE       Admin client config file
    -v, --verbose                   Enable verbose output
    -h, --help                      Show this help message

SAFETY FEATURES:
    - Auto-exits after max-messages (default: no limit, use Ctrl+C)
    - Auto-exits after timeout seconds
    - Uses random group ID unless specified (no offset commits)
    - Read-only operation - does not modify topic

EXAMPLES:
    $(basename "$0") -t events -m 10
    $(basename "$0") -t events -f -m 100 -T 60
    $(basename "$0") -t events -g my-debug-group -f -m 5
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
            -g|--group)
                GROUP="$2"
                shift 2
                ;;
            -f|--from-beginning)
                FROM_BEGINNING=true
                shift
                ;;
            -m|--max-messages)
                MAX_MESSAGES="$2"
                shift 2
                ;;
            -T|--timeout)
                TIMEOUT_SEC="$2"
                shift 2
                ;;
            -c|--consumer-config)
                CONSUMER_CONFIG="$2"
                shift 2
                ;;
            -C|--command-config)
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
    if ! command -v kafka-console-consumer.sh &>/dev/null; then
        die "kafka-console-consumer.sh not found. Ensure Kafka bin/ is in PATH."
    fi

    [[ -z "$TOPIC" ]] && die "Topic name is required (-t)"

    if [[ -n "$CONSUMER_CONFIG" && ! -f "$CONSUMER_CONFIG" ]]; then
        die "Consumer config file not found: $CONSUMER_CONFIG"
    fi

    if [[ -n "$COMMAND_CONFIG" && ! -f "$COMMAND_CONFIG" ]]; then
        die "Command config file not found: $COMMAND_CONFIG"
    fi

    if ! [[ "$TIMEOUT_SEC" =~ ^[0-9]+$ ]] || [[ "$TIMEOUT_SEC" -lt 1 ]]; then
        die "Timeout must be a positive integer"
    fi
}

build_command() {
    local cmd="kafka-console-consumer.sh --bootstrap-server $BOOTSTRAP_SERVER --topic $TOPIC"

    # Use random group ID if not specified (safer for debugging)
    if [[ -n "$GROUP" ]]; then
        cmd="$cmd --group $GROUP"
    else
        local random_group
        random_group="console-consumer-$(date +%s)-$$"
        cmd="$cmd --group $random_group"
    fi

    if [[ "$FROM_BEGINNING" == true ]]; then
        cmd="$cmd --from-beginning"
    fi

    if [[ -n "$MAX_MESSAGES" ]]; then
        cmd="$cmd --max-messages $MAX_MESSAGES"
    fi

    if [[ -n "$CONSUMER_CONFIG" ]]; then
        cmd="$cmd --consumer.config $CONSUMER_CONFIG"
    fi

    if [[ -n "$COMMAND_CONFIG" ]]; then
        cmd="$cmd --consumer.config $COMMAND_CONFIG"
    fi

    # Disable auto-commit for read-only consumption
    cmd="$cmd --property enable.auto.commit=false"

    echo "$cmd"
}

main() {
    parse_args "$@"
    validate_prerequisites

    log "Consuming from topic: $TOPIC"
    echo "  Bootstrap: $BOOTSTRAP_SERVER"
    echo "  From Beginning: $FROM_BEGINNING"
    [[ -n "$MAX_MESSAGES" ]] && echo "  Max Messages: $MAX_MESSAGES"
    echo "  Timeout: ${TIMEOUT_SEC}s"
    echo "  Group: ${GROUP:-(random, read-only)}"
    echo ""

    local cmd
    cmd=$(build_command)

    [[ "$VERBOSE" == true ]] && log "Executing: $cmd"

    # Run with timeout
    timeout "$TIMEOUT_SEC" eval "$cmd" || {
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            log "Consumer timed out after ${TIMEOUT_SEC}s (expected)"
            exit 0
        fi
        die "Consumer failed with exit code: $exit_code"
    }
}

main "$@"
