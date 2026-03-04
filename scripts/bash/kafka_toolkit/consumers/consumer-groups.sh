#!/usr/bin/env bash
#
# Purpose: Manage and inspect Kafka consumer groups (list, describe, reset offsets)
# Usage: ./consumer-groups.sh [--list | --describe --group NAME | --reset --group NAME]
# Requirements: kafka-consumer-groups.sh in PATH
# Safety: Read-only by default; reset requires explicit --execute flag

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Defaults
BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
ACTION=""
GROUP=""
TOPIC=""
PARTITION=""
OFFSET=""
DRY_RUN=true
VERBOSE=false
COMMAND_CONFIG=""
ALL_TOPICS=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Manage Kafka consumer groups: list, describe, and reset offsets.

ACTIONS:
    -l, --list                      List all consumer groups
    -d, --describe                  Describe consumer group (requires -g)
    -r, --reset-offsets             Reset offsets (requires -g, --to-*)

OPTIONS:
    -g, --group GROUP               Consumer group name
    -t, --topic TOPIC               Target topic (for reset)
    -p, --partition N               Target partition (for reset)
    -b, --bootstrap-server SERVER   Kafka bootstrap server
    -c, --command-config FILE       Properties file for client config
    -e, --execute                   Execute reset (default is dry-run)
    -v, --verbose                   Enable verbose output
    -h, --help                      Show this help message

RESET TARGETS (use with --reset-offsets):
    --to-earliest                   Reset to earliest offset
    --to-latest                     Reset to latest offset
    --to-datetime 'YYYY-MM-DDTHH:mm:ss.sss'
                                    Reset to specific datetime
    --to-offset N                   Reset to specific offset
    --shift-by N                    Shift offset by N (+/-)

EXAMPLES:
    $(basename "$0") --list
    $(basename "$0") --describe --group my-group
    $(basename "$0") --reset-offsets --group my-group --topic events --to-earliest -e
    $(basename "$0") --reset-offsets --group my-group --all-topics --to-latest -e
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
            -l|--list)
                ACTION="list"
                shift
                ;;
            -d|--describe)
                ACTION="describe"
                shift
                ;;
            -r|--reset-offsets)
                ACTION="reset"
                shift
                ;;
            -g|--group)
                GROUP="$2"
                shift 2
                ;;
            -t|--topic)
                TOPIC="$2"
                shift 2
                ;;
            -p|--partition)
                PARTITION="$2"
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
            --to-earliest)
                OFFSET="earliest"
                shift
                ;;
            --to-latest)
                OFFSET="latest"
                shift
                ;;
            --to-datetime)
                OFFSET="datetime"
                DATETIME="$2"
                shift 2
                ;;
            --to-offset)
                OFFSET="offset"
                OFFSET_VALUE="$2"
                shift 2
                ;;
            --shift-by)
                OFFSET="shift"
                SHIFT_VALUE="$2"
                shift 2
                ;;
            --all-topics)
                ALL_TOPICS=true
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
    if ! command -v kafka-consumer-groups.sh &>/dev/null; then
        die "kafka-consumer-groups.sh not found. Ensure Kafka bin/ is in PATH."
    fi

    if [[ -n "$COMMAND_CONFIG" && ! -f "$COMMAND_CONFIG" ]]; then
        die "Command config file not found: $COMMAND_CONFIG"
    fi

    if [[ -z "$ACTION" ]]; then
        die "No action specified. Use --list, --describe, or --reset-offsets"
    fi

    if [[ "$ACTION" != "list" && -z "$GROUP" ]]; then
        die "Group name required for describe/reset actions (-g GROUP)"
    fi
}

cmd_base() {
    local cmd="kafka-consumer-groups.sh --bootstrap-server $BOOTSTRAP_SERVER"
    if [[ -n "$COMMAND_CONFIG" ]]; then
        cmd="$cmd --command-config $COMMAND_CONFIG"
    fi
    echo "$cmd"
}

list_groups() {
    local cmd
    cmd=$(cmd_base)
    cmd="$cmd --list"

    [[ "$VERBOSE" == true ]] && log "Executing: $cmd"
    eval "$cmd" 2>/dev/null || die "Failed to list consumer groups"
}

describe_group() {
    local cmd
    cmd=$(cmd_base)
    cmd="$cmd --describe --group $GROUP"

    log "Describing consumer group: $GROUP"
    [[ "$VERBOSE" == true ]] && log "Executing: $cmd"
    eval "$cmd" 2>/dev/null || die "Failed to describe group: $GROUP"
}

reset_offsets() {
    [[ -z "$OFFSET" ]] && die "Reset target required (--to-earliest, --to-latest, etc.)"

    local cmd
    cmd=$(cmd_base)
    cmd="$cmd --reset-offsets --group $GROUP"

    # Add scope
    if [[ "$ALL_TOPICS" == true ]]; then
        cmd="$cmd --all-topics"
    elif [[ -n "$TOPIC" ]]; then
        if [[ -n "$PARTITION" ]]; then
            cmd="$cmd --topic ${TOPIC}:${PARTITION}"
        else
            cmd="$cmd --topic $TOPIC"
        fi
    else
        die "Topic (-t) or --all-topics required for reset"
    fi

    # Add offset target
    case "$OFFSET" in
        earliest)
            cmd="$cmd --to-earliest"
            ;;
        latest)
            cmd="$cmd --to-latest"
            ;;
        datetime)
            cmd="$cmd --to-datetime '$DATETIME'"
            ;;
        offset)
            cmd="$cmd --to-offset $OFFSET_VALUE"
            ;;
        shift)
            cmd="$cmd --shift-by $SHIFT_VALUE"
            ;;
    esac

    if [[ "$DRY_RUN" == true ]]; then
        cmd="$cmd --dry-run"
        log "DRY-RUN mode (add --execute to apply):"
    else
        log "WARNING: Executing offset reset!"
        read -r -p "Continue? (yes/no): " confirm
        [[ "$confirm" != "yes" ]] && die "Aborted"
    fi

    [[ "$VERBOSE" == true ]] && log "Executing: $cmd"
    eval "$cmd" || die "Reset failed"
}

main() {
    parse_args "$@"
    validate_prerequisites

    case "$ACTION" in
        list)
            list_groups
            ;;
        describe)
            describe_group
            ;;
        reset)
            reset_offsets
            ;;
    esac
}

main "$@"
