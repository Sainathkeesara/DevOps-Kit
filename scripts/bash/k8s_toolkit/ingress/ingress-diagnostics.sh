#!/bin/bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-default}"

usage() {
    cat <<EOF
Usage: $(basename "$0") <command> [options]

Commands:
    list                    List all Ingress resources
    status <name>           Check ingress status and backends
    backends <name>         Show backend service endpoints
    tls <name>             Check TLS configuration
    events <name>          Show ingress events
    diagnose <name>        Full diagnostic report
    curl <name> [path]    Test ingress from inside cluster

Options:
    -n, --namespace <ns>   Namespace (default: default)

Examples:
    # List all ingresses
    $(basename "$0") list -n myns

    # Check ingress status
    $(basename "$0") status my-ingress -n myns

    # Full diagnostic
    $(basename "$0") diagnose my-ingress -n myns

    # Test ingress
    $(basename "$0") curl my-ingress /api/health

EOF
    exit 1
}

check_ingress_exists() {
    local name="$1"
    kubectl get ingress "$name" -n "$NAMESPACE" -o name >/dev/null 2>&1
}

cmd_list() {
    echo "=== Ingress Resources in namespace: $NAMESPACE ==="
    kubectl get ingress -n "$NAMESPACE" -o wide
    
    echo ""
    echo "=== Ingress Controller Status ==="
    kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller -o wide 2>/dev/null || \
    kubectl get pods -n kube-system -l k8s-app=ingress-nginx-controller -o wide 2>/dev/null || \
    echo "Ingress controller namespace not found"
}

cmd_status() {
    local name="$1"
    
    if ! check_ingress_exists "$name"; then
        echo "Error: Ingress '$name' not found in namespace '$NAMESPACE'"
        exit 1
    fi
    
    echo "=== Ingress: $name ==="
    kubectl get ingress "$name" -n "$NAMESPACE"
    
    echo ""
    echo "=== Ingress Details ==="
    kubectl describe ingress "$name" -n "$NAMESPACE"
}

cmd_backends() {
    local name="$1"
    
    if ! check_ingress_exists "$name"; then
        echo "Error: Ingress '$name' not found in namespace '$NAMESPACE'"
        exit 1
    fi
    
    echo "=== Backend Services for: $name ==="
    
    local backends
    backends=$(kubectl get ingress "$name" -n "$NAMESPACE" -o jsonpath='{.spec.rules[*].http.paths[*].backend.service.name}')
    
    for backend in $backends; do
        echo ""
        echo "--- Service: $backend ---"
        
        local ports
        ports=$(kubectl get svc "$backend" -n "$NAMESPACE" -o jsonpath='{.spec.ports[*].port}' 2>/dev/null || echo "not found")
        echo "Ports: $ports"
        
        local endpoints
        endpoints=$(kubectl get endpoints "$backend" -n "$NAMESPACE" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || echo "no endpoints")
        echo "Endpoints: $endpoints"
        
        if [[ -z "$endpoints" || "$endpoints" == "no endpoints" ]]; then
            echo "WARNING: No endpoints found - service may have no ready pods"
        fi
    done
}

cmd_tls() {
    local name="$1"
    
    if ! check_ingress_exists "$name"; then
        echo "Error: Ingress '$name' not found in namespace '$NAMESPACE'"
        exit 1
    fi
    
    echo "=== TLS Configuration for: $name ==="
    
    local tls_count
    tls_count=$(kubectl get ingress "$name" -n "$NAMESPACE" -o jsonpath='{.spec.tls[*]}' | wc -w)
    
    if [[ "$tls_count" -eq 0 ]]; then
        echo "No TLS configured"
        return
    fi
    
    kubectl get ingress "$name" -n "$NAMESPACE" -o jsonpath='{.spec.tls}' | jq -r '.[]' 2>/dev/null || \
        kubectl get ingress "$name" -n "$NAMESPACE" -o jsonpath='{.spec.tls}'
    
    echo ""
    echo "=== Checking TLS Secrets ==="
    
    local secrets
    secrets=$(kubectl get ingress "$name" -n "$NAMESPACE" -o jsonpath='{.spec.tls[*].secretName}')
    
    for secret in $secrets; do
        if [[ -n "$secret" && "$secret" != "null" ]]; then
            echo ""
            echo "--- Secret: $secret ---"
            local secret_exists
            secret_exists=$(kubectl get secret "$secret" -n "$NAMESPACE" -o name 2>/dev/null || echo "not found")
            
            if [[ "$secret_exists" != "not found" ]]; then
                local cert_exp
                cert_exp=$(kubectl get secret "$secret" -n "$NAMESPACE" -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d 2>/dev/null | openssl x509 -enddate -noout 2>/dev/null || echo "unable to parse")
                echo "Certificate expires: $cert_exp"
            else
                echo "WARNING: Secret '$secret' not found"
            fi
        fi
    done
}

cmd_events() {
    local name="$1"
    
    if ! check_ingress_exists "$name"; then
        echo "Error: Ingress '$name' not found in namespace '$NAMESPACE'"
        exit 1
    fi
    
    echo "=== Events for Ingress: $name ==="
    kubectl get events -n "$NAMESPACE" --field-selector involvedObject.name="$name",involvedObject.kind=Ingress --sort-by='.lastTimestamp'
}

cmd_diagnose() {
    local name="$1"
    
    echo "=========================================="
    echo "Diagnostic Report for Ingress: $name"
    echo "Namespace: $NAMESPACE"
    echo "=========================================="
    echo ""
    
    cmd_status "$name"
    echo ""
    cmd_backends "$name"
    echo ""
    cmd_tls "$name"
    echo ""
    cmd_events "$name"
    
    echo ""
    echo "=== Service Endpoints Check ==="
    local backends
    backends=$(kubectl get ingress "$name" -n "$NAMESPACE" -o jsonpath='{.spec.rules[*].http.paths[*].backend.service.name}')
    
    for backend in $backends; do
        local ready
        ready=$(kubectl get pods -n "$NAMESPACE" -l "app=$backend" -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | tr -d ' ')
        
        if [[ "$ready" != "True" ]]; then
            echo "WARNING: Service '$backend' has no ready pods"
        fi
    done
    
    echo ""
    echo "=== Ingress Controller Check ==="
    local controller_ns
    for ns in "ingress-nginx" "kube-system" "nginx-ingress"; do
        if kubectl get ns "$ns" >/dev/null 2>&1; then
            controller_ns="$ns"
            break
        fi
    done
    
    if [[ -n "${controller_ns:-}" ]]; then
        local controller_pods
        controller_pods=$(kubectl get pods -n "$controller_ns" -l app.kubernetes.io/component=controller -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
        
        if [[ -n "$controller_pods" ]]; then
            for pod in $controller_pods; do
                local status
                status=$(kubectl get pod "$pod" -n "$controller_ns" -o jsonpath='{.status.phase}')
                echo "Controller pod: $pod - Status: $status"
                
                if [[ "$status" != "Running" ]]; then
                    echo "WARNING: Controller pod is not Running"
                fi
            done
        else
            echo "No controller pods found in namespace: $controller_ns"
        fi
    else
        echo "Could not determine ingress controller namespace"
    fi
}

cmd_curl() {
    local name="$1"
    local path="${2:-/}"
    
    if ! check_ingress_exists "$name"; then
        echo "Error: Ingress '$name' not found in namespace '$NAMESPACE'"
        exit 1
    fi
    
    local host
    host=$(kubectl get ingress "$name" -n "$NAMESPACE" -o jsonpath='{.spec.rules[0].host}')
    
    if [[ -z "$host" || "$host" == "null" ]]; then
        host=$(kubectl get ingress "$name" -n "$NAMESPACE" -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}')
    fi
    
    local namespace="$NAMESPACE"
    local backend
    backend=$(kubectl get ingress "$name" -n "$NAMESPACE" -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}')
    
    echo "Testing ingress via service in cluster..."
    echo "Host: $host"
    echo "Path: $path"
    echo ""
    
    kubectl run curl-test --image=curlimages/curl --rm -i --restart=Never -n "$namespace" \
        -- curl -sS -H "Host: $host" "http://${backend}.${namespace}.svc.cluster.local${path}" 2>/dev/null || \
    kubectl run curl-test --image=curlimages/curl --rm -i --restart=Never -n "$namespace" \
        -- curl -sS "http://${backend}.${namespace}.svc.cluster.local${path}" 2>/dev/null || \
    echo "Failed to curl - check if curl image is available"
}

COMMAND="${1:-}"
[[ "$COMMAND" == "help" ]] && usage

if [[ $# -eq 0 ]]; then
    usage
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--namespace)
            NAMESPACE="$2"
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
    backends)
        [[ -z "${1:-}" ]] && usage
        cmd_backends "$1"
        ;;
    tls)
        [[ -z "${1:-}" ]] && usage
        cmd_tls "$1"
        ;;
    events)
        [[ -z "${1:-}" ]] && usage
        cmd_events "$1"
        ;;
    diagnose)
        [[ -z "${1:-}" ]] && usage
        cmd_diagnose "$1"
        ;;
    curl)
        [[ -z "${1:-}" ]] && usage
        cmd_curl "$@"
        ;;
    *)
        usage
        ;;
esac
