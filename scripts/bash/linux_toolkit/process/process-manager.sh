#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN="${DRY_RUN:-false}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $*" >&2; }
die() { log "FATAL: $*"; exit 1; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        die "This script must be run as root (use sudo)"
    fi
}

list_top_processes() {
    echo "========================================"
    echo "Top 15 CPU Processes"
    echo "========================================"
    ps aux --sort=-%cpu | head -16
    
    echo ""
    echo "========================================"
    echo "Top 15 Memory Processes"
    echo "========================================"
    ps aux --sort=-%mem | head -16
}

find_process() {
    local pattern="${1:-}"
    if [[ -z "$pattern" ]]; then
        die "Pattern required"
    fi
    
    echo "========================================"
    echo "Processes matching: $pattern"
    echo "========================================"
    ps aux | grep -E "$pattern" | grep -v grep
}

kill_process() {
    local pid="$1"
    local signal="${2:-TERM}"
    
    if [[ -z "$pid" ]]; then
        die "PID required"
    fi
    
    if [[ ! -d "/proc/$pid" ]]; then
        die "Process $pid does not exist"
    fi
    
    log "Sending $signal to PID $pid"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would send $signal to $pid"
        return 0
    fi
    
    kill "-${signal}" "$pid"
    sleep 1
    
    if kill -0 "$pid" 2>/dev/null; then
        warn "Process still running, sending KILL"
        kill -9 "$pid" 2>/dev/null || true
    fi
    
    log "Signal sent to $pid"
}

kill_by_pattern() {
    local pattern="${1:-}"
    if [[ -z "$pattern" ]]; then
        die "Pattern required"
    fi
    
    check_root
    
    local pids=$(pgrep -f "$pattern" 2>/dev/null || true)
    if [[ -z "$pids" ]]; then
        warn "No processes found matching: $pattern"
        return 0
    fi
    
    log "Found PIDs: $pids"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would kill processes: $pids"
        return 0
    fi
    
    for pid in $pids; do
        log "Killing PID $pid"
        kill -TERM "$pid" 2>/dev/null || true
        sleep 1
        kill -9 "$pid" 2>/dev/null || true
    done
    
    log "Processes killed"
}

process_tree() {
    local pid="${1:-$$}"
    
    echo "========================================"
    echo "Process Tree for PID: $pid"
    echo "========================================"
    pstree -ap "$pid" 2>/dev/null || ps --forest -o pid,ppid,%cpu,%mem,cmd | head -30
}

main() {
    local action="${1:-top}"
    local arg1="${2:-}"
    local arg2="${3:-}"
    
    case "$action" in
        top)
            list_top_processes
            ;;
        find)
            find_process "$arg1"
            ;;
        kill)
            check_root
            kill_process "$arg1" "$arg2"
            ;;
        kill-pattern)
            check_root
            kill_by_pattern "$arg1"
            ;;
        tree)
            process_tree "$arg1"
            ;;
        *)
            echo "Usage: $0 <action> [args]"
            echo "Actions:"
            echo "  top                    - List top processes by CPU/memory"
            echo "  find <pattern>         - Find processes by name/pattern"
            echo "  kill <pid> [signal]   - Kill process by PID (default: TERM)"
            echo "  kill-pattern <pattern> - Kill all processes matching pattern"
            echo "  tree [pid]             - Show process tree"
            echo ""
            echo "Environment variables:"
            echo "  DRY_RUN=true          - Simulate actions without making changes"
            exit 1
            ;;
    esac
}

main "$@"
