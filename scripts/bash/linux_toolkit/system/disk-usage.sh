#!/usr/bin/env bash
# =============================================================================
# Disk Usage Analyzer
# =============================================================================
# Purpose: Analyze disk usage, find large files/directories, identify old files
# Usage: ./disk-usage.sh [--dry-run] [--threshold PERCENT] [PATH]
#   --dry-run      Show what would be done without making changes
#   --threshold    Disk usage threshold for warnings (default: 80)
#   PATH           Root path to analyze (default: /)
# Requirements: bash >= 4.0, df, du, find
# Safety Notes: Read-only analysis, safe to run on any system
# =============================================================================
set -euo pipefail

DRY_RUN="${DRY_RUN:-false}"
THRESHOLD="${THRESHOLD:-80}"

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --threshold) THRESHOLD="${2:-80}"; shift ;;
        -h|--help)
            echo "Usage: $0 [--dry-run] [--threshold PERCENT] [PATH]"
            echo "  --dry-run      Show commands without executing"
            echo "  --threshold    Disk usage % to flag as warning (default: 80)"
            echo "  PATH           Root path to analyze (default: /)"
            exit 0
            ;;
    esac
done

command -v df >/dev/null 2>&1 || { echo "FATAL: df required but not found"; exit 1; }
command -v du >/dev/null 2>&1 || { echo "FATAL: du required but not found"; exit 1; }
command -v find >/dev/null 2>&1 || { echo "FATAL: find required but not found"; exit 1; }

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $*" >&2; }
die() { log "FATAL: $*"; exit 1; }

print_header() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

dry_run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo "[dry-run] would run: $*"
        return 0
    fi
    "$@"
}

list_disks() {
    print_header "Disk Usage Overview"
    if [ "$DRY_RUN" = true ]; then
        echo "[dry-run] would run: df -h | grep -vE '^tmpfs|^devtmpfs|^overlay|^none'"
    else
        df -h | grep -vE '^tmpfs|^devtmpfs|^overlay|^none'
    fi

    print_header "Disk Usage Warnings (threshold: ${THRESHOLD}%)"
    if [ "$DRY_RUN" = true ]; then
        echo "[dry-run] would run: df -h | grep -vE '^tmpfs|^devtmpfs|^overlay|^none' | awk '\$5 > ${THRESHOLD}'"
    else
        df -h | grep -vE '^tmpfs|^devtmpfs|^overlay|^none' | awk -v threshold="$THRESHOLD" '{gsub(/%/,"",$5); if ($5+0 > threshold) print "WARNING: " $1 " at " $5 " (threshold: " threshold "%)"}'
    fi
}

find_large_dirs() {
    local path="${1:-/}"
    local limit="${2:-5}"

    print_header "Top ${limit} Largest Directories in ${path}"
    if command -v du &>/dev/null; then
        if [ "$DRY_RUN" = true ]; then
            echo "[dry-run] would run: du -ah $path 2>/dev/null | sort -rh | head -$limit"
        else
            du -ah "$path" 2>/dev/null | sort -rh | head -"$limit"
        fi
    else
        if [ "$DRY_RUN" = true ]; then
            echo "[dry-run] would run: find $path -maxdepth 2 -type d -exec du -sh {} \\; 2>/dev/null | sort -rh | head -$limit"
        else
            find "$path" -maxdepth 2 -type d -exec du -sh {} \; 2>/dev/null | sort -rh | head -"$limit"
        fi
    fi
}

find_old_files() {
    local path="${1:-/var/log}"
    local days="${2:-30}"

    print_header "Files not modified in ${days} days (${path})"
    if [ "$DRY_RUN" = true ]; then
        echo "[dry-run] would run: find $path -type f -mtime +$days 2>/dev/null | head -20"
    else
        find "$path" -type f -mtime +"$days" 2>/dev/null | head -20 || echo "Cannot access $path"
    fi
}

check_inodes() {
    print_header "Inode Usage"
    if [ "$DRY_RUN" = true ]; then
        echo "[dry-run] would run: df -i | grep -vE '^tmpfs|^devtmpfs|^overlay|^none'"
    else
        df -i | grep -vE '^tmpfs|^devtmpfs|^overlay|^none'
    fi
}

main() {
    log "Starting disk analysis (DRY_RUN=$DRY_RUN)"

    list_disks
    find_large_dirs "/" 10
    find_large_dirs "/var" 10
    find_large_dirs "/home" 5
    find_old_files "/var/log" 30
    check_inodes

    print_header "Disk Analysis Complete"
}

main "$@"
