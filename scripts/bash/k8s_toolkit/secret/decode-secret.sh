#!/usr/bin/env bash
# decode-secret.sh - Decode Kubernetes secrets (base64 encoded values)
# Usage: ./decode-secret.sh <secret-name> [--namespace=<ns>] [--key=<key>] [--decode]
# Requirements: kubectl configured with cluster access

set -euo pipefail
IFS=$'\n\t'

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $*" >&2; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }

NAMESPACE="${NAMESPACE:-default}"
SECRET_NAME=""
SECRET_KEY=""
DECODE_VALUE=false

usage() {
    cat <<EOF
Decode Kubernetes secrets

Usage: $0 <secret-name> [options]

Arguments:
  <secret-name>          Name of the secret

Options:
  --namespace=<ns>      Namespace (default: default)
  --key=<key>          Specific key to decode (default: all keys)
  --decode             Decode base64 values (default: show encoded)
  -h, --help           Show this help

Examples:
  # List all keys in a secret
  $0 my-secret --namespace=prod

  # Decode a specific key
  $0 my-secret --namespace=prod --key=password --decode

  # Show all keys with decoded values
  $0 my-secret --namespace=prod --decode
EOF
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --namespace=*)
            NAMESPACE="${1#*=}"
            ;;
        --key=*)
            SECRET_KEY="${1#*=}"
            ;;
        --decode)
            DECODE_VALUE=true
            ;;
        -h|--help)
            usage
            ;;
        -*)
            error "Unknown option: $1"
            ;;
        *)
            SECRET_NAME="$1"
            ;;
    esac
    shift
done

if [[ -z "$SECRET_NAME" ]]; then
    error "Secret name is required"
fi

check_prereqs() {
    if ! command -v kubectl &>/dev/null; then
        error "kubectl not found. Install: https://kubernetes.io/docs/tasks/tools/"
    fi
    
    if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
        error "Namespace '$NAMESPACE' does not exist"
    fi
}

decode_secret() {
    local key="$2"
    local encoded_value="$3"
    local decoded=""
    
    if [[ "$DECODE_VALUE" == "true" ]]; then
        decoded=$(echo "$encoded_value" | base64 -d 2>/dev/null || echo "[decode failed]")
        printf "  %-40s -> %s\n" "$key" "$decoded"
    else
        printf "  %-40s = %s\n" "$key" "$encoded_value"
    fi
}

main() {
    check_prereqs
    
    log "Fetching secret: $SECRET_NAME in namespace: $NAMESPACE"
    
    if ! kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &>/dev/null; then
        error "Secret '$SECRET_NAME' not found in namespace '$NAMESPACE'"
    fi
    
    echo ""
    echo "Secret: $SECRET_NAME"
    echo "Namespace: $NAMESPACE"
    echo "Type: $(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.type}')"
    echo ""
    
    if [[ -n "$SECRET_KEY" ]]; then
        local value
        value=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath="{.data.${SECRET_KEY}}" 2>/dev/null || true)
        
        if [[ -z "$value" ]]; then
            error "Key '$SECRET_KEY' not found in secret"
        fi
        
        echo "Key: $SECRET_KEY"
        decode_secret "$SECRET_NAME" "$SECRET_KEY" "$value"
    else
        echo "Keys:"
        local all_keys
        all_keys=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data}' | jq -r 'keys[]' 2>/dev/null)
        
        if [[ -z "$all_keys" ]]; then
            error "Failed to parse secret data. Is jq installed?"
        fi
        
        while IFS= read -r key; do
            [[ -z "$key" ]] && continue
            local encoded_value
            encoded_value=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath="{.data.${key}}")
            decode_secret "$SECRET_NAME" "$key" "$encoded_value"
        done <<< "$all_keys"
    fi
    
    echo ""
    log "Done"
}

main "$@"
