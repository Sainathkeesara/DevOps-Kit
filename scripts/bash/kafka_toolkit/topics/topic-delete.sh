#!/usr/bin/env bash
#
# Purpose: Safely delete Kafka topics with confirmation and dry-run support
# Usage: ./topic-delete.sh --topic NAME [--dry-run] [--execute]
# Requirements: kafka-topics.sh in PATH, connectivity to Kafka cluster
# Safety: Requires explicit --execute flag; dry-run by default; pattern protection

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Defaults
BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
TOPIC=""
DRY_RUN=true
VERBOSE=false
COMMAND_CONFIG=""
FORCE=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Safely delete Kafka topics with confirmation and dry-run support.

OPTIONS:
    -t, --topic TOPIC               Topic name to delete (required)
    -b, --bootstrap-server SERVER   Kafka bootstrap server (default: localhost:9092)
    -c, --command-config FILE       Properties file for client configuration
    -e, --execute                   Execute deletion (default is dry-run)
    -f, --force                     Skip confirmation prompt
    -v, --verbose                   Enable verbose output
    -h, --help                      Show this help message

SAFETY FEATURES:
    - Dry-run mode by default (shows what would be deleted)
    - Requires explicit --execute flag for actual deletion
    - Confirmation prompt before destructive action
    - Pattern protection (no wildcards allowed)

EXAMPLES:
    $(basename "$0") -t old-topic
    $(basename "$0") -t old-topic -e
    $(basename "$0") -t old-topic -e -f
    $(basename "$0") -t old-topic -b kafka.example.com:9092 -e
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
            -c|--command-config)
                COMMAND_CONFIG="$2"
                shift 2
                ;;
            -e|--execute)
                DRY_RUN=false
                shift
                ;;
            -f|--force)
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

    if [[ -z "$TOPIC" ]]; then
        die "Topic name required (-t TOPIC)"
    fi

    # Pattern protection - no wildcards
    if [[ "$TOPIC" == *"*"* || "$TOPIC" == *"?"* ]]; then
        die "Wildcards not allowed in topic name for safety: $TOPIC"
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

topic_exists() {
    local cmd
    cmd=$(cmd_base)
    
    if eval "$cmd --list 2>/dev/null" | grep -qx "$TOPIC"; then
        return 0
    else
        return 1
    fi
}

get_topic_info() {
    local cmd
    cmd=$(cmd_base)
    eval "$cmd --describe --topic $TOPIC" 2>/dev/null || true
}

check_topic_usage() {
    log "Checking for active consumers on topic: $TOPIC"
    
    if command -v kafka-consumer-groups.sh &>/dev/null; then
        local groups
        groups=$(kafka-consumer-groups.sh --bootstrap-server "$BOOTSTRAP_SERVER" --list 2>/dev/null || true)
        
        if [[ -n "$groups" ]]; then
            log "Found consumer groups (verify none are actively consuming from $TOPIC):"
            echo "$groups" | head -10
            echo ""
        fi
    fi
}

delete_topic() {
    local cmd
    cmd=$(cmd_base)
    cmd="$cmd --delete --topic $TOPIC"

    if [[ "$DRY_RUN" == true ]]; then
        log "DRY-RUN mode - would execute:"
        echo "  $cmd"
        echo ""
        log "Topic to delete: $TOPIC"
        
        if topic_exists; then
            log "Topic exists and will be deleted on actual run"
            echo ""
            get_topic_info
        else
            error "Topic does not exist: $TOPIC"
            return 1
        fi
        return 0
    fi

    # Execution mode
    if [[ "$FORCE" != true ]]; then
        log "WARNING: This will permanently delete topic: $TOPIC"
        read -r -p "Type 'delete' to confirm: " confirm
        if [[ "$confirm" != "delete" ]]; then
            die "Aborted"
        fi
    fi

    log "Deleting topic: $TOPIC"
    [[ "$VERBOSE" == true ]] && log "Executing: $cmd"
    
    if eval "$cmd" 2>&1; then
        log "Topic deleted successfully: $TOPIC"
    else
        die "Failed to delete topic: $TOPIC"
    fi
}

main() {
    parse_args "$@"
    validate_prerequisites

    echo "========================================"
    echo "Kafka Topic Deletion"
    echo "========================================"
    echo "Bootstrap: $BOOTSTRAP_SERVER"
    echo "Topic: $TOPIC"
    echo "Mode: $([ "$DRY_RUN" == true ] && echo "DRY-RUN" || echo "EXECUTE")"
    echo "Time: $(date -Iseconds)"
    echo ""

    if ! topic_exists; then
        error "Topic does not exist: $TOPIC"
        exit 1
    fi

    get_topic_info
    echo ""
    
    if [[ "$DRY_RUN" == false ]]; then
        check_topic_usage
    fi

    delete_topic
}

main "$@"
