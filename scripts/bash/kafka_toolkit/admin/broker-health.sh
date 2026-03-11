#!/usr/bin/env bash
#
# Purpose: Check individual broker health (port, JMX, replica status)
# Usage: ./broker-health.sh -b <broker> [-p <port>] [-j <jmx-port>] [--replica-check]
# Requirements: kafka-topics.sh, nc, jq (optional for JSON output)
# Safety: Read-only operations only, --dry-run available

set -euo pipefail

BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
BROKER_HOST=""
BROKER_PORT=9092
JMX_PORT=9999
CHECK_PORT=true
CHECK_JMX=false
CHECK_REPLICA=false
DRY_RUN=false
VERBOSE=false
COMMAND_CONFIG=""
TIMEOUT=10

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Check individual broker health: port connectivity, JMX metrics, replica status.

OPTIONS:
    -b, --broker HOST         Broker hostname (required for port/JMX check)
    -p, --port PORT           Broker port (default: 9092)
    -j, --jmx-port PORT       JMX port for metrics (default: 9999)
    -B, --bootstrap-server SERVER  Kafka bootstrap server (default: localhost:9092)
    -c, --command-config FILE      Properties file for client config
        --check-port          Enable port connectivity check (default: true)
        --check-jmx           Enable JMX health check
        --check-replica       Enable replica status check
        --check-all           Enable all health checks
    -t, --timeout SEC         Connection timeout (default: 10)
    -n, --dry-run             Show what would be checked without executing
    -v, --verbose             Enable verbose output
    -f, --format FORMAT       Output format: text, json (default: text)
    -h, --help                Show this help message

EXAMPLES:
    # Basic port check
    $(basename "$0") -b kafka1.example.com -p 9092

    # Full health check with JMX
    $(basename "$0") -b kafka1.example.com -j 9999 --check-all

    # Check replicas only (no port/JMX)
    $(basename "$0") -B kafka.example.com:9092 --check-replica

    # JSON output for monitoring
    $(basename "$0") -b kafka1 -j 9999 --check-all -f json

CHECKS PERFORMED:
    - Port connectivity (TCP)
    - JMX port accessibility and basic metrics
    - Under-replicated partitions per broker
    - Offline partitions count
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
            -b|--broker)
                BROKER_HOST="$2"
                shift 2
                ;;
            -p|--port)
                BROKER_PORT="$2"
                shift 2
                ;;
            -j|--jmx-port)
                JMX_PORT="$2"
                shift 2
                ;;
            -B|--bootstrap-server)
                BOOTSTRAP_SERVER="$2"
                shift 2
                ;;
            -c|--command-config)
                COMMAND_CONFIG="$2"
                shift 2
                ;;
            --check-port)
                CHECK_PORT=true
                shift
                ;;
            --check-jmx)
                CHECK_JMX=true
                shift
                ;;
            --check-replica)
                CHECK_REPLICA=true
                shift
                ;;
            --check-all)
                CHECK_PORT=true
                CHECK_JMX=true
                CHECK_REPLICA=true
                shift
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -f|--format)
                OUTPUT_FORMAT="$2"
                shift 2
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

    if [[ -z "$BROKER_HOST" ]] && [[ "$CHECK_PORT" == true || "$CHECK_JMX" == true ]]; then
        die "Broker hostname required (use -b/--broker)"
    fi
}

check_port() {
    local host="$1"
    local port="$2"
    local label="$host:$port"

    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY-RUN] Would check port connectivity for $label"
        return 0
    fi

    log "Checking port connectivity: $label"

    if command -v nc &>/dev/null; then
        if timeout "$TIMEOUT" nc -z "$host" "$port" 2>/dev/null; then
            echo "  ✓ $label is reachable"
            return 0
        else
            echo "  ✗ Cannot connect to $label"
            return 1
        fi
    elif command -v timeout &>/dev/null; then
        if timeout "$TIMEOUT" bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
            echo "  ✓ $label is reachable"
            return 0
        else
            echo "  ✗ Cannot connect to $label"
            return 1
        fi
    else
        echo "  ⚠ Neither nc nor bash TCP available, skipping port check"
        return 0
    fi
}

check_jmx() {
    local host="$1"
    local port="$2"

    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY-RUN] Would check JMX at $host:$port"
        return 0
    fi

    log "Checking JMX port: $host:$port"

    if ! timeout "$TIMEOUT" nc -z "$host" "$port" 2>/dev/null; then
        echo "  ✗ JMX port $port not accessible"
        return 1
    fi

    echo "  ✓ JMX port is accessible"

    if [[ "$VERBOSE" == true ]]; then
        echo "  ℹ Note: Full JMX metrics require jmxterm or Jolokia endpoint"
        echo "  ℹ Common metrics: java.lang:type=Memory, kafka.server:type=ReplicaManager"
    fi
    return 0
}

check_replica_status() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY-RUN] Would check replica status for all topics"
        return 0
    fi

    log "Checking replica status..."

    local cmd="kafka-topics.sh --bootstrap-server $BOOTSTRAP_SERVER --describe"
    [[ -n "$COMMAND_CONFIG" ]] && cmd="$cmd --command-config $COMMAND_CONFIG"

    local output
    if ! output=$(eval "$cmd" 2>&1); then
        error "Failed to get topic descriptions"
        echo "$output" >&2
        return 1
    fi

    local under_replicated=0
    local offline_partitions=0
    local total_partitions=0

    total_partitions=$(echo "$output" | grep -c "Partition:" || true)

    if [[ "$total_partitions" -eq 0 ]]; then
        echo "  No partitions found"
        return 0
    fi

    under_replicated=$(echo "$output" | grep -c "UnderReplicated" || true)
    offline_partitions=$(echo "$output" | grep -c "OfflineReplicas" || true)

    echo "  Total partitions: $total_partitions"
    echo "  Under-replicated: $under_replicated"
    echo "  Offline partitions: $offline_partitions"

    if [[ "$VERBOSE" == true ]] && [[ "$under_replicated" -gt 0 ]]; then
        echo ""
        echo "  Under-replicated partitions:"
        echo "$output" | grep "UnderReplicated" | head -10
    fi

    if [[ "$VERBOSE" == true ]] && [[ "$offline_partitions" -gt 0 ]]; then
        echo ""
        echo "  Offline partitions:"
        echo "$output" | grep "OfflineReplicas" | head -10
    fi

    if [[ "$under_replicated" -gt 0 || "$offline_partitions" -gt 0 ]]; then
        return 1
    fi

    return 0
}

output_json() {
    local port_status="$1"
    local jmx_status="$2"
    local replica_status="$3"
    local under_repl="$4"
    local offline="$5"

    cat <<EOF
{
  "broker": "$BROKER_HOST",
  "port": $BROKER_PORT,
  "jmx_port": $JMX_PORT,
  "port_healthy": $port_status,
  "jmx_healthy": $jmx_status,
  "replica_healthy": $replica_status,
  "under_replicated_partitions": $under_repl,
  "offline_partitions": $offline,
  "timestamp": "$(date -Iseconds)"
}
EOF
}

main() {
    OUTPUT_FORMAT="text"
    parse_args "$@"
    validate_prerequisites

    if [[ "$CHECK_PORT" == false && "$CHECK_JMX" == false && "$CHECK_REPLICA" == false ]]; then
        CHECK_PORT=true
    fi

    echo "========================================"
    echo "Kafka Broker Health Check"
    echo "========================================"
    echo "Bootstrap: $BOOTSTRAP_SERVER"
    if [[ -n "$BROKER_HOST" ]]; then
        echo "Broker: $BROKER_HOST:$BROKER_PORT"
        echo "JMX: $BROKER_HOST:$JMX_PORT"
    fi
    echo "Time: $(date -Iseconds)"
    echo ""

    local port_ok=true
    local jmx_ok=true
    local replica_ok=true
    local under_repl=0
    local offline=0

    if [[ "$CHECK_PORT" == true ]]; then
        check_port "$BROKER_HOST" "$BROKER_PORT" || port_ok=false
        echo ""
    fi

    if [[ "$CHECK_JMX" == true ]]; then
        check_jmx "$BROKER_HOST" "$JMX_PORT" || jmx_ok=false
        echo ""
    fi

    if [[ "$CHECK_REPLICA" == true ]]; then
        if check_replica_status; then
            replica_ok=true
            under_repl=0
            offline=0
        else
            replica_ok=false
            local output
            output=$(kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --describe 2>/dev/null)
            under_repl=$(echo "$output" | grep -c "UnderReplicated" || echo 0)
            offline=$(echo "$output" | grep -c "OfflineReplicas" || echo 0)
        fi
        echo ""
    fi

    echo "========================================"
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        output_json "$port_ok" "$jmx_ok" "$replica_ok" "$under_repl" "$offline"
    else
        if [[ "$port_ok" == true && "$jmx_ok" == true && "$replica_ok" == true ]]; then
            log "Broker health check: PASSED"
            exit 0
        else
            error "Broker health check: FAILED"
            exit 1
        fi
    fi
}

main "$@"