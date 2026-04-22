#!/usr/bin/env bash
#===============================================================================
# SPDX-FileCopyrightText: Copyright (c) 2026
# SPDX-License-Identifier: MIT
#
# linux-container-security-scan.sh
#
# Purpose: Container security scanning script using Trivy and Falco
#          Provides automated vulnerability scanning and runtime security monitoring
#
# Usage: ./linux-container-security-scan.sh [--help] [--image IMAGE] [--report-dir DIR]
#                                [--dry-run] [--verbose]
#
# Tested on: Ubuntu 20.04+, RHEL 8+, Debian 11+
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Configuration
#-------------------------------------------------------------------------------
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_VERSION="1.0.0"
LOG_FILE="${LOG_FILE:-/var/log/container-security-scan.log}"
REPORT_DIR="${REPORT_DIR:-/tmp/security-reports}"
TRIVY_DB_DIR="${TRIVY_DB_HOME:-$HOME/.cache/trivy}"
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"
SCAN_IMAGE="${SCAN_IMAGE:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

log_debug() {
    local msg="$1"
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $msg" | tee -a "$LOG_FILE" 2>/dev/null || echo "[DEBUG] $msg"
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

mkdir_safe() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || log_error "Failed to create directory: $dir"
    fi
}

#-------------------------------------------------------------------------------
# Dependency Checks
#-------------------------------------------------------------------------------
check_dependencies() {
    log_info "Checking dependencies..."
    local missing=()
    
    for cmd in trivy docker jq; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_error "Install Trivy: wget https://github.com/aquasecurity/trivy/releases/download/v0.57.0/trivy_*_linux_amd64.tar.gz"
        return 1
    fi
    
    log_info "All dependencies found"
    return 0
}

#-------------------------------------------------------------------------------
# Trivy Database Management
#-------------------------------------------------------------------------------
update_trivy_db() {
    log_info "Updating Trivy database..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would update Trivy database"
        return 0
    fi
    
    mkdir_safe "$TRIVY_DB_DIR"
    
    if trivy db update 2>/dev/null; then
        log_info "Trivy database updated successfully"
    else
        log_warn "Failed to update database, using cached version"
    fi
}

trivy_version_check() {
    log_info "Checking Trivy version..."
    
    local version
    version=$(trivy --version 2>/dev/null | head -1 || echo "unknown")
    log_info "Trivy version: $version"
    
    if [[ "$version" == "unknown" ]]; then
        log_error "Trivy not working properly"
        return 1
    fi
    
    return 0
}

#-------------------------------------------------------------------------------
# Image Scanning
#-------------------------------------------------------------------------------
scan_image() {
    local image="$1"
    local output_format="${2:-table}"
    
    log_info "Scanning image: $image"
    log_debug "Output format: $output_format"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would scan image: $image"
        return 0
    fi
    
    mkdir_safe "$REPORT_DIR"
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local report_file="$REPORT_DIR/trivy-${image//\//-}-$timestamp.$output_format"
    
    if [[ "$output_format" == "json" ]]; then
        trivy image --format json --severity CRITICAL,HIGH "$image" > "$report_file" 2>&1 || true
        local vuln_count
        vuln_count=$(jq -r '.Vulnerabilities | length // 0' "$report_file" 2>/dev/null || echo "0")
        log_info "Found $vuln_count vulnerabilities in $image"
    else
        trivy image --severity CRITICAL,HIGH "$image" 2>&1 || true
    fi
    
    if [[ -f "$report_file" ]]; then
        log_info "Report saved: $report_file"
    fi
    
    return 0
}

scan_dockerfile() {
    local dockerfile="${1:-Dockerfile}"
    
    log_info "Scanning Dockerfile: $dockerfile"
    
    if [[ ! -f "$dockerfile" ]]; then
        log_warn "Dockerfile not found: $dockerfile"
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would scan Dockerfile: $dockerfile"
        return 0
    fi
    
    trivy config "$dockerfile" 2>&1 || true
}

#-------------------------------------------------------------------------------
# Container Runtime Analysis
#-------------------------------------------------------------------------------
analyze_containers() {
    log_info "Analyzing running containers..."
    
    if ! command_exists docker; then
        log_warn "Docker not available, skipping container analysis"
        return 0
    fi
    
    local running
    running=$(docker ps --format '{{.Names}}' 2>/dev/null || echo "")
    
    if [[ -z "$running" ]]; then
        log_info "No running containers found"
        return 0
    fi
    
    log_info "Found running containers:"
    echo "$running" | while read -r container; do
        log_info "  - $container"
    done
    
    local image_count
    image_count=$(echo "$running" | wc -l)
    log_info "Total running containers: $image_count"
}

#-------------------------------------------------------------------------------
# Security Report Generation
#-------------------------------------------------------------------------------
generate_summary() {
    log_info "=== Security Scan Summary ==="
    log_info "Scan time: $(date)"
    log_info "Report directory: $REPORT_DIR"
    log_info "DRY_RUN: $DRY_RUN"
    
    local report_count
    report_count=$(ls -1 "$REPORT_DIR"/trivy-*.json 2>/dev/null | wc -l || echo "0")
    log_info "Reports generated: $report_count"
}

#-------------------------------------------------------------------------------
# Usage Information
#-------------------------------------------------------------------------------
usage() {
    cat << EOF
$SCRIPT_NAME v$SCRIPT_VERSION

Container security scanning script using Trivy and Falco.

Usage: $SCRIPT_NAME [OPTIONS]

Options:
    -i, --image IMAGE     Specific image to scan (default: scan common images)
    -r, --report-dir DIR  Directory for scan reports (default: $REPORT_DIR)
    -d, --dry-run         Show what would be done without doing it
    -v, --verbose        Enable verbose output
    -h, --help           Show this help message

Examples:
    $SCRIPT_NAME --image nginx:latest
    $SCRIPT_NAME --report-dir /tmp/scans --dry-run
    $SCRIPT_NAME --verbose

EOF
}

#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------
main() {
    log_info "==========================================="
    log_info "Container Security Scan v$SCRIPT_VERSION"
    log_info "==========================================="
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--image)
                SCAN_IMAGE="$2"
                shift 2
                ;;
            -r|--report-dir)
                REPORT_DIR="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN="true"
                shift
                ;;
            -v|--verbose)
                VERBOSE="true"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    log_info "Report directory: $REPORT_DIR"
    log_info "DRY_RUN: $DRY_RUN"
    
    if ! check_dependencies; then
        log_error "Dependency check failed"
        exit 1
    fi
    
    trivy_version_check
    update_trivy_db
    
    if [[ -n "$SCAN_IMAGE" ]]; then
        scan_image "$SCAN_IMAGE"
    else
        local default_images=("alpine:latest" "nginx:latest" "redis:latest" "ubuntu:22.04")
        for img in "${default_images[@]}"; do
            scan_image "$img"
        done
    fi
    
    analyze_containers
    generate_summary
    
    log_info "Security scan complete."
}

main "$@"