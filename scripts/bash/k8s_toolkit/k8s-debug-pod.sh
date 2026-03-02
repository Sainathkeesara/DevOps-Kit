#!/usr/bin/env bash
################################################################################
# k8s-debug-pod.sh
#
# Purpose: Comprehensive pod debugging utility – shows pod info, events, logs,
#          and execs into the pod for interactive troubleshooting.
# Usage: k8s-debug-pod.sh <pod-name> [namespace]
# Requirements: kubectl with get/pod/exec/log access.
# Safety: Non-destructive (read-only except optional exec).
#
# Options:
#   --shell <path>       Shell to use when exec-ing (default: /bin/bash)
#   --no-exec            Do not exec into the pod (only view info/logs)
#   --logs-tail <n>      Number of log lines to show (default: 200)
#   --since <duration>   Show logs since duration (e.g., 5m)
#   --previous           Include previous container logs if available
################################################################################

set -euo pipefail

SHELL_PATH="/bin/bash"
NO_EXEC=false
LOGS_TAIL=200
SINCE=
PREVIOUS=false

usage() {
  grep '^#' "$0" | cut -c4- | head -n 30 >&2
  exit 1
}

error() {
  echo "[k8s-debug][ERROR] $*" >&2
  exit 1
}

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --shell)
      SHELL_PATH="$2"
      shift 2
      ;;
    --no-exec)
      NO_EXEC=true
      shift
      ;;
    --logs-tail)
      LOGS_TAIL="$2"
      shift 2
      ;;
    --since)
      SINCE="$2"
      shift 2
      ;;
    --previous)
      PREVIOUS=true
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

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
fi

POD_NAME="$1"
NAMESPACE="${2:-}"

log() {
  echo "[k8s-debug] $(date +'%Y-%m-%d %H:%M:%S') $*" >&2
}

KUBECTL_ARGS=()
[[ -n "$NAMESPACE" ]] && KUBECTL_ARGS+=("-n" "$NAMESPACE")

log "Starting debug session for pod: $POD_NAME"

# 1. Pod details
echo "=== POD DETAILS ==="
kubectl get pod "$POD_NAME" "${KUBECTL_ARGS[@]}" -o wide || error "Pod not found"
echo

# 2. Pod YAML
echo "=== POD SPEC (YAML) ==="
kubectl get pod "$POD_NAME" "${KUBECTL_ARGS[@]}" -o yaml || true
echo

# 3. Events
echo "=== POD EVENTS ==="
kubectl get events "${KUBECTL_ARGS[@]}" --field-selector involvedObject.name="$POD_NAME" --sort-by=.metadata.creationTimestamp || true
echo

# 4. Logs (all containers)
echo "=== POD LOGS ==="
CONTAINERS=$(kubectl get pod "$POD_NAME" "${KUBECTL_ARGS[@]}" -o jsonpath='{range .spec.containers[*]}{.name}{"\n"}{end}')
for container in $CONTAINERS; do
  echo "--- Container: $container ---"
  LOG_ARGS=()
  [[ -n "$NAMESPACE" ]] && LOG_ARGS+=("-n" "$NAMESPACE")
  [[ "$PREVIOUS" = true ]] && LOG_ARGS+=("--previous")
  [[ -n "$SINCE" ]] && LOG_ARGS+=("--since=$SINCE")
  LOG_ARGS+=("--tail=$LOGS_TAIL")
  kubectl logs "$POD_NAME" "${LOG_ARGS[@]}" -c "$container" || echo "  [No logs available]"
  echo
done

# 5. Optional exec
if $NO_EXEC; then
  log "Debug info displayed. Skipping exec due to --no-exec."
  exit 0
fi

# Try to exec into first container
DEFAULT_CONTAINER=$(echo "$CONTAINERS" | head -n1)
echo "=== EXEC DEBUG SHELL ==="
log "Attempting to exec into pod $POD_NAME (container: $DEFAULT_CONTAINER)..."

if kubectl exec "$POD_NAME" "${KUBECTL_ARGS[@]}" -c "$DEFAULT_CONTAINER" -it -- "$SHELL_PATH"; then
  log "Exec session ended."
else
  log "Exec failed. This may be normal if the pod is not running or lacks $SHELL_PATH."
  log "Try: --shell /bin/sh or check container image."
fi
