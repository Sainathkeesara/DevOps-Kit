#!/usr/bin/env bash
#===============================================================================
# SPDX-FileCopyrightText: Copyright (c) 2026
# SPDX-License-Identifier: MIT
#
# mcp-server-kubernetes-hardening.sh
# 
# Purpose: Hardening script for CVE-2026-39884 - mcp-server-kubernetes
#          argument injection RCE vulnerability
#
# CVE: CVE-2026-39884
# CVSS: 8.3 HIGH
# Affected versions: mcp-server-kubernetes <= 3.4.0
# Fixed in version: 3.5.0
#
# Usage: ./mcp-server-kubernetes-hardening.sh [--dry-run] [--check-only] [--verbose]
#
# Tested on: Ubuntu 22.04, Debian 12, RHEL 9, Amazon Linux 2023
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Configuration
#-------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
LOG_FILE="/var/log/mcp-server-kubernetes-hardening.log"
DRY_RUN="${DRY_RUN:-false}"
CHECK_ONLY="${CHECK_ONLY:-false}"
VERBOSE="${VERBOSE:-false}"

# CVE Information
CVE_ID="CVE-2026-39884"
AFFECTED_VERSIONS="<= 3.4.0"
FIXED_VERSION="3.5.0"
CVSS_SCORE="8.3"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#-------------------------------------------------------------------------------
# Functions
#-------------------------------------------------------------------------------

log_info() {
    local msg="$1"
    echo -e "${GREEN}[INFO]${NC} $msg" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "[INFO] $msg"
}

log_warn() {
    local msg="$1"
    echo -e "${YELLOW}[WARN]${NC} $msg" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "[WARN] $msg"
}

log_error() {
    local msg="$1"
    echo -e "${RED}[ERROR]${NC} $msg" >&2 | tee -a "$LOG_FILE" 2>/dev/null || echo -e "[ERROR] $msg" >&2
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        local msg="$1"
        echo -e "${BLUE}[DEBUG]${NC} $msg" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "[DEBUG] $msg"
    fi
}

dry_run_exec() {
    local cmd="$1"
    local description="$2"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Would execute: $description"
        log_verbose "Command: $cmd"
    else
        log_verbose "Executing: $description"
        eval "$cmd"
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get installed version of mcp-server-kubernetes
get_mcp_version() {
    local version=""
    
    # Try npm first (if installed via npm)
    if command_exists npm; then
        version=$(npm list -g @modelcontextprotocol/server-kubernetes 2>/dev/null | grep '@modelcontextprotocol/server-kubernetes' | awk -F'@modelcontextprotocol/server-kubernetes@' '{print $2}' | head -1 || echo "")
    fi
    
    # Try pip/uv for Python installation
    if [[ -z "$version" ]] && command_exists uv; then
        version=$(uv pip show mcp-server-kubernetes 2>/dev/null | grep '^Version:' | awk '{print $2}' || echo "")
    fi
    
    echo "$version"
}

# Check if mcp-server-kubernetes is installed
is_mcp_installed() {
    if command_exists npm; then
        npm list -g @modelcontextprotocol/server-kubernetes >/dev/null 2>&1 && return 0
    fi
    if command_exists uv; then
        uv pip show mcp-server-kubernetes >/dev/null 2>&1 && return 0
    fi
    return 1
}

# Check version vulnerability
check_vulnerable() {
    local version="$1"
    
    if [[ -z "$version" ]]; then
        return 2  # Unknown
    fi
    
    # Extract major.minor.patch
    local major minor patch
    IFS='.' read -r major minor patch <<< "$version"
    
    # Compare versions
    # Version 3.5.0+ is fixed
    if [[ "$major" -gt 3 ]]; then
        return 1  # Not vulnerable ( newer major)
    elif [[ "$major" -eq 3 && "$minor" -gt 5 ]]; then
        return 1  # Not vulnerable (3.6+)
    elif [[ "$major" -eq 3 && "$minor" -eq 5 && "$patch" -ge 0 ]]; then
        return 1  # Not vulnerable (3.5.0+)
    else
        return 0  # Vulnerable
    fi
}

#-------------------------------------------------------------------------------
# Main logic
#-------------------------------------------------------------------------------

main() {
    log_info "==========================================="
    log_info "mcp-server-kubernetes Hardening Script"
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
            --verbose)
                VERBOSE="true"
                shift
                ;;
            --help|-h)
                echo "Usage: $SCRIPT_NAME [--dry-run] [--check-only] [--verbose]"
                echo ""
                echo "Options:"
                echo "  --dry-run     Show what would be done without making changes"
                echo "  --check-only Only check vulnerability status, don't remediate"
                echo "  --verbose     Enable verbose output"
                echo ""
                echo "This script checks for CVE-2026-39884 in mcp-server-kubernetes"
                echo "and provides remediation recommendations."
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
    
    # Step 1: Check if mcp-server-kubernetes is installed
    log_info "Step 1: Checking if mcp-server-kubernetes is installed..."
    
    if ! is_mcp_installed; then
        log_info "mcp-server-kubernetes is NOT installed. System is not vulnerable."
        log_info "To install the secure version (${FIXED_VERSION}+):"
        log_info "  npm install -g @modelcontextprotocol/server-kubernetes@${FIXED_VERSION}"
        exit 0
    fi
    
    local version
    version=$(get_mcp_version)
    log_info "Found mcp-server-kubernetes version: ${version:-unknown}"
    
    # Step 2: Check vulnerability status
    log_info "Step 2: Checking vulnerability status..."
    
    local vulnerable
    check_vulnerable "$version"
    vulnerable=$?
    
    if [[ $vulnerable -eq 1 ]]; then
        log_info "System is NOT vulnerable. Version $version is >= $FIXED_VERSION"
        exit 0
    elif [[ $vulnerable -eq 2 ]]; then
        log_warn "Could not determine version. Assuming vulnerable."
        log_info "Please verify manually and upgrade to ${FIXED_VERSION}+"
    else
        log_error "System IS VULNERABLE to $CVE_ID"
        log_error "Version $version is in affected range: $AFFECTED_VERSIONS"
    fi
    
    # Step 3: Provide remediation guidance (check-only mode)
    if [[ "$CHECK_ONLY" == "true" ]]; then
        log_info "Check-only mode: No remediation performed."
        exit 1
    fi
    
    # Step 4: Remdiation steps
    log_info "Step 3: Providing remediation guidance..."
    
    echo ""
    echo "=============================================="
    echo "REMEDIATION STEPS FOR $CVE_ID"
    echo "=============================================="
    echo ""
    echo "1. UPGRADE TO FIXED VERSION"
    echo "   The vulnerability is fixed in version $FIXED_VERSION"
    echo ""
    echo "   # If installed via npm:"
    echo "   npm install -g @modelcontextprotocol/server-kubernetes@${FIXED_VERSION}"
    echo ""
    echo "   # If installed via pip/uv:"
    echo "   uv pip install --upgrade mcp-server-kubernetes>=${FIXED_VERSION}"
    echo ""
    
    echo "2. VERIFY UPGRADE"
    echo "   After upgrading, verify the fix:"
    echo "   npm list -g @modelcontextprotocol/server-kubernetes"
    echo ""
    
    echo "3. ADDITIONAL HARDENING"
    echo "   - Run with limited permissions (non-root)"
    echo "   - Use Kubernetes RBAC to restrict mcp-server permissions"
    echo "   - Network policies to limit pod communication"
    echo "   - Enable audit logging for API server"
    echo ""
    
    echo "=============================================="
    
    # Dry-run: Don't actually do remediation
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Dry-run complete - no changes made"
    else
        log_info "Review the remediation steps above and apply manually"
    fi
    
    log_info "Done."
}

# Run main function
main "$@"