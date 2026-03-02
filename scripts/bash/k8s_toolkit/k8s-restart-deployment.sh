#!/usr/bin/env bash
################################################################################
# k8s-restart-deployment.sh
#
# Purpose: Trigger a safe restart of a Kubernetes Deployment by updating its
#          pod template annotation (rolls pods using the same image).
# Usage: k8s-restart-deployment.sh <deployment-name> [namespace]
# Requirements: kubectl configured with edit access to deployments.
# Safety: Requires explicit confirmation; supports --dry-run.
#
# Options:
#   --dry-run         Show the patch command without executing
#   --timeout <sec>   Wait for rollout completion timeout (default: 600)
################################################################################

set -euo pipefail

DRY_RUN=false
TIMEOUT=600

log() {
  echo "[k8s-restart] $(date +'%Y-%m-%d %H:%M:%S') $*" >&2
}

error() {
  echo "[k8s-restart][ERROR] $*" >&2
  exit 1
}

usage() {
  grep '^#' "$0" | cut -c4- | head -n 20 >&2
  exit 1
}

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --timeout)
      TIMEOUT="$2"
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

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
fi

DEPLOYMENT="$1"
NAMESPACE="${2:-}"

log "Preparing to restart deployment: $DEPLOYMENT ${NAMESPACE:+in namespace $NAMESPACE}"

# Verify deployment exists
KUBECTL_ARGS=()
[[ -n "$NAMESPACE" ]] && KUBECTL_ARGS+=("-n" "$NAMESPACE")
if ! kubectl get deployment "${KUBECTL_ARGS[@]}" "$DEPLOYMENT" &>/dev/null; then
  error "Deployment '$DEPLOYMENT' not found"
fi

# Generate restart timestamp annotation
RESTART_ANNOTATION="k8s-restartTimestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

log "Will patch deployment with annotation: $RESTART_ANNOTATION"
log "Dry run: $DRY_RUN"

if $DRY_RUN; then
  CMD=(kubectl patch deployment "$DEPLOYMENT" "${KUBECTL_ARGS[@]}" -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"$RESTART_ANNOTATION\":\"\"}}}}}")
  echo "DRY RUN: ${CMD[*]}"
  exit 0
fi

# Confirmation
echo
read -p "This will restart the deployment $DEPLOYMENT. Continue? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  log "Aborted by user."
  exit 0
fi

# Apply patch to restart
if kubectl patch deployment "$DEPLOYMENT" "${KUBECTL_ARGS[@]}" -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"restartedAt\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}}}}" ; then
  log "Deployment patched. Starting rollout..."
  # Wait for rollout to complete
  kubectl rollout status deployment "$DEPLOYMENT" "${KUBECTL_ARGS[@]}" --timeout="${TIMEOUT}s"
  log "Restart completed successfully."
else
  error "Failed to patch deployment"
fi
