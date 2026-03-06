#!/usr/bin/env bash
#
# Purpose: View and modify Kafka topic configurations with validation
# Usage: ./topic-config.sh --topic NAME [--get | --set key=value | --delete key]
# Requirements: kafka-configs.sh in PATH, connectivity to Kafka cluster
# Safety: Dry-run for modifications; validates config keys

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Defaults
BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
TOPIC=""
ACTION=""
CONFIG_KEY=""
CONFIG_VALUE=""
DRY_RUN=true
VERBOSE=false
COMMAND_CONFIG=""

# Valid Kafka topic config keys
VALID_CONFIG_KEYS=(
    "cleanup.policy"
    "compression.type"
    "delete.retention.ms"
    "file.delete.delay.ms"
    "flush.messages"
    "flush.ms"
    "follower.replication.throttled.replicas"
    "index.interval.bytes"
    "leader.replication.throttled.replicas"
    "max.compaction.lag.ms"
    "max.message.bytes"
    "message.downconversion.enable"
    "message.format.version"
    "message.timestamp.difference.max.ms"
    "message.timestamp.type"
    "min.cleanable.dirty.ratio"
    "min.compaction.lag.ms"
    "min.insync.replicas"
    "preallocate"
    "retention.bytes"
    "retention.ms"
    "segment.bytes"
    "segment.index.bytes"
    "segment.jitter.ms"
    "segment.ms"
    "unclean.leader.election.enable"
)

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

View and modify Kafka topic configurations.

ACTIONS:
    -g, --get                       Get current topic configuration
    -s, --set KEY=VALUE             Set a configuration value
    -d, --delete KEY                Delete a configuration value (reset to default)
    -l, --list-valid                List all valid configuration keys

OPTIONS:
    -t, --topic TOPIC               Topic name (required)
    -b, --bootstrap-server SERVER   Kafka bootstrap server (default: localhost:9092)
    -c, --command-config FILE       Properties file for client configuration
    -n, --dry-run                   Show what would be changed (default)
    -e, --execute                   Execute modification (required for set/delete)
    -v, --verbose                   Enable verbose output
    -h, --help                      Show this help message

EXAMPLES:
    $(basename "$0") -t events -g
    $(basename "$0") -t events -s retention.ms=604800000 -e
    $(basename "$0") -t events -s min.insync.replicas=2 -s compression.type=snappy -e
    $(basename "$0") -t events -d retention.bytes -e
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
            -g|--get)
                ACTION="get"
                shift
                ;;
            -s|--set)
                ACTION="set"
                if [[ "$2" != *"="* ]]; then
                    die "Invalid format for --set. Use KEY=VALUE"
                fi
                CONFIG_KEY="${2%%=*}"
                CONFIG_VALUE="${2#*=}"
                shift 2
                ;;
            -d|--delete)
                ACTION="delete"
                CONFIG_KEY="$2"
                shift 2
                ;;
            -l|--list-valid)
                ACTION="list_valid"
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -e|--execute)
                DRY_RUN=false
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
    if ! command -v kafka-configs.sh &>/dev/null; then
        die "kafka-configs.sh not found. Ensure Kafka bin/ is in PATH."
    fi

    if [[ -z "$TOPIC" && "$ACTION" != "list_valid" ]]; then
        die "Topic name required (-t TOPIC)"
    fi

    if [[ -n "$COMMAND_CONFIG" && ! -f "$COMMAND_CONFIG" ]]; then
        die "Command config file not found: $COMMAND_CONFIG"
    fi

    if [[ "$ACTION" == "set" && -z "$CONFIG_KEY" ]]; then
        die "Configuration key required for --set"
    fi

    if [[ "$ACTION" == "delete" && -z "$CONFIG_KEY" ]]; then
        die "Configuration key required for --delete"
    fi
}

cmd_base() {
    local cmd="kafka-configs.sh --bootstrap-server $BOOTSTRAP_SERVER"
    if [[ -n "$COMMAND_CONFIG" ]]; then
        cmd="$cmd --command-config $COMMAND_CONFIG"
    fi
    echo "$cmd"
}

is_valid_config_key() {
    local key="$1"
    for valid_key in "${VALID_CONFIG_KEYS[@]}"; do
        if [[ "$key" == "$valid_key" ]]; then
            return 0
        fi
    done
    return 1
}

list_valid_keys() {
    echo "Valid Kafka topic configuration keys:"
    echo ""
    printf "  %-40s\n" "${VALID_CONFIG_KEYS[@]}"
    echo ""
    echo "Common configurations:"
    echo "  retention.ms          - Message retention period (default: 604800000 = 7 days)"
    echo "  retention.bytes       - Max bytes to retain (default: -1 = unlimited)"
    echo "  cleanup.policy        - delete or compact (default: delete)"
    echo "  compression.type      - none, gzip, snappy, lz4, zstd"
    echo "  min.insync.replicas   - Minimum in-sync replicas (default: 1)"
    echo "  max.message.bytes     - Max message size (default: 1048576)"
    echo "  segment.ms            - Segment roll time (default: 604800000)"
    echo "  segment.bytes         - Segment size in bytes (default: 1073741824)"
}

get_config() {
    local cmd
    cmd=$(cmd_base)
    cmd="$cmd --entity-type topics --entity-name $TOPIC --describe"

    log "Getting configuration for topic: $TOPIC"
    [[ "$VERBOSE" == true ]] && log "Executing: $cmd"

    echo ""
    echo "=== Topic Configuration: $TOPIC ==="
    eval "$cmd" 2>/dev/null || die "Failed to get topic configuration"
}

set_config() {
    if ! is_valid_config_key "$CONFIG_KEY"; then
        log "WARNING: '$CONFIG_KEY' is not in the standard config keys list"
        log "Proceeding anyway (custom configs may be supported)"
    fi

    local cmd
    cmd=$(cmd_base)
    cmd="$cmd --entity-type topics --entity-name $TOPIC --alter --add-config $CONFIG_KEY=$CONFIG_VALUE"

    if [[ "$DRY_RUN" == true ]]; then
        log "DRY-RUN mode - would execute:"
        echo "  $cmd"
        echo ""
        log "Configuration change:"
        echo "  Topic: $TOPIC"
        echo "  Set: $CONFIG_KEY = $CONFIG_VALUE"
        return 0
    fi

    log "Setting configuration:"
    log "  Topic: $TOPIC"
    log "  $CONFIG_KEY = $CONFIG_VALUE"
    [[ "$VERBOSE" == true ]] && log "Executing: $cmd"

    if eval "$cmd" 2>&1; then
        log "Configuration updated successfully"
    else
        die "Failed to update configuration"
    fi
}

delete_config() {
    local cmd
    cmd=$(cmd_base)
    cmd="$cmd --entity-type topics --entity-name $TOPIC --alter --delete-config $CONFIG_KEY"

    if [[ "$DRY_RUN" == true ]]; then
        log "DRY-RUN mode - would execute:"
        echo "  $cmd"
        echo ""
        log "Configuration change:"
        echo "  Topic: $TOPIC"
        echo "  Delete: $CONFIG_KEY (will reset to default)"
        return 0
    fi

    log "Deleting configuration:"
    log "  Topic: $TOPIC"
    log "  Key: $CONFIG_KEY (will reset to default)"
    [[ "$VERBOSE" == true ]] && log "Executing: $cmd"

    if eval "$cmd" 2>&1; then
        log "Configuration deleted successfully"
    else
        die "Failed to delete configuration"
    fi
}

main() {
    parse_args "$@"
    validate_prerequisites

    if [[ "$ACTION" == "list_valid" ]]; then
        list_valid_keys
        exit 0
    fi

    echo "========================================"
    echo "Kafka Topic Configuration"
    echo "========================================"
    echo "Bootstrap: $BOOTSTRAP_SERVER"
    echo "Topic: $TOPIC"
    echo "Action: $ACTION"
    echo "Time: $(date -Iseconds)"
    echo ""

    case "$ACTION" in
        get)
            get_config
            ;;
        set)
            set_config
            ;;
        delete)
            delete_config
            ;;
        *)
            die "No action specified. Use --get, --set, or --delete"
            ;;
    esac
}

main "$@"
