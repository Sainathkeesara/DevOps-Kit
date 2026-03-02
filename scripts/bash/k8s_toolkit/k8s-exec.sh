#!/usr/bin/env bash
################################################################################
# k8s-exec.sh
#
# Purpose: Execute a command inside a pod with improved ergonomics.
# Usage: k8s-exec.sh <pod-name> <command> [namespace] [options]
# Requirements: kubectl configured with exec access to the pod.
# Safety: Non-destructive (executes user-provided command).
#
# Options:
#   --container <name>   Which container to use (for multi-container pods)
#   -i                  Keep stdin open (for interactive commands)
#   -t                  Allocate a TTY (for interactive sessions)
#   --shell <path>      Shell to use when none specified (default: /bin/bash, fallback /bin/sh)
#
# Examples:
#   k8s-exec.sh mypod ls /tmp
#   k8s-exec.sh mypod --container sidecar -it sh
################################################################################

set -euo pipefail

CONTAINER=
INTERACTIVE_STDIN=false
INTERACTIVE_TTY=false
SHELL_PATH="/bin/bash"

usage() {
  grep '^#' "$0" | cut -c4- | head -n 25 >&2
  exit 1
}

error() {
  echo "[k8s-exec][ERROR] $*" >&2
  exit 1
}

# Parse options before positional args
OPTIONS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --container)
      CONTAINER="$2"
      OPTIONS+=("--container" "$CONTAINER")
      shift 2
      ;;
    -i)
      INTERACTIVE_STDIN=true
      shift
      ;;
    -t)
      INTERACTIVE_TTY=true
      shift
      ;;
    --shell)
      SHELL_PATH="$2"
      shift 2
      ;;
    -*)
      error "Unknown option: $1"
      ;;
    *)
      break
      ;;
  esac
done

# Positional args: pod-name, command..., [namespace?]
if [[ $# -lt 1 ]]; then
  usage
fi

POD_NAME="$1"
shift

# The remaining arguments form the command to execute. Last arg may be namespace.
COMMAND=("$@")

# If last arg looks like a namespace (no spaces, lowercase, doesn't start with -)
if [[ ${#COMMAND[@]} -gt 0 ]]; then
  LAST_ARG="${COMMAND[-1]}"
  if [[ ! "$LAST_ARG" =~ ^- ]] && [[ "$LAST_ARG" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]] && [[ ${#COMMAND[@]} -gt 1 ]]; then
    # Assume it's a namespace if there's more than 1 command arg? ambiguous but possible common pattern:
    # pod cmd namespace
    NAMESPACE="$LAST_ARG"
    unset 'COMMAND[${#COMMAND[@]}-1]'
  fi
else
  error "No command specified"
fi

# If no command left after removing namespace, use shell
if [[ ${#COMMAND[@]} -eq 0 ]]; then
  COMMAND=("$SHELL_PATH")
fi

log() {
  echo "[k8s-exec] $(date +'%Y-%m-%d %H:%M:%S') $*" >&2
}

log "Executing in pod: $POD_NAME"
log "Command: ${COMMAND[*]} ${NAMESPACE:+in namespace $NAMESPACE}"

# Build kubectl args
KUBECTL_ARGS=()
[[ -n "${NAMESPACE:-}" ]] && KUBECTL_ARGS+=("-n" "$NAMESPACE")
$INTERACTIVE_STDIN && KUBECTL_ARGS+=("-i")
$INTERACTIVE_TTY && KUBECTL_ARGS+=("-t")
[[ -n "$CONTAINER" ]] && KUBECTL_ARGS+=("-c" "$CONTAINER")

# Execute
kubectl exec "$POD_NAME" "${KUBECTL_ARGS[@]}" -- "${COMMAND[@]}"
