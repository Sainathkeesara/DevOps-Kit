#!/usr/bin/env bash
#
# Purpose: Manage Kafka ACLs (list, add, remove) with dry-run support
# Usage: ./manage-acls.sh [--list | --add | --remove] [OPTIONS]
# Requirements: kafka-acls.sh in PATH, connectivity to Kafka cluster
# Safety: Dry-run by default for add/remove; requires --execute for modifications

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Defaults
BOOTSTRAP_SERVER="${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}"
ACTION=""
DRY_RUN=true
VERBOSE=false
COMMAND_CONFIG=""

# ACL specification
ACL_PRINCIPAL=""
ACL_HOST=""
ACL_OPERATION=""
ACL_RESOURCE_TYPE=""
ACL_RESOURCE_NAME=""
ACL_PATTERN_TYPE="LITERAL"
ACL_PERMISSION=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Manage Kafka ACLs: list, add, and remove access control rules.

ACTIONS:
    -l, --list                      List all ACLs (default action)
    -a, --add                       Add an ACL rule
    -r, --remove                    Remove an ACL rule

OPTIONS:
    -b, --bootstrap-server SERVER   Kafka bootstrap server (default: localhost:9092)
    -c, --command-config FILE       Properties file for client config
    -e, --execute                   Execute modification (default is dry-run)
    -v, --verbose                   Enable verbose output
    -h, --help                      Show this help message

ACL SPECIFICATION (required for --add/--remove):
    --principal USER                Principal (User:username or User:*)
    --host HOST                     Host address (IP, *, or 0.0.0.0/0)
    --operation OP                  Operation: Read, Write, Create, Delete,
                                    Alter, Describe, ClusterAction, All
    --resource-type TYPE            Resource type: Topic, Group, Cluster,
                                    TransactionalId, DelegationToken
    --resource-name NAME            Resource name (topic name, group name, etc.)
    --pattern-type TYPE             Pattern: LITERAL, PREFIXED, WILDCARD (default: LITERAL)
    --permission PERM               Permission: Allow, Deny

COMMON EXAMPLES:
    # List all ACLs
    $(basename "$0") --list

    # Allow user to read from a topic
    $(basename "$0") --add \\
      --principal User:app-user \\
      --host "*" \\
      --operation Read \\
      --resource-type Topic \\
      --resource-name events \\
      -e

    # Allow user to write to a topic
    $(basename "$0") --add \\
      --principal User:producer \\
      --host "10.0.0.*" \\
      --operation Write \\
      --resource-type Topic \\
      --resource-name events \\
      -e

    # Allow consumer group access
    $(basename "$0") --add \\
      --principal User:app-user \\
      --host "*" \\
      --operation Read \\
      --resource-type Group \\
      --resource-name app-consumer \\
      -e

    # Remove an ACL
    $(basename "$0") --remove \\
      --principal User:old-user \\
      --operation Read \\
      --resource-type Topic \\
      --resource-name events \\
      -e

    # Dry-run first (always recommended)
    $(basename "$0") --add \\
      --principal User:test \\
      --host "*" \\
      --operation Read \\
      --resource-type Topic \\
      --resource-name test-topic
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
            -a|--add)
                ACTION="add"
                shift
                ;;
            -r|--remove)
                ACTION="remove"
                shift
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
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --principal)
                ACL_PRINCIPAL="$2"
                shift 2
                ;;
            --host)
                ACL_HOST="$2"
                shift 2
                ;;
            --operation)
                ACL_OPERATION="$2"
                shift 2
                ;;
            --resource-type)
                ACL_RESOURCE_TYPE="$2"
                shift 2
                ;;
            --resource-name)
                ACL_RESOURCE_NAME="$2"
                shift 2
                ;;
            --pattern-type)
                ACL_PATTERN_TYPE="$2"
                shift 2
                ;;
            --permission)
                ACL_PERMISSION="$2"
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
    if ! command -v kafka-acls.sh &>/dev/null; then
        die "kafka-acls.sh not found. Ensure Kafka bin/ is in PATH."
    fi

    if [[ -n "$COMMAND_CONFIG" && ! -f "$COMMAND_CONFIG" ]]; then
        die "Command config file not found: $COMMAND_CONFIG"
    fi

    # Default to list if no action specified
    if [[ -z "$ACTION" ]]; then
        ACTION="list"
    fi

    # Validate ACL parameters for add/remove
    if [[ "$ACTION" == "add" || "$ACTION" == "remove" ]]; then
        [[ -z "$ACL_PRINCIPAL" ]] && die "Principal required for add/remove (--principal)"
        [[ -z "$ACL_OPERATION" ]] && die "Operation required for add/remove (--operation)"
        [[ -z "$ACL_RESOURCE_TYPE" ]] && die "Resource type required for add/remove (--resource-type)"

        # Validate operation
        local valid_ops=("Read" "Write" "Create" "Delete" "Alter" "Describe" "ClusterAction" "All")
        if [[ ! " ${valid_ops[*]} " =~ " ${ACL_OPERATION} " ]]; then
            die "Invalid operation: $ACL_OPERATION. Valid: ${valid_ops[*]}"
        fi

        # Validate resource type
        local valid_types=("Topic" "Group" "Cluster" "TransactionalId" "DelegationToken")
        if [[ ! " ${valid_types[*]} " =~ " ${ACL_RESOURCE_TYPE} " ]]; then
            die "Invalid resource type: $ACL_RESOURCE_TYPE. Valid: ${valid_types[*]}"
        fi

        # Validate pattern type
        local valid_patterns=("LITERAL" "PREFIXED" "WILDCARD")
        if [[ ! " ${valid_patterns[*]} " =~ " ${ACL_PATTERN_TYPE} " ]]; then
            die "Invalid pattern type: $ACL_PATTERN_TYPE. Valid: ${valid_patterns[*]}"
        fi

        # Validate permission
        if [[ -n "$ACL_PERMISSION" ]]; then
            local valid_perms=("Allow" "Deny")
            if [[ ! " ${valid_perms[*]} " =~ " ${ACL_PERMISSION} " ]]; then
                die "Invalid permission: $ACL_PERMISSION. Valid: ${valid_perms[*]}"
            fi
        fi
    fi
}

cmd_base() {
    local cmd="kafka-acls.sh --bootstrap-server $BOOTSTRAP_SERVER"
    if [[ -n "$COMMAND_CONFIG" ]]; then
        cmd="$cmd --command-config $COMMAND_CONFIG"
    fi
    echo "$cmd"
}

list_acls() {
    local cmd
    cmd=$(cmd_base)
    cmd="$cmd --list"

    log "Listing all ACLs"
    [[ "$VERBOSE" == true ]] && log "Executing: $cmd"

    echo ""
    echo "=== Kafka ACLs ==="
    eval "$cmd" 2>/dev/null || die "Failed to list ACLs"
}

build_acl_args() {
    local args="--authorizer-properties zookeeper.connect=${BOOTSTRAP_SERVER}"

    # For KRaft mode, use different approach
    if [[ -n "$COMMAND_CONFIG" ]]; then
        args="--command-config $COMMAND_CONFIG"
    fi

    args="$args --principal '$ACL_PRINCIPAL'"
    [[ -n "$ACL_HOST" ]] && args="$args --host '$ACL_HOST'"
    args="$args --operation $ACL_OPERATION"
    args="$args --resource-type $ACL_RESOURCE_TYPE"
    [[ -n "$ACL_RESOURCE_NAME" ]] && args="$args --resource-name '$ACL_RESOURCE_NAME'"
    args="$args --pattern-type $ACL_PATTERN_TYPE"
    [[ -n "$ACL_PERMISSION" ]] && args="$args --permission $ACL_PERMISSION"

    echo "$args"
}

add_acl() {
    local args
    args=$(build_acl_args)

    local cmd="kafka-acls.sh --add $args"

    log "Adding ACL rule:"
    echo "  Principal: $ACL_PRINCIPAL"
    echo "  Host: ${ACL_HOST:-(any)}"
    echo "  Operation: $ACL_OPERATION"
    echo "  Resource Type: $ACL_RESOURCE_TYPE"
    echo "  Resource Name: ${ACL_RESOURCE_NAME:-(any)}"
    echo "  Pattern Type: $ACL_PATTERN_TYPE"
    echo "  Permission: ${ACL_PERMISSION:-Allow}"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        log "DRY-RUN mode - would execute:"
        echo "  $cmd"
        echo ""
        log "Review the ACL rule above. Add --execute to apply."
        return 0
    fi

    log "Adding ACL..."
    [[ "$VERBOSE" == true ]] && log "Executing: $cmd"

    if eval "$cmd" 2>&1; then
        log "ACL added successfully"
    else
        die "Failed to add ACL"
    fi
}

remove_acl() {
    local args
    args=$(build_acl_args)

    local cmd="kafka-acls.sh --remove $args"

    log "Removing ACL rule:"
    echo "  Principal: $ACL_PRINCIPAL"
    echo "  Host: ${ACL_HOST:-(any)}"
    echo "  Operation: $ACL_OPERATION"
    echo "  Resource Type: $ACL_RESOURCE_TYPE"
    echo "  Resource Name: ${ACL_RESOURCE_NAME:-(any)}"
    echo "  Pattern Type: $ACL_PATTERN_TYPE"
    echo "  Permission: ${ACL_PERMISSION:-Allow}"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        log "DRY-RUN mode - would execute:"
        echo "  $cmd"
        echo ""
        log "Review the ACL rule above. Add --execute to apply."
        return 0
    fi

    log "WARNING: This will permanently remove the ACL rule"
    read -r -p "Continue? (yes/no): " confirm
    [[ "$confirm" != "yes" ]] && die "Aborted"

    log "Removing ACL..."
    [[ "$VERBOSE" == true ]] && log "Executing: $cmd"

    if eval "$cmd" 2>&1; then
        log "ACL removed successfully"
    else
        die "Failed to remove ACL"
    fi
}

main() {
    parse_args "$@"
    validate_prerequisites

    echo "========================================"
    echo "Kafka ACL Management"
    echo "========================================"
    echo "Bootstrap: $BOOTSTRAP_SERVER"
    echo "Action: $ACTION"
    echo "Mode: $([ "$DRY_RUN" == true ] && echo "DRY-RUN" || echo "EXECUTE")"
    echo "Time: $(date -Iseconds)"
    echo ""

    case "$ACTION" in
        list)
            list_acls
            ;;
        add)
            add_acl
            ;;
        remove)
            remove_acl
            ;;
    esac
}

main "$@"
