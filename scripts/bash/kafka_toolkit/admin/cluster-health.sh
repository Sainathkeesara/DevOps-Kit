#!/usr/bin/env bash
#
# Purpose: Check Kafka cluster health and broker status
# Usage: ./cluster-health.sh [--bootstrap-server localhost:9092]
# Requirements: kafka-broker-api-versions.sh, kafka-metadata-quorum.sh in PATH
# Safety: Read-only operations only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Defaults
BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
VERBOSE=false
COMMAND_CONFIG=""
TIMEOUT=10

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Check Kafka cluster health, broker status, and metadata quorum.

OPTIONS:
    -b, --bootstrap-server SERVER   Kafka bootstrap server (default: localhost:9092)
    -c, --command-config FILE       Properties file for client config
    -t, --timeout N                 Connection timeout seconds (default: 10)
    -v, --verbose                   Enable verbose output
    -h, --help                      Show this help message

EXAMPLES:
    $(basename "$0")
    $(basename "$0") -b kafka.example.com:9092 -t 5
    $(basename "$0") -b kafka1:9092,kafka2:9092 -v

CHECKS PERFORMED:
    - Broker connectivity
    - API versions supported
    - Metadata quorum status (KRaft mode)
    - Controller broker identification
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
            -c|--command-config)
                COMMAND_CONFIG="$2"
                shift 2
                ;;
            -t|--timeout)
                TIMEOUT="$2"
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
    if [[ -n "$COMMAND_CONFIG" && ! -f "$COMMAND_CONFIG" ]]; then
        die "Command config file not found: $COMMAND_CONFIG"
    fi
}

check_broker_connectivity() {
    log "Checking broker connectivity..."

    local first_broker
    first_broker=$(echo "$BOOTSTRAP_SERVER" | cut -d',' -f1)

    if command -v kafka-broker-api-versions.sh &>/dev/null; then
        local cmd="kafka-broker-api-versions.sh --bootstrap-server $BOOTSTRAP_SERVER"
        [[ -n "$COMMAND_CONFIG" ]] && cmd="$cmd --command-config $COMMAND_CONFIG"

        if eval "$cmd" &>/dev/null; then
            log "  ✓ Brokers are reachable"
            return 0
        else
            error "  ✗ Cannot connect to brokers at $BOOTSTRAP_SERVER"
            return 1
        fi
    else
        # Fallback to netcat if available
        if command -v nc &>/dev/null; then
            local host port
            host=$(echo "$first_broker" | cut -d':' -f1)
            port=$(echo "$first_broker" | cut -d':' -f2)

            if timeout "$TIMEOUT" nc -z "$host" "$port" 2>/dev/null; then
                log "  ✓ Broker $host:$port is reachable"
                return 0
            else
                error "  ✗ Cannot connect to $host:$port"
                return 1
            fi
        fi
    fi
}

get_broker_info() {
    log "Retrieving broker information..."

    if ! command -v kafka-broker-api-versions.sh &>/dev/null; then
        log "  kafka-broker-api-versions.sh not available, skipping"
        return 0
    fi

    local cmd="kafka-broker-api-versions.sh --bootstrap-server $BOOTSTRAP_SERVER"
    [[ -n "$COMMAND_CONFIG" ]] && cmd="$cmd --command-config $COMMAND_CONFIG"

    local output
    if output=$(eval "$cmd" 2>/dev/null); then
        local broker_count
        broker_count=$(echo "$output" | grep -c '^[a-zA-Z0-9-]*:[0-9]* ' || true)
        log "  Brokers found: $broker_count"

        if [[ "$VERBOSE" == true ]]; then
            echo ""
            echo "$output" | head -20
            echo ""
        fi
    else
        error "  Failed to retrieve broker info"
    fi
}

check_metadata_quorum() {
    log "Checking metadata quorum (KRaft mode)..."

    if ! command -v kafka-metadata-quorum.sh &>/dev/null; then
        log "  kafka-metadata-quorum.sh not available (pre-KRaft Kafka), skipping"
        return 0
    fi

    local cmd="kafka-metadata-quorum.sh --bootstrap-server $BOOTSTRAP_SERVER"
    [[ -n "$COMMAND_CONFIG" ]] && cmd="$cmd --command-config $COMMAND_CONFIG"

    if eval "$cmd --describe --status" &>/dev/null; then
        log "  ✓ Metadata quorum is healthy"

        if [[ "$VERBOSE" == true ]]; then
            echo ""
            eval "$cmd --describe --status" 2>/dev/null || true
            echo ""
        fi
    else
        error "  ✗ Metadata quorum check failed"
    fi
}

check_controller() {
    log "Identifying controller broker..."

    if ! command -v kafka-metadata-quorum.sh &>/dev/null; then
        # Fallback for older Kafka versions
        if command -v zookeeper-shell.sh &>/dev/null; then
            log "  ZooKeeper mode detected (legacy)"
        fi
        return 0
    fi

    local cmd="kafka-metadata-quorum.sh --bootstrap-server $BOOTSTRAP_SERVER"
    [[ -n "$COMMAND_CONFIG" ]] && cmd="$cmd --command-config $COMMAND_CONFIG"

    local leader_id
    leader_id=$(eval "$cmd --describe --status" 2>/dev/null | grep "LeaderId" | awk '{print $2}' || true)

    if [[ -n "$leader_id" ]]; then
        log "  Controller (LeaderId): $leader_id"
    else
        log "  Could not determine controller"
    fi
}

main() {
    parse_args "$@"
    validate_prerequisites

    echo "========================================"
    echo "Kafka Cluster Health Check"
    echo "========================================"
    echo "Bootstrap: $BOOTSTRAP_SERVER"
    echo "Time: $(date -Iseconds)"
    echo ""

    local healthy=true

    check_broker_connectivity || healthy=false
    echo ""
    get_broker_info
    echo ""
    check_metadata_quorum || healthy=false
    echo ""
    check_controller
    echo ""

    echo "========================================"
    if [[ "$healthy" == true ]]; then
        log "Cluster health check: PASSED"
        exit 0
    else
        error "Cluster health check: FAILED"
        exit 1
    fi
}

main "$@"
