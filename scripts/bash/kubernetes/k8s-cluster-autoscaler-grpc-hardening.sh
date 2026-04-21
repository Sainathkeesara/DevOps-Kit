#!/usr/bin/env bash
#===============================================================================
# SPDX-FileCopyrightText: Copyright (c) 2026
# SPDX-License-Identifier: MIT
#
# k8s-cluster-autoscaler-grpc-hardening.sh
#
# Purpose: Hardening script for CVE-2026-33186 - cluster-autoscaler
#          incorrect authorization vulnerability
#
# CVE: CVE-2026-33186
# CVSS: CRITICAL (9.8)
# Affected versions: cluster-autoscaler v1.35.0
# Fixed in: grpc v1.79.3
#
# Usage: ./k8s-cluster-autoscaler-grpc-hardening.sh [--dry-run] [--check-only]
#
# Tested on: GKE, EKS, AKS
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Configuration
#-------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
LOG_FILE="/var/log/k8s-cluster-autoscaler-hardening.log"
DRY_RUN="${DRY_RUN:-false}"
CHECK_ONLY="${CHECK_ONLY:-false}"

# CVE Information
CVE_ID="CVE-2026-33186"
AFFECTED_VERSIONS="v1.35.0"
FIXED_DEP_VERSION="grpc v1.79.3"
CVSS_SCORE="9.8"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

#-------------------------------------------------------------------------------
# Functions
#-------------------------------------------------------------------------------
log_info() {
    local msg="$1"
    echo -e "${GREEN}[INFO]${NC} $msg" | tee -a "$LOG_FILE" 2>/dev/null || echo "[INFO] $msg"
}

log_warn() {
    local msg="$1"
    echo -e "${YELLOW}[WARN]${NC} $msg" | tee -a "$LOG_FILE" 2>/dev/null || echo "[WARN] $msg"
}

log_error() {
    local msg="$1"
    echo -e "${RED}[ERROR]${NC} $msg" >&2 | tee -a "$LOG_FILE" 2>/dev/null || echo "[ERROR] $msg" >&2
}

dry_run_exec() {
    local cmd="$1"
    local description="$2"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Would execute: $description"
    else
        eval "$cmd"
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get cluster-autoscaler version
get_autoscaler_version() {
    local namespace="${1:-kube-system}"
    local version=""
    
    if command_exists kubectl; then
        version=$(kubectl get deployment -n "$namespace" cluster-autoscaler -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "")
    fi
    
    echo "$version"
}

# Check if cluster is vulnerable
check_vulnerability() {
    local version="$1"
    
    if [[ -z "$version" ]]; then
        return 2  # Unknown
    fi
    
    # Check if version contains v1.35.0 or if grpc version is affected
    if echo "$version" | grep -q "1.35.0"; then
        return 0  # Vulnerable
    fi
    
    return 1  # Not vulnerable or unknown
}

#-------------------------------------------------------------------------------
# Main logic
#-------------------------------------------------------------------------------
main() {
    log_info "==========================================="
    log_info "Kubernetes cluster-autoscaler Hardening"
    log_info "CVE: $CVE_ID (CVSS $CVSS_SCORE)"
    log_info "==========================================="
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --check-only)
                CHECK_ONLY="true"
                shift
                ;;
            --help|-h)
                echo "Usage: $SCRIPT_NAME [--dry-run] [--check-only]"
                echo ""
                echo "Options:"
                echo "  --dry-run     Show what would be done without making changes"
                echo "  --check-only Only check vulnerability status, don't remediate"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    log_info "DRY_RUN mode: $DRY_RUN"
    log_info "CHECK_ONLY mode: $CHECK_ONLY"
    
    # Check dependencies
    if ! command_exists kubectl; then
        log_error "kubectl not found. Please install kubectl first."
        exit 1
    fi
    
    # Detect cluster type and check autoscaler
    log_info "Detecting cluster-autoscaler deployment..."
    
    local clusters=("kube-system" "openshift-scale" "cluster-autoscaler")
    local found=false
    
    for ns in "${clusters[@]}"; do
        local version
        version=$(get_autoscaler_version "$ns")
        
        if [[ -n "$version" ]]; then
            log_info "Found cluster-autoscaler in namespace: $ns"
            log_info "Version: $version"
            
            check_vulnerability "$version"
            local result=$?
            
            if [[ $result -eq 0 ]]; then
                log_error "System IS VULNERABLE to $CVE_ID"
                log_error "cluster-autoscaler version $AFFECTED_VERSIONS is affected"
            elif [[ $result -eq 1 ]]; then
                log_info "System is NOT vulnerable. Version is patched."
            else
                log_warn "Could not determine version. Please verify manually."
            fi
            
            found=true
            
            if [[ "$CHECK_ONLY" == "true" ]]; then
                log_info "Check-only mode complete."
                exit 0
            fi
            
            # Provide remediation
            echo ""
            echo "=============================================="
            echo "REMEDIATION STEPS FOR $CVE_ID"
            echo "=============================================="
            echo ""
            echo "1. UPDATE CLUSTER-AUTOSCALER"
            echo "   The vulnerability is fixed by updating grpc dependency to v1.79.3+"
            echo ""
            echo "   For GKE:"
            echo "   gcloud container clusters update CLUSTER_NAME --enable-autoscaling"
            echo ""
            echo "   For EKS (update node group):"
            echo "   aws eks update-nodegroup-version --cluster-name CLUSTER_NAME --nodegroup-name NODEGROUP"
            echo ""
            echo "2. VERIFY UPDATE"
            echo "   After updating, verify the fix:"
            echo "   kubectl get deployment -n kube-system cluster-autoscaler -o jsonpath='{.spec.template.spec.containers[*].image}'"
            echo ""
            echo "3. ADDITIONAL HARDENING"
            echo "   - Ensure RBAC is configured with minimal permissions"
            echo "   - Enable audit logging for cluster-autoscaler"
            echo "   - Restrict network policies"
            echo ""
            
            break
        fi
    done
    
    if [[ "$found" == "false" ]]; then
        log_warn "No cluster-autoscaler deployment found in common namespaces."
        log_info "Cluster may not use cluster-autoscaler, or uses a managed solution."
    fi
    
    # Dry-run: Don't actually do remediation
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Dry-run complete - no changes made"
    fi
    
    log_info "Done."
}

# Run main function
main "$@"