#!/usr/bin/env bash
# context-manager.sh - Manage multiple Kubernetes contexts and namespaces
# Usage: ./context-manager.sh [list|switch|current|validate|run] [args...]
# Requirements: kubectl configured

set -euo pipefail

usage() {
    cat <<EOF
Manage Kubernetes contexts and namespaces

Usage: $0 <command> [options]

Commands:
  list                      List all contexts (default)
  current                   Show current context and namespace
  switch <context> [ns]     Switch to context, optionally set namespace
  validate [context]        Validate context connectivity
  run <context> <command>  Run command in specific context

Options:
  -h, --help               Show this help

Examples:
  # List all contexts with current highlighted
  $0 list

  # Switch to production context
  $0 switch production

  # Switch to production context and monitoring namespace
  $0 switch production monitoring

  # Validate all contexts
  $0 validate

  # Run command in staging context
  $0 run staging kubectl get pods
EOF
    exit 1
}

if [[ $# -eq 0 ]]; then
    usage
fi

COMMAND="$1"
shift

check_prereqs() {
    if ! command -v kubectl &>/dev/null; then
        echo "ERROR: kubectl not found. Install: https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi
}

cmd_list() {
    local current
    current=$(kubectl config current-context 2>/dev/null || echo "")
    
    echo "Available contexts:"
    echo ""
    
    local contexts
    contexts=$(kubectl config get-contexts -o name 2>/dev/null || true)
    
    if [[ -z "$contexts" ]]; then
        echo "  No contexts found"
        return
    fi
    
    while IFS= read -r ctx; do
        [[ -z "$ctx" ]] && continue
        
        local marker=" "
        if [[ "$ctx" == "$current" ]]; then
            marker="*"
        fi
        
        local namespace
        namespace=$(kubectl config view -o "jsonpath={.contexts[?(@.name == \"$ctx\")}].context.namespace" 2>/dev/null || echo "-")
        
        printf "  %s %-30s (namespace: %s)\n" "$marker" "$ctx" "${namespace:-default}"
    done <<< "$contexts"
    
    echo ""
    echo "* = current context"
}

cmd_current() {
    local current
    current=$(kubectl config current-context 2>/dev/null || echo "none")
    
    echo "Current context: $current"
    
    if [[ "$current" != "none" ]]; then
        local namespace
        namespace=$(kubectl config view -o "jsonpath={.contexts[?(@.name == \"$current\")}].context.namespace" 2>/dev/null || echo "default")
        echo "Current namespace: ${namespace:-default}"
        
        local cluster
        cluster=$(kubectl config view -o "jsonpath={.contexts[?(@.name == \"$current\")}].context.cluster" 2>/dev/null || echo "unknown")
        echo "Cluster: $cluster"
    fi
}

cmd_switch() {
    local context="${1:-}"
    local namespace="${2:-}"
    
    if [[ -z "$context" ]]; then
        echo "ERROR: Context name required"
        echo "Usage: $0 switch <context> [namespace]"
        exit 1
    fi
    
    if ! kubectl config get-contexts -o name | grep -qx "$context"; then
        echo "ERROR: Context '$context' not found"
        echo "Available contexts:"
        kubectl config get-contexts -o name | sed 's/^/  /'
        exit 1
    fi
    
    echo "Switching to context: $context"
    kubectl config use-context "$context"
    
    if [[ -n "$namespace" ]]; then
        echo "Setting namespace: $namespace"
        kubectl config set-context "$context" --namespace="$namespace"
    fi
    
    echo "Done. Current context: $(kubectl config current-context)"
}

cmd_validate() {
    local context="${1:-}"
    
    if [[ -z "$context" ]]; then
        echo "Validating all contexts..."
        echo ""
        
        local contexts
        contexts=$(kubectl config get-contexts -o name 2>/dev/null || true)
        
        local valid=0
        local invalid=0
        
        while IFS= read -r ctx; do
            [[ -z "$ctx" ]] && continue
            
            if kubectl --context="$ctx" cluster-info &>/dev/null; then
                echo "  [OK]   $ctx"
                ((valid++)) || true
            else
                echo "  [FAIL] $ctx"
                ((invalid++)) || true
            fi
        done <<< "$contexts"
        
        echo ""
        echo "Valid: $valid, Invalid: $invalid"
    else
        echo "Validating context: $context"
        
        if kubectl --context="$context" cluster-info &>/dev/null; then
            echo "  [OK] Context is accessible"
            
            local namespace
            namespace=$(kubectl --context="$context" config view -o "jsonpath={.contexts[?(@.name == \"$context\")}].context.namespace" 2>/dev/null || echo "default")
            echo "  Namespace: ${namespace:-default}"
            
            local nodes
            nodes=$(kubectl --context="$context" get nodes -o name 2>/dev/null | wc -l || echo 0)
            echo "  Nodes: $nodes"
            
            exit 0
        else
            echo "  [FAIL] Context is not accessible"
            echo "  Check cluster connectivity and credentials"
            exit 1
        fi
    fi
}

cmd_run() {
    local context="${1:-}"
    local cmd="${2:-}"
    
    if [[ -z "$context" ]] || [[ -z "$cmd" ]]; then
        echo "ERROR: Context and command required"
        echo "Usage: $0 run <context> <command>"
        exit 1
    fi
    
    shift 2
    
    echo "Running in context '$context': $cmd"
    kubectl --context="$context" "$cmd" "$@"
}

main() {
    check_prereqs
    
    case "$COMMAND" in
        list)
            cmd_list
            ;;
        current|curr)
            cmd_current
            ;;
        switch|use)
            cmd_switch "$@"
            ;;
        validate|check)
            cmd_validate "$@"
            ;;
        run|exec)
            cmd_run "$@"
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown command: $COMMAND"
            usage
            ;;
    esac
}

main "$@"
