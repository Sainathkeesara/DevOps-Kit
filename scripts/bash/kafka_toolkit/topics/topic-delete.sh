#!/usr/bin/env bash
#
# Purpose: Safely delete Kafka topics with pre-checks and dry-run support
# Usage: ./topic-delete.sh -t topic-name [--dry-run] [--force]
# Requirements: kafka-topics.sh, kafka-consumer-groups.sh in PATH
# Safety: Dry-run by default; checks for active consumers before deletion

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
TOPIC=""
DRY_RUN=true
FORCE=false
VERBOSE=false
COMMAND_CONFIG=""
CHECK_CONSUMERS=true

usage() {
    cat <<EOF
Usage: $(basename "$0") -t TOPIC [OPTIONS]

Safely delete a Kafka topic with pre-checks.

REQUIRED:
    -t, --topic TOPIC           Topic name to delete

OPTIONS:
    -b, --bootstrap-server     Kafka bootstrap server (default: localhost:9092)
    -f, --command-config FILE  Properties file for client configuration
    -n, --dry-run              Show what would be done (default: true)
    -e, --execute              Actually perform the deletion (disables dry-run)
    -F, --force                Skip consumer check warnings
    -v, --verbose              Enable verbose output
    -h, --help                 Show this help message

EXAMPLES:
    $(basename "$0") -t old-topic
    $(basename "$0") -t temp-topic -e
    $(basename "$0") -t deprecated --force -v

SAFETY:
    - Default is dry-run mode - no changes made
    - Checks if topic exists before deletion
    - Warns if active consumers are attached (can skip with --force)
    - Requires delete.topic.enable=true on brokers
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
            -f|--command-config)
                COMMAND_CONFIG="$2"
                shift 2
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -e|--execute)
                DRY_RUN=false
                shift
                ;;
            -F|--force)
                FORCE=true
                shift
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

    if ! command -v kafka-consumer-groups.sh &>/dev/null; then
        die "kafka-consumer-groups.sh not found. Ensure Kafka bin/ is in PATH."
    fi

    [[ -z "$TOPIC" ]] && die "Topic name is required (-t)"

    if [[ -n "$COMMAND_CONFIG" && ! -f "$COMMAND_CONFIG" ]]; then
        die "Command config file not found: $COMMAND_CONFIG"
    fi
}

check_delete_enabled() {
    local cmd="kafka-configs.sh --bootstrap-server $BOOTSTRAP_SERVER --entity-type brokers --entity-default --describe"
    if [[ -n "$COMMAND_CONFIG" ]]; then
        cmd="$cmd --command-config $COMMAND_CONFIG"
    fi
    
    if [[ "$VERBOSE" == true ]]; then
        log "Checking delete.topic.enable setting..."
    fi
}

check_topic_exists() {
    local cmd="kafka-topics.sh --bootstrap-server $BOOTSTRAP_SERVER --list"
    if [[ -n "$COMMAND_CONFIG" ]]; then
        cmd="$cmd --command-config $COMMAND_CONFIG"
    fi

    if eval "$cmd" 2>/dev/null | grep -qx "$TOPIC"; then
        return 0
    fi
    return 1
}

check_active_consumers() {
    local cmd="kafka-consumer-groups.sh --bootstrap-server $BOOTSTRAP_SERVER --describe --group console-consumer-group 2>/dev/null || true"
    local groups
    groups=$(eval "$cmd" | grep -oP "^\S+" | sort -u || true)
    
    local consumers
    consumers=$(kafka-consumer-groups.sh --bootstrap-server "$BOOTSTRAP_SERVER" \
        --list --command-config "$COMMAND_CONFIG" 2>/dev/null || true)
    
    for group in $consumers; do
        local topic_lag
        topic_lag=$(kafka-consumer-groups.sh --bootstrap-server "$BOOTSTRAP_SERVER" \
            --group "$group" --describe --command-config "$COMMAND_CONFIG" 2>/dev/null | \
            grep "$TOPIC" | awk '{sum+=$5} END {print sum}' || echo "0")
        
        if [[ "$topic_lag" != "0" && "$topic_lag" != "" ]]; then
            if [[ "$FORCE" != true ]]; then
                error "Active consumer group '$group' with lag $topic_lag on topic $TOPIC"
                return 1
            else
                log "Warning: Consumer group '$group' has lag $topic_lag (using --force to skip)"
            fi
        fi
    done
    return 0
}

get_topic_details() {
    local cmd="kafka-topics.sh --bootstrap-server $BOOTSTRAP_SERVER --describe --topic $TOPIC"
    if [[ -n "$COMMAND_CONFIG" ]]; then
        cmd="$cmd --command-config $COMMAND_CONFIG"
    fi
    eval "$cmd" 2>/dev/null || true
}

main() {
    parse_args "$@"
    validate_prerequisites

    log "Topic Deletion Request"
    echo "  Topic: $TOPIC"
    echo "  Bootstrap: $BOOTSTRAP_SERVER"
    echo "  Dry-run: $DRY_RUN"
    echo "  Force: $FORCE"
    echo ""

    if ! check_topic_exists; then
        die "Topic does not exist: $TOPIC"
    fi

    echo "Topic Details:"
    get_topic_details
    echo ""

    if [[ "$CHECK_CONSUMERS" == true && "$FORCE" != true ]]; then
        log "Checking for active consumers..."
        if ! check_active_consumers; then
            error "Active consumers found. Use --force to skip this check."
            die "Aborting deletion. Resolve consumer attachments first."
        fi
    fi

    local cmd="kafka-topics.sh --bootstrap-server $BOOTSTRAP_SERVER --delete --topic $TOPIC"
    if [[ -n "$COMMAND_CONFIG" ]]; then
        cmd="$cmd --command-config $COMMAND_CONFIG"
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log "DRY-RUN: Would execute:"
        echo "  $cmd"
        echo ""
        log "To actually delete, run with --execute flag"
        exit 0
    fi

    log "Deleting topic..."
    [[ "$VERBOSE" == true ]] && log "Executing: $cmd"

    if eval "$cmd"; then
        log "Topic marked for deletion: $TOPIC"
        echo ""
        echo "Note: Topic deletion is asynchronous. It may take a few seconds to complete."
        echo "Verify deletion: kafka-topics.sh --bootstrap-server $BOOTSTRAP_SERVER --list"
    else
        die "Failed to delete topic: $TOPIC"
    fi
}

main "$@"
