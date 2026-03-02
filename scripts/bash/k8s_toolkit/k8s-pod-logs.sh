#!/usr/bin/env bash
################################################################################
# k8s-pod-logs.sh
#
# Purpose: Fetch logs from a pod with enhanced options (tail, since, container).
# Usage: k8s-pod-logs.sh <pod-name> [namespace] [options]
# Requirements: kubectl configured with read access to pods/logs.
# Safety: Non-destructive.
#
# Options (can be placed after pod-name or before):
#   --tail <lines>      Number of lines to show from end (default: 100)
#   --since <duration>   Show logs since duration (e.g., 10m, 1h, 2d)
#   --container <name>   Container name (for multi-container pods)
#   --follow            Stream logs in real-time (like -f)
#   --previous          Get logs from previous instance of a container
#   -f                  Alias for --follow
################################################################################

set -euo pipefail

TAIL=100
SINCE=
CONTAINER=
FOLLOW=false
PREVIOUS=false

usage() {
  grep '^#' "$0" | cut -c4- | head -n 25 >&2
  exit 1
}

log() {
  echo "[k8s-logs] $(date +'%Y-%m-%d %H:%M:%S') $*" >&2
}

error() {
  echo "[k8s-logs][ERROR] $*" >&2
  exit 1
}

# Simple option parsing (supports options before/after required args)
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tail)
      TAIL="$2"
      shift 2
      ;;
    --since)
      SINCE="$2"
      shift 2
      ;;
    --container)
      CONTAINER="$2"
      shift 2
      ;;
    --follow)
      FOLLOW=true
      shift
      ;;
    --previous)
      PREVIOUS=true
      shift
      ;;
    -f)
      FOLLOW=true
      shift
      ;;
    -*)
      error "Unknown option: $1"
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

# Set positional args
if [[ ${#POSITIONAL_ARGS[@]} -lt 1 || ${#POSITIONAL_ARGS[@]} -gt 2 ]]; then
  usage
fi

POD_NAME="${POSITIONAL_ARGS[0]}"
NAMESPACE="${POSITIONAL_ARGS[1]:-}"

log "Fetching logs for pod: $POD_NAME ${NAMESPACE:+in namespace $NAMESPACE}"

# Build kubectl args
KUBECTL_ARGS=()
[[ -n "$NAMESPACE" ]] && KUBECTL_ARGS+=("-n" "$NAMESPACE")
[[ -n "$CONTAINER" ]] && KUBECTL_ARGS+=("-c" "$CONTAINER")
[[ "$TAIL" != "all" ]] && KUBECTL_ARGS+=("--tail=$TAIL")
[[ -n "$SINCE" ]] && KUBECTL_ARGS+=("--since=$SINCE")
$PREVIOUS && KUBECTL_ARGS+=("--previous")
$FOLLOW && KUBECTL_ARGS+=("-f")

kubectl logs "$POD_NAME" "${KUBECTL_ARGS[@]}"
