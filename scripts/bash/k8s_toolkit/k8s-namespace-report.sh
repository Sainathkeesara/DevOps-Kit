#!/usr/bin/env bash
################################################################################
# k8s-namespace-report.sh
#
# Purpose: Generate a comprehensive report of resource usage and status across
#          one or all namespaces. Useful for capacity planning and auditing.
# Usage: k8s-namespace-report.sh [namespace] [options]
# Requirements: kubectl configured with list/watch access to common resources.
# Safety: Read-only.
#
# Options:
#   --output <format>   Output format: text (default) or json
#   --no-pods           Omit pod listing
#   --no-deployments    Omit deployment listing
#   --no-pvcs           Omit persistent volume claim listing
#   --resource-limit    Include resource limits/requests summary (slow in large clusters)
################################################################################

set -euo pipefail

OUTPUT_FORMAT="text"
INCLUDE_PODS=true
INCLUDE_DEPLOYMENTS=true
INCLUDE_PVCS=true
RESOURCE_LIMITS=false

usage() {
  grep '^#' "$0" | cut -c4- | head -n 30 >&2
  exit 1
}

error() {
  echo "[k8s-namespace-report][ERROR] $*" >&2
  exit 1
}

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      OUTPUT_FORMAT="$2"
      shift 2
      ;;
    --no-pods)
      INCLUDE_PODS=false
      shift
      ;;
    --no-deployments)
      INCLUDE_DEPLOYMENTS=false
      shift
      ;;
    --no-pvcs)
      INCLUDE_PVCS=false
      shift
      ;;
    --resource-limit)
      RESOURCE_LIMITS=true
      shift
      ;;
    -h|--help) usage ;;
    -*)
      error "Unknown option: $1"
      ;;
    *)
      break
      ;;
  esac
done

NAMESPACE="${1:-}"

log() {
  echo "[k8s-ns-report] $(date +'%Y-%m-%d %H:%M:%S') $*" >&2
}

if [[ -n "$NAMESPACE" ]]; then
  NAMESPACES=("$NAMESPACE")
else
  # All namespaces excluding kube-system, kube-public typically
  log "Discovering namespaces..."
  NAMESPACES=($(kubectl get namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'))
fi

if [[ ${#NAMESPACES[@]} -eq 0 ]]; then
  error "No namespaces found"
fi

generate_report() {
  local ns="$1"
  echo "Namespace: $ns"

  # Pods summary
  if $INCLUDE_PODS; then
    POD_COUNT=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | wc -l)
    RUNNING_PODS=$(kubectl get pods -n "$ns" --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    FAILED_PODS=$(kubectl get pods -n "$ns" --field-selector=status.phase=Failed --no-headers 2>/dev/null | wc -l)
    echo "  Pods: total=$POD_COUNT running=$RUNNING_PODS failed=$FAILED_PODS"
  fi

  # Deployments summary
  if $INCLUDE_DEPLOYMENTS; then
    DEPLOY_COUNT=$(kubectl get deployments -n "$ns" --no-headers 2>/dev/null | wc -l)
    echo "  Deployments: $DEPLOY_COUNT"
  fi

  # PVCs summary
  if $INCLUDE_PVCS; then
    PVC_COUNT=$(kubectl get pvc -n "$ns" --no-headers 2>/dev/null | wc -l)
    BOUND_PVC=$(kubectl get pvc -n "$ns" --field-selector=status.phase=Bound --no-headers 2>/dev/null | wc -l)
    echo "  PVCs: total=$PVC_COUNT bound=$BOUND_PVC"
  fi

  # Resource usage summary (optional, may be slow)
  if $RESOURCE_LIMITS; then
    echo "  Resource Requests/Limits (by pod):"
    kubectl get pods -n "$ns" -o json 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
containers = [c for pod in data.get('items',[]) for c in pod.get('spec',{}).get('containers',[])]
total_cpu_req = sum(c.get('resources',{}).get('requests',{}).get('cpu','0') for c in containers)
total_mem_req = sum(c.get('resources',{}).get('requests',{}).get('memory','0') for c in containers)
total_cpu_lim = sum(c.get('resources',{}).get('limits',{}).get('cpu','0') for c in containers)
total_mem_lim = sum(c.get('resources',{}).get('limits',{}).get('memory','0') for c in containers)
print(f\"    CPU Req: {total_cpu_req}, CPU Lim: {total_cpu_lim}\")
print(f\"    Mem Req: {total_mem_req}, Mem Lim: {total_mem_lim}\")
"
  fi

  echo
}

log "Generating namespace report..."
log "Format: $OUTPUT_FORMAT"

if [[ "$OUTPUT_FORMAT" == "json" ]]; then
  # Emit JSON structure
  echo "{"
  for ns in "${NAMESPACES[@]}"; do
    # Build JSON snippet per namespace (simplified)
    echo "  \"$ns\": {"
    # Could expand with actual data; for now just placeholder
    echo "    \"status\": \"ok\""
    echo -n "  }"
    [[ $ns != "${NAMESPACES[-1]}" ]] && echo ","
  done
  echo "}"
else
  for ns in "${NAMESPACES[@]}"; do
    generate_report "$ns"
  done
fi

log "Report complete."
