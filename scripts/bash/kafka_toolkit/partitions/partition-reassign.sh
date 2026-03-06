#!/usr/bin/env bash
#
# Purpose: Generate and execute Kafka partition reassignment plans
# Usage: ./partition-reassign.sh [--generate | --execute | --verify] [--topics NAME]
# Requirements: kafka-reassign-partitions.sh in PATH
# Safety: Dry-run by default; requires --execute for actual reassignment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Defaults
BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
ACTION=""
TOPICS=()
BROKER_LIST=""
REASSIGNMENT_FILE=""
DRY_RUN=true
VERBOSE=false
COMMAND_CONFIG=""
THROTTLE_MB=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Generate, execute, and verify Kafka partition reassignment plans.

ACTIONS:
    -g, --generate                  Generate reassignment JSON plan
    -e, --execute                   Execute reassignment from file
    -v, --verify                    Verify reassignment progress
    -c, --cancel                    Cancel ongoing reassignment

OPTIONS:
    -b, --bootstrap-server SERVER   Kafka bootstrap server (default: localhost:9092)
    -t, --topics NAME,...           Comma-separated topic names (default: all)
    -B, --brokers ID,...            Target broker IDs for reassignment
    -f, --file FILE                 Reassignment plan JSON file
    -T, --throttle MB               Replication throttle in MB/s
    -n, --dry-run                   Show what would be done (default)
    -x, --execute                   Execute reassignment (overrides dry-run)
    -v, --verbose                   Enable verbose output
    -h, --help                      Show this help message

EXAMPLES:
    # Generate plan for specific topics
    $(basename "$0") --generate -t events,orders -B 1,2,3

    # Generate plan for all topics with throttle
    $(basename "$0") --generate -B 4,5,6 -T 50

    # Execute reassignment from file
    $(basename "$0") --execute -f reassignment.json

    # Verify reassignment progress
    $(basename "$0") --verify -f reassignment.json

    # Cancel ongoing reassignment
    $(basename "$0") --cancel -f reassignment.json

    # Dry-run first (recommended)
    $(basename "$0") --generate -t events -B 1,2,3
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
            -g|--generate)
                ACTION="generate"
                shift
                ;;
            -e|--execute)
                ACTION="execute"
                shift
                ;;
            -v|--verify)
                ACTION="verify"
                shift
                ;;
            -c|--cancel)
                ACTION="cancel"
                shift
                ;;
            -b|--bootstrap-server)
                BOOTSTRAP_SERVER="$2"
                shift 2
                ;;
            -t|--topics)
                IFS=',' read -ra TOPICS <<< "$2"
                shift 2
                ;;
            -B|--brokers)
                BROKER_LIST="$2"
                shift 2
                ;;
            -f|--file)
                REASSIGNMENT_FILE="$2"
                shift 2
                ;;
            -T|--throttle)
                THROTTLE_MB="$2"
                shift 2
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -x|--execute)
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
    if ! command -v kafka-reassign-partitions.sh &>/dev/null; then
        die "kafka-reassign-partitions.sh not found. Ensure Kafka bin/ is in PATH."
    fi

    if [[ -n "$COMMAND_CONFIG" && ! -f "$COMMAND_CONFIG" ]]; then
        die "Command config file not found: $COMMAND_CONFIG"
    fi

    if [[ -z "$ACTION" ]]; then
        die "Action required: --generate, --execute, --verify, or --cancel"
    fi

    if [[ "$ACTION" == "generate" && -z "$BROKER_LIST" ]]; then
        die "Target brokers required for generate (--brokers)"
    fi

    if [[ ("$ACTION" == "execute" || "$ACTION" == "verify" || "$ACTION" == "cancel") && -z "$REASSIGNMENT_FILE" ]]; then
        die "Reassignment file required for execute/verify/cancel (--file)"
    fi

    if [[ "$ACTION" == "execute" && -n "$REASSIGNMENT_FILE" && ! -f "$REASSIGNMENT_FILE" ]]; then
        die "Reassignment file not found: $REASSIGNMENT_FILE"
    fi
}

cmd_base() {
    local cmd="kafka-reassign-partitions.sh --bootstrap-server $BOOTSTRAP_SERVER"
    if [[ -n "$COMMAND_CONFIG" ]]; then
        cmd="$cmd --command-config $COMMAND_CONFIG"
    fi
    echo "$cmd"
}

generate_reassignment() {
    local topics_json=""
    if [[ ${#TOPICS[@]} -gt 0 ]]; then
        topics_json=$(printf '"%s",' "${TOPICS[@]}")
        topics_json="[${topics_json%,}]"
    else
        topics_json='""'
    fi

    local brokers_json
    brokers_json=$(echo "$BROKER_LIST" | sed 's/,/,/g')

    # Create temporary file for reassignment plan
    local temp_file
    temp_file=$(mktemp)

    local cmd="kafka-reassign-partitions.sh --bootstrap-server $BOOTSTRAP_SERVER"
    cmd="$cmd --generate"
    cmd="$cmd --topics-to-move-json-string '{\"topics\": $topics_json}'"
    cmd="$cmd --broker-list \"$BROKER_LIST\""

    if [[ -n "$COMMAND_CONFIG" ]]; then
        cmd="$cmd --command-config $COMMAND_CONFIG"
    fi

    log "Generating reassignment plan..."
    echo "  Topics: ${TOPICS[*]:-(all)}"
    echo "  Target Brokers: $BROKER_LIST"
    [[ -n "$THROTTLE_MB" ]] && echo "  Throttle: ${THROTTLE_MB} MB/s"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        log "DRY-RUN mode - would execute:"
        echo "  $cmd"
        echo ""
        log "Output would be saved to a JSON file for review"
        return 0
    fi

    # Generate and save plan
    log "Generating reassignment plan..."
    eval "$cmd" > "$temp_file" 2>&1 || die "Failed to generate reassignment plan"

    # Extract the proposed assignment from output
    local plan_file="reassignment-plan-$(date +%Y%m%d-%H%M%S).json"
    grep -A 1000 '"version"' "$temp_file" > "$plan_file" 2>/dev/null || true

    if [[ -s "$plan_file" ]]; then
        log "Reassignment plan saved to: $plan_file"
        echo ""
        cat "$plan_file"
        echo ""
        log "To execute: $(basename "$0") --execute -f $plan_file"
    else
        die "Failed to extract reassignment plan from output"
    fi

    rm -f "$temp_file"
}

execute_reassignment() {
    local cmd="kafka-reassign-partitions.sh --bootstrap-server $BOOTSTRAP_SERVER"
    cmd="$cmd --execute"
    cmd="$cmd --reassignment-json-file '$REASSIGNMENT_FILE'"

    if [[ -n "$THROTTLE_MB" ]]; then
        cmd="$cmd --throttle $((THROTTLE_MB * 1048576))"
    fi

    if [[ -n "$COMMAND_CONFIG" ]]; then
        cmd="$cmd --command-config $COMMAND_CONFIG"
    fi

    log "Reassignment Plan:"
    cat "$REASSIGNMENT_FILE"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        log "DRY-RUN mode - would execute:"
        echo "  $cmd"
        echo ""
        log "Review the plan above. Add --execute to apply."
        return 0
    fi

    log "WARNING: This will trigger partition reassignment"
    log "This operation can take significant time and I/O"
    [[ -n "$THROTTLE_MB" ]] && log "Throttle: ${THROTTLE_MB} MB/s"
    echo ""
    read -r -p "Type 'reassign' to confirm: " confirm
    [[ "$confirm" != "reassign" ]] && die "Aborted"

    log "Executing reassignment..."
    [[ "$VERBOSE" == true ]] && log "Executing: $cmd"

    eval "$cmd" 2>&1 || die "Failed to execute reassignment"

    log "Reassignment started. Monitor progress with:"
    echo "  $(basename "$0") --verify -f $REASSIGNMENT_FILE"
}

verify_reassignment() {
    local cmd="kafka-reassign-partitions.sh --bootstrap-server $BOOTSTRAP_SERVER"
    cmd="$cmd --verify"
    cmd="$cmd --reassignment-json-file '$REASSIGNMENT_FILE'"

    if [[ -n "$COMMAND_CONFIG" ]]; then
        cmd="$cmd --command-config $COMMAND_CONFIG"
    fi

    log "Verifying reassignment progress..."
    [[ "$VERBOSE" == true ]] && log "Executing: $cmd"

    echo ""
    eval "$cmd" 2>&1 || die "Failed to verify reassignment"
}

cancel_reassignment() {
    local cmd="kafka-reassign-partitions.sh --bootstrap-server $BOOTSTRAP_SERVER"
    cmd="$cmd --cancel"
    cmd="$cmd --reassignment-json-file '$REASSIGNMENT_FILE'"

    if [[ -n "$COMMAND_CONFIG" ]]; then
        cmd="$cmd --command-config $COMMAND_CONFIG"
    fi

    log "WARNING: This will cancel the ongoing reassignment"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        log "DRY-RUN mode - would execute:"
        echo "  $cmd"
        return 0
    fi

    read -r -p "Type 'cancel' to confirm: " confirm
    [[ "$confirm" != "cancel" ]] && die "Aborted"

    log "Cancelling reassignment..."
    [[ "$VERBOSE" == true ]] && log "Executing: $cmd"

    eval "$cmd" 2>&1 || die "Failed to cancel reassignment"

    log "Reassignment cancelled"
}

main() {
    parse_args "$@"
    validate_prerequisites

    echo "========================================"
    echo "Kafka Partition Reassignment"
    echo "========================================"
    echo "Bootstrap: $BOOTSTRAP_SERVER"
    echo "Action: $ACTION"
    echo "Mode: $([ "$DRY_RUN" == true ] && echo "DRY-RUN" || echo "EXECUTE")"
    echo "Time: $(date -Iseconds)"
    echo ""

    case "$ACTION" in
        generate)
            generate_reassignment
            ;;
        execute)
            execute_reassignment
            ;;
        verify)
            verify_reassignment
            ;;
        cancel)
            cancel_reassignment
            ;;
    esac
}

main "$@"
