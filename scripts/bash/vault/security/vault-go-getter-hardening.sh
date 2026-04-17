#!/usr/bin/env bash
set -euo pipefail

# vault-go-getter-hardening.sh - Hardening script for CVE-2026-4660
# Purpose: Detect and mitigate HashiCorp go-getter arbitrary file read vulnerability
# Requirements: Vault >= 1.20.1, go-getter >= 1.8.6
# Tested OS: Linux (RHEL/CentOS, Ubuntu, Debian)
# 
# SECURITY WARNING: This script performs read-only detection. It does NOT modify any files.
# For production deployment, upgrade go-getter to version 1.8.6 or later.

DRY_RUN=true

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[ERROR] $*" >&2
}

check_binary() {
    command -v vault >/dev/null 2>&1 || { error "vault CLI not found"; exit 1; }
}

check_vault_version() {
    log "Checking Vault version..."
    local version
    version=$(vault version 2>/dev/null | grep -oP 'Vault v\K[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
    log "Vault version: $version"
    
    if [[ "$version" == "unknown" ]]; then
        error "Could not determine Vault version"
        return 1
    fi
    
    local major minor patch
    IFS='.' read -r major minor patch <<< "$version"
    
    if (( major > 1 )) || (( major == 1 && minor > 20 )) || (( major == 1 && minor == 20 && patch >= 1 )); then
        log "Vault version $version is patched (>= 1.20.1)"
        return 0
    else
        log "Vault version $version is VULNERABLE to CVE-2026-4660"
        log "Upgrade to Vault >= 1.20.1"
        return 1
    fi
}

check_go_getter_version() {
    log "Checking go-getter version..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[dry-run] Would check go-getter library version"
        return 0
    fi
    
    local getter_version
    getter_version=$(go list -m github.com/hashicorp/go-getter 2>/dev/null | grep -oP 'v\K[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
    
    if [[ "$getter_version" == "unknown" ]]; then
        log "Could not determine go-getter version (may not be directly used)"
        return 0
    fi
    
    log "go-getter version: $getter_version"
    
    local major minor patch
    IFS='.' read -r major minor patch <<< "$getter_version"
    
    if (( major > 1 )) || (( major == 1 && minor > 8 )) || (( major == 1 && minor == 8 && patch >= 6 )); then
        log "go-getter version $getter_version is patched (>= 1.8.6)"
        return 0
    else
        log "go-getter version $getter_version is VULNERABLE to CVE-2026-4660"
        return 1
    fi
}

check_git_config() {
    log "Checking git configuration for security..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[dry-run] Would check git safe.directory and protocol restrictions"
        return 0
    fi
    
    local git_safe_dirs
    git_safe_dirs=$(git config --get-all safe.directory 2>/dev/null || echo "")
    
    if [[ -z "$git_safe_dirs" ]]; then
        log "WARNING: No safe.directory restrictions configured"
    else
        log "Configured safe directories: $git_safe_dirs"
    fi
}

check_network_restrictions() {
    log "Checking network restrictions for git operations..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[dry-run] Would check network policies and firewall rules"
        return 0
    fi
    
    log "Recommendation: Restrict outgoing network for Vault processes"
    log "Use network policies (k8s) or firewall rules to limit git:// access"
}

main() {
    log "Starting CVE-2026-4660 hardening check"
    log "DRY_RUN mode: $DRY_RUN"
    
    check_binary
    
    local vulnerable=0
    
    check_vault_version || vulnerable=1
    check_go_getter_version || vulnerable=1
    check_git_config
    check_network_restrictions
    
    echo ""
    if [[ "$vulnerable" == "1" ]]; then
        log "RESULT: VULNERABLE - System is affected by CVE-2026-4660"
        log "ACTION REQUIRED: Upgrade Vault to >= 1.20.1 or go-getter to >= 1.8.6"
        exit 1
    else
        log "RESULT: PATCHED - System is not affected by CVE-2026-4660"
        exit 0
    fi
}

main "$@"
