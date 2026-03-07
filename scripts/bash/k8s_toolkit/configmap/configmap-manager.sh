#!/bin/bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-default}"
OUTPUT_FORMAT="table"

usage() {
    cat <<EOF
Usage: $(basename "$0") <command> [options]

Commands:
    list                    List ConfigMaps and Secrets
    get <name>              Get ConfigMap or Secret details
    create <name>           Create a ConfigMap from literals or file
    update <name>          Update ConfigMap from literals or file
    delete <name>          Delete ConfigMap or Secret
    diff <name>            Show diff between local file and cluster

Options:
    -n, --namespace <ns>   Namespace (default: default)
    -t, --type <type>      Type: configmap, secret, or all (default: all)
    -o, --output <format>  Output format: table, yaml, json (default: table)
    -f, --file <path>      File path for create/update from file
    -k, --key-value <kv>   Key=value pairs for create/update (can repeat)
    --dry-run              Show what would happen without making changes

Examples:
    # List all ConfigMaps and Secrets
    $(basename "$0") list -n myns

    # Get a ConfigMap
    $(basename "$0") get my-config -n myns

    # Create ConfigMap from key-value pairs
    $(basename "$0") create my-config -n myns -k "key1=value1" -k "key2=value2"

    # Create ConfigMap from file
    $(basename "$0") create my-config -n myns -f config.yaml

    # Update ConfigMap
    $(basename "$0") update my-config -n myns -k "newkey=newvalue"

    # Delete ConfigMap
    $(basename "$0") delete my-config -n myns

    # Show diff
    $(basename "$0") diff my-config -n myns -f local-config.yaml

EOF
    exit 1
}

get_resource() {
    local name="$1"
    local resource_type="$2"
    
    if [[ "$resource_type" == "secret" ]]; then
        kubectl get secret "$name" -n "$NAMESPACE" -o yaml 2>/dev/null | kubectl --dry-run=client apply -f - 2>/dev/null || kubectl get secret "$name" -n "$NAMESPACE" -o yaml
    else
        kubectl get configmap "$name" -n "$NAMESPACE" -o yaml
    fi
}

cmd_list() {
    local type_filter="$1"
    
    if [[ "$type_filter" == "configmap" ]] || [[ "$type_filter" == "all" ]]; then
        echo "=== ConfigMaps ==="
        kubectl get configmap -n "$NAMESPACE" -o "$OUTPUT_FORMAT"
        echo ""
    fi
    
    if [[ "$type_filter" == "secret" ]] || [[ "$type_filter" == "all" ]]; then
        echo "=== Secrets ==="
        kubectl get secret -n "$NAMESPACE" -o "$OUTPUT_FORMAT"
    fi
}

cmd_get() {
    local name="$1"
    local resource_type="$2"
    
    if [[ "$resource_type" == "all" ]]; then
        resource_type="configmap"
    fi
    
    get_resource "$name" "$resource_type"
}

cmd_create() {
    local name="$1"
    local file_path=""
    local key_values=()
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--file)
                file_path="$2"
                shift 2
                ;;
            -k|--key-value)
                key_values+=("$2")
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    if [[ -n "$file_path" ]]; then
        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            echo "kubectl create configmap $name --from-file=$file_path -n $NAMESPACE --dry-run=client -o yaml"
            return
        fi
        kubectl create configmap "$name" --from-file="$file_path" -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    elif [[ ${#key_values[@]} -gt 0 ]]; then
        local args=()
        for kv in "${key_values[@]}"; do
            args+=(--from-literal="$kv")
        done
        
        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            echo "kubectl create configmap $name ${args[*]} -n $NAMESPACE --dry-run=client -o yaml"
            return
        fi
        kubectl create configmap "$name" "${args[@]}" -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    else
        echo "Error: Must specify either --file or --key-value"
        exit 1
    fi
    
    echo "Created/updated ConfigMap: $name in namespace: $NAMESPACE"
}

cmd_update() {
    local name="$1"
    local file_path=""
    local key_values=()
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--file)
                file_path="$2"
                shift 2
                ;;
            -k|--key-value)
                key_values+=("$2")
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    if [[ -n "$file_path" ]]; then
        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            echo "kubectl create configmap $name --from-file=$file_path -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -"
            return
        fi
        kubectl create configmap "$name" --from-file="$file_path" -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    elif [[ ${#key_values[@]} -gt 0 ]]; then
        local args=()
        for kv in "${key_values[@]}"; do
            args+=(--from-literal="$kv")
        done
        
        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            echo "kubectl create configmap $name ${args[*]} -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -"
            return
        fi
        kubectl create configmap "$name" "${args[@]}" -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    else
        echo "Error: Must specify either --file or --key-value"
        exit 1
    fi
    
    echo "Updated ConfigMap: $name in namespace: $NAMESPACE"
}

cmd_delete() {
    local name="$1"
    local resource_type="$2"
    
    if [[ "$resource_type" == "all" ]]; then
        resource_type="configmap"
    fi
    
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        echo "kubectl delete $resource_type $name -n $NAMESPACE"
        return
    fi
    
    kubectl delete "$resource_type" "$name" -n "$NAMESPACE"
    echo "Deleted $resource_type: $name from namespace: $NAMESPACE"
}

cmd_diff() {
    local name="$1"
    local file_path=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--file)
                file_path="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    if [[ -z "$file_path" ]]; then
        echo "Error: --file is required for diff"
        exit 1
    fi
    
    local current
    current=$(kubectl get configmap "$name" -n "$NAMESPACE" -o yaml 2>/dev/null || echo "")
    
    local proposed
    proposed=$(kubectl create configmap "$name" --from-file="$file_path" -n "$NAMESPACE" --dry-run=client -o yaml)
    
    if diff <(echo "$current") <(echo "$proposed") >/dev/null 2>&1; then
        echo "No differences found"
    else
        diff <(echo "$current") <(echo "$proposed") || true
    fi
}

COMMAND="${1:-}"
[[ "$COMMAND" == "help" ]] && usage

if [[ $# -eq 0 ]]; then
    usage
fi

shift

RESOURCE_TYPE="all"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -t|--type)
            RESOURCE_TYPE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

case "$COMMAND" in
    list)
        cmd_list "$RESOURCE_TYPE"
        ;;
    get)
        [[ -z "${1:-}" ]] && usage
        cmd_get "$1" "$RESOURCE_TYPE"
        ;;
    create)
        [[ -z "${1:-}" ]] && usage
        cmd_create "$@"
        ;;
    update)
        [[ -z "${1:-}" ]] && usage
        cmd_update "$@"
        ;;
    delete)
        [[ -z "${1:-}" ]] && usage
        cmd_delete "$1" "$RESOURCE_TYPE"
        ;;
    diff)
        [[ -z "${1:-}" ]] && usage
        cmd_diff "$@"
        ;;
    *)
        usage
        ;;
esac
