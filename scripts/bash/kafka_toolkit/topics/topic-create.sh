#!/usr/bin/env bash
#
# Purpose: Create Kafka topic with validation and safety checks
# Usage: ./topic-create.sh -t topic-name -p 6 -r 3 [--dry-run]
# Requirements: kafka-topics.sh in PATH
# Safety: Supports --dry-run; validates parameters before execution

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Defaults
BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
TOPIC=""
PARTITIONS=""
REPLICATION_FACTOR=""
CONFIGS=()
DRY_RUN=false
VERBOSE=false
COMMAND_CONFIG=""
IF_NOT_EXISTS=false

usage() {
    cat <<EOF
Usage: $(basename "$0") -t TOPIC -p PARTITIONS -r REPLICATION_FACTOR [OPTIONS]

Create a Kafka topic with validation and optional dry-run.

REQUIRED:
    -t, --topic TOPIC                 Topic name to create
    -p, --partitions N                Number of partitions
    -r, --replication-factor N        Replication factor

OPTIONS:
    -b, --bootstrap-server SERVER     Kafka bootstrap server (default: localhost:9092)
    -c, --config KEY=VALUE            Topic configuration (can be used multiple times)
    -f, --command-config FILE         Properties file for client configuration
    -i, --if-not-exists               Do not fail if topic already exists
    -n, --dry-run                     Show what would be done without executing
    -v, --verbose                     Enable verbose output
    -h, --help                        Show this help message

EXAMPLES:
    $(basename "$0") -t events -p 6 -r 3
    $(basename "$0") -t logs -p 12 -r 3 -c retention.ms=604800000 -n
    $(basename "$0") -t metrics -p 24 -r 3 -c compression.type=snappy -i

COMMON CONFIGS:
    retention.ms=604800000            (7 days)
    cleanup.policy=delete|compact
    compression.type=snappy|lz4|gzip
    min.insync.replicas=2
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
            -p|--partitions)
                PARTITIONS="$2"
                shift 2
                ;;
            -r|--replication-factor)
                REPLICATION_FACTOR="$2"
                shift 2
                ;;
            -b|--bootstrap-server)
                BOOTSTRAP_SERVER="$2"
                shift 2
                ;;
            -c|--config)
                CONFIGS+=("$2")
                shift 2
                ;;
            -f|--command-config)
                COMMAND_CONFIG="$2"
                shift 2
                ;;
            -i|--if-not-exists)
                IF_NOT_EXISTS=true
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
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

    [[ -z "$TOPIC" ]] && die "Topic name is required (-t)"
    [[ -z "$PARTITIONS" ]] && die "Partition count is required (-p)"
    [[ -z "$REPLICATION_FACTOR" ]] && die "Replication factor is required (-r)"

    if ! [[ "$PARTITIONS" =~ ^[0-9]+$ ]] || [[ "$PARTITIONS" -lt 1 ]]; then
        die "Partitions must be a positive integer"
    fi

    if ! [[ "$REPLICATION_FACTOR" =~ ^[0-9]+$ ]] || [[ "$REPLICATION_FACTOR" -lt 1 ]]; then
        die "Replication factor must be a positive integer"
    fi

    if [[ -n "$COMMAND_CONFIG" && ! -f "$COMMAND_CONFIG" ]]; then
        die "Command config file not found: $COMMAND_CONFIG"
    fi

    # Topic name validation
    if [[ ! "$TOPIC" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        die "Invalid topic name. Use alphanumeric, dots, dashes, underscores only."
    fi
}

build_command() {
    local cmd="kafka-topics.sh --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC"
    cmd="$cmd --partitions $PARTITIONS --replication-factor $REPLICATION_FACTOR"

    if [[ -n "$COMMAND_CONFIG" ]]; then
        cmd="$cmd --command-config $COMMAND_CONFIG"
    fi

    if [[ "$IF_NOT_EXISTS" == true ]]; then
        cmd="$cmd --if-not-exists"
    fi

    for config in "${CONFIGS[@]}"; do
        cmd="$cmd --config $config"
    done

    echo "$cmd"
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

main() {
    parse_args "$@"
    validate_prerequisites

    log "Topic Creation Request"
    echo "  Topic: $TOPIC"
    echo "  Partitions: $PARTITIONS"
    echo "  Replication Factor: $REPLICATION_FACTOR"
    echo "  Bootstrap: $BOOTSTRAP_SERVER"
    [[ ${#CONFIGS[@]} -gt 0 ]] && echo "  Configs: ${CONFIGS[*]}"
    echo ""

    if check_topic_exists; then
        if [[ "$IF_NOT_EXISTS" == true ]]; then
            log "Topic already exists: $TOPIC (skipping due to --if-not-exists)"
            exit 0
        else
            die "Topic already exists: $TOPIC (use --if-not-exists to skip)"
        fi
    fi

    local cmd
    cmd=$(build_command)

    if [[ "$DRY_RUN" == true ]]; then
        log "DRY-RUN: Would execute:"
        echo "  $cmd"
        exit 0
    fi

    log "Creating topic..."
    [[ "$VERBOSE" == true ]] && log "Executing: $cmd"

    if eval "$cmd"; then
        log "Topic created successfully: $TOPIC"
        echo ""
        echo "To verify: kafka-topics.sh --bootstrap-server $BOOTSTRAP_SERVER --describe --topic $TOPIC"
    else
        die "Failed to create topic: $TOPIC"
    fi
}

main "$@"
