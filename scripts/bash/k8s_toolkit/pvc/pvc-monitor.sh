#!/bin/bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-default}"

usage() {
    cat <<EOF
Usage: $(basename "$0") <command> [options]

Commands:
    list                    List all PVCs with status
    status <name>          Show PVC details and conditions
    usage                   Show storage usage per PVC
    unused                  Find unused PVCs (no pods referencing)
    pods                    Show pods using each PVC
    volume <name>           Show PV details
    watch                   Watch PVC status changes

Options:
    -n, --namespace <ns>    Namespace (default: all namespaces)
    -s, --storage-class <sc>  Filter by storage class
    -w, --watch             Watch mode
    --threshold <gb>       Threshold for usage alert (default: 80)

Examples:
    # List all PVCs
    $(basename "$0") list

    # PVCs in specific namespace
    $(basename "$0") list -n myns

    # Show storage usage
    $(basename "$0") usage -n myns

    # Find unused PVCs
    $(basename "$0") unused -n myns

    # Show pods using PVCs
    $(basename "$0") pods -n myns

    # Watch PVC status
    $(basename "$0") watch -n myns

EOF
    exit 1
}

cmd_list() {
    local storage_class="${STORAGE_CLASS:-}"
    local ns_arg=""
    
    if [[ "$NAMESPACE" != "all" ]]; then
        ns_arg="-n $NAMESPACE"
    fi
    
    echo "=== PersistentVolumeClaims ==="
    if [[ -n "$storage_class" ]]; then
        kubectl get pvc "$ns_arg" -o wide --field-selector spec.storageClassName="$storage_class"
    else
        kubectl get pvc "$ns_arg" -o wide
    fi
    
    echo ""
    echo "=== PVC Status Summary ==="
    
    local pending
    pending=$(kubectl get pvc "$ns_arg" -o jsonpath='{.items[?(@.status.phase=="Pending")].metadata.name}' 2>/dev/null | wc -w)
    
    local bound
    bound=$(kubectl get pvc "$ns_arg" -o jsonpath='{.items[?(@.status.phase=="Bound")].metadata.name}' 2>/dev/null | wc -w)
    
    local lost
    lost=$(kubectl get pvc "$ns_arg" -o jsonpath='{.items[?(@.status.phase=="Lost")].metadata.name}' 2>/dev/null | wc -w)
    
    echo "Bound: $bound"
    echo "Pending: $pending"
    echo "Lost: $lost"
    
    if [[ "$pending" -gt 0 ]]; then
        echo ""
        echo "WARNING: There are $pending PVC(s) in Pending state"
        kubectl get pvc "$ns_arg" --field-selector status.phase=Pending -o custom-columns=NAME:.metadata.name,REASON:.status.conditions[0].type,MESSAGE:.status.conditions[0].message
    fi
}

cmd_status() {
    local name="$1"
    
    echo "=== PVC: $name ==="
    kubectl get pvc "$name" -n "$NAMESPACE" -o wide
    
    echo ""
    echo "=== Events ==="
    kubectl get events -n "$NAMESPACE" --field-selector involvedObject.name="$name",involvedObject.kind=PersistentVolumeClaim --sort-by='.lastTimestamp'
    
    echo ""
    echo "=== Conditions ==="
    kubectl get pvc "$name" -n "$NAMESPACE" -o jsonpath='{range .status.conditions[*]}
Type: {.type}
Status: {.status}
Message: {.message}
Last Update: {.lastTransitionTime}
---
{end}'
}

cmd_usage() {
    local threshold="${THRESHOLD:-80}"
    local ns_arg=""
    
    if [[ "$NAMESPACE" != "all" ]]; then
        ns_arg="-n $NAMESPACE"
    fi
    
    echo "=== Storage Usage (threshold: ${threshold}%) ==="
    
    local pvcs
    pvcs=$(kubectl get pvc "$ns_arg" -o jsonpath='{.items[*].metadata.name}')
    
    for pvc in $pvcs; do
        local ns
        ns=$(kubectl get pvc "$pvc" "$ns_arg" -o jsonpath='{.metadata.namespace}')
        
        local capacity
        capacity=$(kubectl get pvc "$pvc" -n "$ns" -o jsonpath='{.status.capacity.storage}')
        
        local used
        used=$(kubectl get pvc "$pvc" -n "$ns" -o jsonpath='{.status.usedSize}' 2>/dev/null || echo "")
        
        local request
        request=$(kubectl get pvc "$pvc" -n "$ns" -o jsonpath='{.spec.resources.requests.storage}')
        
        local pv
        pv=$(kubectl get pvc "$pvc" -n "$ns" -o jsonpath='{.spec.volumeName}')
        
        echo ""
        echo "PVC: $pvc (ns: $ns)"
        echo "  Request: $request"
        echo "  Capacity: $capacity"
        echo "  Used: ${used:-N/A}"
        echo "  PV: ${pv:-N/A}"
        
        if [[ -n "$used" ]]; then
            local used_num
            used_num=$(echo "$used" | sed 's/Gi//' | sed 's/Mi//' | sed 's/Ti//')
            
            if [[ "$used" == *"Gi" ]]; then
                local request_num
                request_num=${request//Gi/}
                local pct=$((used_num * 100 / request_num))
                echo "  Usage: ${pct}%"
                
                if [[ "$pct" -ge "$threshold" ]]; then
                    echo "  WARNING: Usage above ${threshold}%"
                fi
            fi
        fi
    done
}

cmd_unused() {
    local ns_arg=""
    
    if [[ "$NAMESPACE" != "all" ]]; then
        ns_arg="-n $NAMESPACE"
    fi
    
    echo "=== Unused PVCs (no pods referencing) ==="
    
    local pvcs
    pvcs=$(kubectl get pvc "$ns_arg" -o jsonpath='{.items[*].metadata.name}')
    
    local found_unused=false
    
    for pvc in $pvcs; do
        local ns
        ns=$(kubectl get pvc "$pvc" "$ns_arg" -o jsonpath='{.metadata.namespace}')
        
        local referencing_pods
        referencing_pods=$(kubectl get pods -o json --all-namespaces -l volume.kubernetes.io_name="$pvc" 2>/dev/null | jq -r '.items | length')
        
        if [[ "$referencing_pods" == "0" ]]; then
            found_unused=true
            local status
            status=$(kubectl get pvc "$pvc" -n "$ns" -o jsonpath='{.status.phase}')
            local age
            age=$(kubectl get pvc "$pvc" -n "$ns" -o jsonpath='{.metadata.creationTimestamp}')
            echo "PVC: $pvc | Namespace: $ns | Status: $status | Age: $age"
        fi
    done
    
    if [[ "$found_unused" == "false" ]]; then
        echo "No unused PVCs found"
    fi
}

cmd_pods() {
    local ns_arg=""
    
    if [[ "$NAMESPACE" != "all" ]]; then
        ns_arg="-n $NAMESPACE"
    fi
    
    echo "=== Pods using PVCs ==="
    
    local pvcs
    pvcs=$(kubectl get pvc "$ns_arg" -o jsonpath='{.items[*].metadata.name}')
    
    for pvc in $pvcs; do
        local ns
        ns=$(kubectl get pvc "$pvc" "$ns_arg" -o jsonpath='{.metadata.namespace}')
        
        echo ""
        echo "--- PVC: $pvc (ns: $ns) ---"
        
        local pods
        pods=$(kubectl get pods -n "$ns" -o json -l volume.kubernetes.io_name="$pvc" 2>/dev/null | jq -r '.items[].metadata.name' 2>/dev/null || echo "")
        
        if [[ -n "$pods" ]]; then
            for pod in $pods; do
                local status
                status=$(kubectl get pod "$pod" -n "$ns" -o jsonpath='{.status.phase}')
                local ready
                ready=$(kubectl get pod "$pod" -n "$ns" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
                echo "  Pod: $pod | Status: $status | Ready: $ready"
            done
        else
            echo "  (no pods using this PVC)"
        fi
    done
}

cmd_volume() {
    local name="$1"
    local pvc_info
    pvc_info=$(kubectl get pvc "$name" -n "$NAMESPACE" -o json 2>/dev/null)
    
    if [[ -z "$pvc_info" ]]; then
        echo "Error: PVC '$name' not found in namespace '$NAMESPACE'"
        exit 1
    fi
    
    local pv
    pv=$(echo "$pvc_info" | jq -r '.spec.volumeName // empty')
    
    if [[ -z "$pv" ]]; then
        echo "Error: No PV bound to PVC '$name'"
        exit 1
    fi
    
    echo "=== PV: $pv ==="
    kubectl get pv "$pv" -o wide
    
    echo ""
    echo "=== PV Details ==="
    kubectl get pv "$pv" -o json | jq '{
        name: .metadata.name,
        capacity: .spec.capacity,
        accessModes: .spec.accessModes,
        reclaimPolicy: .spec.persistentVolumeReclaimPolicy,
        storageClass: .spec.storageClassName,
        status: .status.phase,
        claim: .spec.claimRef,
        nodeAffinity: .spec.nodeAffinity
    }'
}

cmd_watch() {
    local ns_arg=""
    
    if [[ "$NAMESPACE" != "all" ]]; then
        ns_arg="-n $NAMESPACE"
    fi
    
    echo "Watching PVCs in namespace: $NAMESPACE (Ctrl+C to exit)"
    echo ""
    
    watch -t -n 5 "kubectl get pvc $ns_arg -o wide"
}

COMMAND="${1:-}"
[[ "$COMMAND" == "help" ]] && usage

if [[ $# -eq 0 ]]; then
    usage
fi

STORAGE_CLASS=""
THRESHOLD=80

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -s|--storage-class)
            STORAGE_CLASS="$2"
            shift 2
            ;;
        --threshold)
            THRESHOLD="$2"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

case "$COMMAND" in
    list)
        cmd_list
        ;;
    status)
        [[ -z "${1:-}" ]] && usage
        cmd_status "$1"
        ;;
    usage)
        cmd_usage
        ;;
    unused)
        cmd_unused
        ;;
    pods)
        cmd_pods
        ;;
    volume)
        [[ -z "${1:-}" ]] && usage
        cmd_volume "$1"
        ;;
    watch)
        cmd_watch
        ;;
    *)
        usage
        ;;
esac
