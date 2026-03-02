#!/usr/bin/env bash
################################################################################
# k8s-drain-node.sh
#
# Purpose: Safely drain a Kubernetes node, evicting pods gracefully.
# Usage: k8s-drain-node.sh <node-name> [options]
# Requirements: kubectl configured with cluster admin privileges.
# Safety: Supports --dry-run; requires confirmation for destructive operations.
#
# Options:
#   --dry-run           Show what would be done without executing
#   --force             Force drain even if pods not managed by ReplicationController
#   --ignore-daemonsets Ignore DaemonSet pods (don't require --force)
#   --delete-emptydir-data Delete pods using emptyDir (data will be lost)
#   --timeout <seconds> Time to wait per pod (default: 120)
################################################################################

set -euo pipefail

DRY_RUN=false
FORCE=false
IGNORE_DAEMONSETS=false
DELETE_EMPTYDIR=false
TIMEOUT=120

log() {
  echo "[k8s-drain] $(date +'%Y-%m-%d %H:%M:%S') $*" >&2
}

error() {
  echo "[k8s-drain][ERROR] $*" >&2
  exit 1
}

usage() {
  grep '^#' "$0" | cut -c4- | head -n 20 >&2
  exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --force) FORCE=true; shift ;;
    --ignore-daemonsets) IGNORE_DAEMONSETS=true; shift ;;
    --delete-emptydir-data) DELETE_EMPTYDIR=true; shift ;;
    --timeout)
      TIMEOUT="$2"
      shift 2
      ;;
    -h|--help) usage ;;
    -*)
      error "Unknown option: $1"
      ;;
    *)
      NODE_NAME="$1"
      shift
      ;;
  esac
done

[[ -z "${NODE_NAME:-}" ]] && usage

log "Preparing to drain node: $NODE_NAME"
log "Dry run: $DRY_RUN"

# Build kubectl drain arguments
DRAIN_ARGS=("--timeout=${TIMEOUT}s")
$FORCE && DRAIN_ARGS+=("--force")
$IGNORE_DAEMONSETS && DRAIN_ARGS+=("--ignore-daemonsets")
$DELETE_EMPTYDIR && DRAIN_ARGS+=("--delete-emptydir-data")

# Show pods that would be affected
log "Fetching pods on node $NODE_NAME..."
kubectl get pods --all-namespaces --field-selector spec.nodeName="$NODE_NAME" -o wide || error "Failed to list pods"

if $DRY_RUN; then
  log "DRY RUN: Would execute: kubectl drain $NODE_NAME ${DRAIN_ARGS[*]}"
  log "DRY RUN: Check the pod list above to verify."
  exit 0
fi

# Confirmation
echo
read -p "This will evict all pods on node $NODE_NAME. Continue? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  log "Aborted by user."
  exit 0
fi

# Execute drain
log "Draining node..."
if kubectl drain "$NODE_NAME" "${DRAIN_ARGS[@]}"; then
  log "Node $NODE_NAME drained successfully."
  exit 0
else
  error "Drain failed. Check pod eviction policies and try with additional flags if needed."
fi
