#!/usr/bin/env bash
# cleanup-jobs.sh - Clean up completed or failed Kubernetes jobs
# Usage: ./cleanup-jobs.sh [--namespace=<ns>] [--status=<status>] [--dry-run] [--force]
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
JOB_STATUS="succeeded"
DRY_RUN=true
FORCE=false

usage() {
    cat <<EOF
Clean up completed or failed Kubernetes jobs

Usage: $0 [options]

Options:
  --namespace=<ns>      Namespace (default: default)
  --status=<status>    Job status to clean: succeeded, failed, all (default: succeeded)
  --dry-run            Show what would be deleted (default: true)
  --force              Actually delete jobs (requires this flag)
  -h, --help           Show this help

Examples:
  # Preview deletion of succeeded jobs
  $0 --namespace=prod

  # Delete all succeeded jobs
  $0 --namespace=prod --status=succeeded --force

  # Delete all failed jobs
  $0 --namespace=prod --status=failed --force

  # Delete all completed jobs (succeeded + failed)
  $0 --namespace=prod --status=all --force
EOF
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --namespace=*)
            NAMESPACE="${1#*=}"
            ;;
        --status=*)
            JOB_STATUS="${1#*=}"
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --force)
            FORCE=true
            DRY_RUN=false
            ;;
        -h|--help)
            usage
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
    shift
done

check_prereqs() {
    if ! command -v kubectl &>/dev/null; then
        error "kubectl not found. Install: https://kubernetes.io/docs/tasks/tools/"
    fi
    
    if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
        error "Namespace '$NAMESPACE' does not exist"
    fi
}

get_jobs_to_delete() {
    local status="$1"
    local selector=""
    
    case "$status" in
        succeeded)
            selector="status.successful=1"
            ;;
        failed)
            selector="status.failed=1"
            ;;
        all)
            echo ""
            return
            ;;
        *)
            error "Invalid status: $status. Use succeeded, failed, or all"
            ;;
    esac
    
    kubectl get jobs -n "$NAMESPACE" --field-selector="$selector" -o name 2>/dev/null || true
}

main() {
    check_prereqs
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY RUN MODE - No jobs will be deleted"
    else
        log "FORCE MODE - Jobs will be permanently deleted"
    fi
    
    echo ""
    echo "Namespace: $NAMESPACE"
    echo "Status filter: $JOB_STATUS"
    echo ""
    
    local jobs
    local count=0
    
    if [[ "$JOB_STATUS" == "all" ]]; then
        jobs=$(kubectl get jobs -n "$NAMESPACE" -o name 2>/dev/null || true)
        count=$(echo "$jobs" | grep -c "job" || echo 0)
    else
        jobs=$(get_jobs_to_delete "$JOB_STATUS")
        count=$(echo "$jobs" | grep -c "job" || echo 0)
    fi
    
    if [[ "$count" -eq 0 ]]; then
        log "No jobs found matching criteria"
        exit 0
    fi
    
    echo "Jobs to process: $count"
    echo ""
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would delete:"
        echo "$jobs" | sed 's|job/|  - |g'
        echo ""
        log "Run with --force to delete"
    else
        echo "Deleting..."
        local deleted=0
        local failed=0
        
        while IFS= read -r job; do
            [[ -z "$job" ]] && continue
            local job_name="${job#job/}"
            
            if kubectl delete "$job" -n "$NAMESPACE" &>/dev/null; then
                echo "  Deleted: $job_name"
                ((deleted++)) || true
            else
                echo "  Failed: $job_name"
                ((failed++)) || true
            fi
        done <<< "$jobs"
        
        echo ""
        log "Deleted: $deleted, Failed: $failed"
    fi
}

main "$@"
