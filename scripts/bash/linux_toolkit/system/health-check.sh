#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTNAME="${HOSTNAME:-$(hostname)}"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $*" >&2; }
die() { log "FATAL: $*"; exit 1; }

CPU_THRESHOLD="${CPU_THRESHOLD:-80}"
MEM_THRESHOLD="${MEM_THRESHOLD:-80}"
DISK_THRESHOLD="${DISK_THRESHOLD:-85}"
DRY_RUN="${DRY_RUN:-false}"

print_header() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

check_disk() {
    print_header "Disk Usage"
    df -h | grep -vE '^tmpfs|^devtmpfs|^overlay|^none' | awk 'NR==1 || $5+0 > '"${DISK_THRESHOLD}"' {print}'
}

check_memory() {
    print_header "Memory Usage"
    free -h
    local used_pct=$(free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')
    echo "Usage: ${used_pct}%"
    if [[ "$used_pct" -gt "$MEM_THRESHOLD" ]]; then
        warn "Memory usage above threshold: ${used_pct}%"
    fi
}

check_cpu() {
    print_header "CPU Load"
    uptime
    local load_1m=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | xargs)
    echo "1min load: $load_1m"
}

check_top_cpu_mem() {
    print_header "Top 10 CPU-Hungry Processes"
    ps aux --sort=-%cpu | head -11

    print_header "Top 10 Memory-Hungry Processes"
    ps aux --sort=-%mem | head -11
}

check_services() {
    print_header "Failed Systemd Services"
    systemctl --failed --no-pager 2>/dev/null || echo "systemctl not available or not running as root"
}

check_uptime() {
    print_header "System Uptime"
    uptime -p 2>/dev/null || uptime
}

check_io_stats() {
    print_header "I/O Statistics"
    if command -v iostat &>/dev/null; then
        iostat -x 1 1 2>/dev/null | tail -20 || echo "iostat requires sysstat package"
    else
        cat /proc/diskstats 2>/dev/null | head -10 || echo "Cannot read diskstats"
    fi
}

main() {
    log "Starting system health check on $HOSTNAME"
    
    print_header "System Health Report - $HOSTNAME - $TIMESTAMP"
    
    check_uptime
    check_cpu
    check_memory
    check_disk
    check_top_cpu_mem
    check_services
    check_io_stats
    
    print_header "Health Check Complete"
    log "Finished system health check"
}

main "$@"
