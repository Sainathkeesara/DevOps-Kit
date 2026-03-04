#!/usr/bin/env bash
#
# PURPOSE: Create a Kafka topic with safe defaults and validation
# USAGE: ./topic-create.sh <topic-name> [--partitions <n>] [--replication-factor <n>] [--bootstrap-server <host:port>] [--dry-run]
# REQUIREMENTS: Kafka client tools (kafka-topics.sh) in PATH, admin permissions
# SAFETY: Validates topic doesn't exist before creation. Dry-run mode available.
#
# EXAMPLES:
#   ./topic-create.sh my-topic                              # Create with defaults (3 partitions, RF 1)
#   ./topic-create.sh my-topic --partitions 6 --replication-factor 3
#   ./topic-create.sh my-topic --dry-run                    # Preview only

set -euo pipefail
IFS=$'\n\t'

BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
TOPIC_NAME=""
PARTITIONS=3
REPLICATION_FACTOR=1
DRY_RUN=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_dry() { echo -e "${BLUE}[DRY-RUN]${NC} $*" >&2; }

usage() {
    grep '^#' "$0" | cut -c4- | head -n 9 | tail -n +3
    exit 1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --bootstrap-server) BOOTSTRAP_SERVER="$2"; shift ;;
            --partitions) PARTITIONS="$2"; shift ;;
            --replication-factor) REPLICATION_FACTOR="$2"; shift ;;
            --dry-run) DRY_RUN=1 ;;
            -h|--help) usage ;;
            -*)
                if [[ -z "$TOPIC_NAME" ]]; then
                    log_error "Topic name must be specified before options"
                    usage
                fi
                log_error "Unknown option: $1"
                usage
                ;;
            *)
                if [[ -z "$TOPIC_NAME" ]]; then
                    TOPIC_NAME="$1"
                else
                    log_error "Multiple topic names provided"
                    usage
                fi
                ;;
        esac
        shift
    done
}

check_kafka_tools() {
    if ! command -v kafka-topics.sh >/dev/null 2>&1; then
        log_error "kafka-topics.sh not found in PATH"
        exit 1
    fi
}

validate_topic_name() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        log_error "Topic name is required"
        usage
    fi
    
    if [[ ${#name} -gt 249 ]]; then
        log_error "Topic name too long (max 249 characters)"
        exit 1
    fi
    
    if [[ ! "$name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        log_error "Topic name contains invalid characters. Use only: a-z, A-Z, 0-9, ., _, -"
        exit 1
    fi
}

check_topic_exists() {
    local name="$1"
    
    if kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --list 2>/dev/null | grep -qx "$name"; then
        return 0
    fi
    return 1
}

get_broker_count() {
    local count
    count=$(kafka-broker-api-versions.sh --bootstrap-server "$BOOTSTRAP_SERVER" 2>/dev/null | grep -c "id: " || echo "1")
    echo "$count"
}

validate_replication_factor() {
    local rf="$1"
    local broker_count
    broker_count=$(get_broker_count)
    
    if [[ "$rf" -gt "$broker_count" ]]; then
        log_warn "Replication factor ($rf) exceeds broker count ($broker_count)"
        log_warn "Setting replication factor to $broker_count"
        REPLICATION_FACTOR=$broker_count
    fi
}

create_topic() {
    local name="$1"
    
    log_info "Creating topic: $name"
    log_info "  Partitions: $PARTITIONS"
    log_info "  Replication Factor: $REPLICATION_FACTOR"
    log_info "  Bootstrap Server: $BOOTSTRAP_SERVER"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_dry "Would execute:"
        log_dry "kafka-topics.sh --bootstrap-server $BOOTSTRAP_SERVER --create --topic $name --partitions $PARTITIONS --replication-factor $REPLICATION_FACTOR"
        return
    fi
    
    if kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" \
        --create \
        --topic "$name" \
        --partitions "$PARTITIONS" \
        --replication-factor "$REPLICATION_FACTOR" \
        --if-not-exists 2>/dev/null; then
        log_info "Topic '$name' created successfully"
        
        log_info "Topic details:"
        kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --describe --topic "$name" 2>/dev/null
    else
        log_error "Failed to create topic '$name'"
        exit 1
    fi
}

main() {
    parse_args "$@"
    check_kafka_tools
    validate_topic_name "$TOPIC_NAME"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_dry "DRY RUN MODE - No changes will be made"
    fi
    
    if check_topic_exists "$TOPIC_NAME"; then
        log_warn "Topic '$TOPIC_NAME' already exists"
        log_info "Use kafka-topics.sh --describe --topic $TOPIC_NAME to view details"
        exit 0
    fi
    
    validate_replication_factor "$REPLICATION_FACTOR"
    create_topic "$TOPIC_NAME"
}

main "$@"
