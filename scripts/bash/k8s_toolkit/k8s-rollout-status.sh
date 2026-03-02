#!/usr/bin/env bash
################################################################################
# k8s-rollout-status.sh
#
# Purpose: Monitor and report Kubernetes deployment/rollout status.
# Usage: k8s-rollout-status.sh <deployment-name> [namespace]
# Requirements: kubectl configured with read access to the cluster.
# Safety: Non-destructive, only reads cluster state.
#
# Arguments:
#   deployment-name     Name of the Deployment, DaemonSet, or StatefulSet
#   namespace           Namespace (default: current context namespace)
#
# Options:
#   --watch            Continuously watch rollout status (default: false)
#   --timeout <seconds> Timeout for rollout in seconds (default: 600)
#   --format <type>    Output format: text, json, yaml (default: text)
################################################################################

set -euo pipefail

WATCH=false
TIMEOUT=600
FORMAT="text"

log() {
  echo "[k8s-rollout] $(date +'%Y-%m-%d %H:%M:%S') $*" >&2
}

error() {
  echo "[k8s-rollout][ERROR] $*" >&2
  exit 1
}

usage() {
  grep '^#' "$0" | cut -c4- | head -n 25 >&2
  exit 1
}

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --watch) WATCH=true; shift ;;
    --timeout)
      TIMEOUT="$2"
      shift 2
      ;;
    --format)
      FORMAT="$2"
      shift 2
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

# Positional arguments after options
if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
fi

DEPLOYMENT="$1"
NAMESPACE="${2:-}"

log "Checking rollout status for $DEPLOYMENT ${NAMESPACE:+in namespace $NAMESPACE}"

# Build kubectl arguments
KUBECTL_ARGS=()
[[ -n "$NAMESPACE" ]] && KUBECTL_ARGS+=("-n" "$NAMESPACE")

# Check if resource exists
if ! kubectl get deployment "${KUBECTL_ARGS[@]}" "$DEPLOYMENT" &>/dev/null; then
  # Try DaemonSet
  if kubectl get daemonset "${KUBECTL_ARGS[@]}" "$DEPLOYMENT" &>/dev/null; then
    RESOURCE_TYPE="daemonset"
  elif kubectl get statefulset "${KUBECTL_ARGS[@]}" "$DEPLOYMENT" &>/dev/null; then
    RESOURCE_TYPE="statefulset"
  else
    error "Resource '$DEPLOYMENT' not found as Deployment, DaemonSet, or StatefulSet"
  fi
else
  RESOURCE_TYPE="deployment"
fi

log "Resource type: $RESOURCE_TYPE"

if $WATCH; then
  log "Watching rollout (timeout: ${TIMEOUT}s)..."
  if ! timeout "${TIMEOUT}s" kubectl rollout status "$RESOURCE_TYPE" "$DEPLOYMENT" "${KUBECTL_ARGS[@]}"; then
    error "Rollout did not complete within ${TIMEOUT} seconds"
  fi
else
  # Single status check
  log "Fetching rollout status..."
  kubectl rollout status "$RESOURCE_TYPE" "$DEPLOYMENT" "${KUBECTL_ARGS[@]}" --timeout="${TIMEOUT}s"
fi

log "Rollout check completed."
