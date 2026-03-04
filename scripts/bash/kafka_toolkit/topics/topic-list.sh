#!/usr/bin/env bash
#
# Purpose: List and describe Kafka topics with filtering options
# Usage: ./topic-list.sh [--bootstrap-server localhost:9092] [--pattern '*'] [--describe]
# Requirements: kafka-topics.sh in PATH, connectivity to Kafka cluster
# Safety: Read-only by default; use --describe for detailed info

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Defaults
BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
PATTERN="*"
DESCRIBE=false
VERBOSE=false
COMMAND_CONFIG=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

List and describe Kafka topics with optional filtering.

OPTIONS:
    -b, --bootstrap-server SERVER   Kafka bootstrap server (default: localhost:9092)
    -p, --pattern PATTERN           Topic name pattern (default: *)
    -d, --describe                  Show detailed topic description
    -c, --command-config FILE       Properties file for client configuration
    -v, --verbose                   Enable verbose output
    -h, --help                      Show this help message

ENVIRONMENT:
    KAFKA_BOOTSTRAP_SERVER          Default bootstrap server

EXAMPLES:
    $(basename "$0")
    $(basename "$0") -b kafka.example.com:9092 -p "prod-*"
    $(basename "$0") -d -p "critical-topic"
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
            -p|--pattern)
                PATTERN="$2"
                shift 2
                ;;
            -d|--describe)
                DESCRIBE=true
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
    if ! command -v kafka-topics.sh &>/dev/null; then
        die "kafka-topics.sh not found. Ensure Kafka bin/ is in PATH."
    fi

    if [[ -n "$COMMAND_CONFIG" && ! -f "$COMMAND_CONFIG" ]]; then
        die "Command config file not found: $COMMAND_CONFIG"
    fi
}

cmd_base() {
    local cmd="kafka-topics.sh --bootstrap-server $BOOTSTRAP_SERVER"
    if [[ -n "$COMMAND_CONFIG" ]]; then
        cmd="$cmd --command-config $COMMAND_CONFIG"
    fi
    echo "$cmd"
}

list_topics() {
    local cmd
    cmd=$(cmd_base)
    cmd="$cmd --list"

    [[ "$VERBOSE" == true ]] && log "Executing: $cmd"

    if [[ "$PATTERN" == "*" ]]; then
        eval "$cmd" 2>/dev/null || die "Failed to list topics. Check connectivity to $BOOTSTRAP_SERVER"
    else
        eval "$cmd" 2>/dev/null | grep -E "^${PATTERN//\*/.*}$" || true
    fi
}

describe_topics() {
    local topics
    topics=$(list_topics)

    if [[ -z "$topics" ]]; then
        log "No topics matching pattern: $PATTERN"
        return 0
    fi

    local cmd
    cmd=$(cmd_base)

    echo "$topics" | while IFS= read -r topic; do
        [[ -z "$topic" ]] && continue
        echo ""
        echo "=== Topic: $topic ==="
        eval "$cmd --describe --topic '$topic'" 2>/dev/null || error "Failed to describe topic: $topic"
    done
}

show_summary() {
    local topics
    topics=$(list_topics)
    local count
    count=$(echo "$topics" | grep -c '^' || true)

    echo ""
    echo "=== Summary ==="
    echo "Bootstrap Server: $BOOTSTRAP_SERVER"
    echo "Pattern: $PATTERN"
    echo "Topics Found: $count"
    echo ""
}

main() {
    parse_args "$@"
    validate_prerequisites

    log "Listing topics from: $BOOTSTRAP_SERVER"

    if [[ "$DESCRIBE" == true ]]; then
        describe_topics
    else
        list_topics
    fi

    show_summary
}

main "$@"
