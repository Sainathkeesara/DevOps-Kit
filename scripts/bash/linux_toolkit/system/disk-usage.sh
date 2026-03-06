#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN="${DRY_RUN:-false}"
THRESHOLD="${THRESHOLD:-80}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $*" >&2; }
die() { log "FATAL: $*"; exit 1; }

print_header() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

list_disks() {
    print_header "Disk Usage Overview"
    df -h | grep -vE '^tmpfs|^devtmpfs|^overlay|^none'
}

find_large_dirs() {
    local path="${1:-/}"
    local limit="${2:-5}"
    
    print_header "Top ${limit} Largest Directories in ${path}"
    if command -v du &>/dev/null; then
        du -ah "$path" 2>/dev/null | sort -rh | head -"$limit"
    else
        find "$path" -maxdepth 2 -type d -exec du -sh {} \; 2>/dev/null | sort -rh | head -"$limit"
    fi
}

find_old_files() {
    local path="${1:-/var/log}"
    local days="${2:-30}"
    
    print_header "Files not modified in ${days} days (${path})"
    find "$path" -type f -mtime +"$days" 2>/dev/null | head -20 || echo "Cannot access $path"
}

check_inodes() {
    print_header "Inode Usage"
    df -i | grep -vE '^tmpfs|^devtmpfs|^overlay|^none'
}

main() {
    log "Starting disk analysis"
    
    list_disks
    find_large_dirs "/" 10
    find_large_dirs "/var" 10
    find_large_dirs "/home" 5
    find_old_files "/var/log" 30
    check_inodes
    
    print_header "Disk Analysis Complete"
}

main "$@"
