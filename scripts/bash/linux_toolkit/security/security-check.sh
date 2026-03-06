#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $*" >&2; }

print_header() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

check_failed_logins() {
    print_header "Failed Login Attempts (last 24h)"
    if command -v lastb &>/dev/null; then
        lastb -20 2>/dev/null || echo "lastb not accessible"
    else
        grep "Failed password" /var/log/auth.log 2>/dev/null | tail -20 || echo "Cannot read auth.log"
    fi
}

check_successful_logins() {
    print_header "Recent Successful Logins"
    if command -v last &>/dev/null; then
        last -20
    else
        echo "last command not available"
    fi
}

check_listening_ports() {
    print_header "Listening Ports (Security Check)"
    ss -tulpn | grep LISTEN
}

check_sudoers() {
    print_header "Sudoers Configuration"
    if [[ -f /etc/sudoers ]]; then
        grep -v "^#" /etc/sudoers | grep -v "^$" | head -30
    fi
}

check_cron() {
    print_header "Cron Jobs"
    if command -v crontab &>/dev/null; then
        echo "User crontabs:"
        for user in $(cut -d: -f1 /etc/passwd); do
            crontab -u "$user" -l 2>/dev/null && echo "--- $user ---"
        done
    fi
    
    echo ""
    echo "System crontabs:"
    ls -la /etc/cron.*/ 2>/dev/null || true
}

check_selinux() {
    print_header "SELinux Status"
    if command -v getenforce &>/dev/null; then
        getenforce 2>/dev/null || echo "SELinux not available"
    else
        echo "SELinux not installed"
    fi
}

check_firewall() {
    print_header "Firewall Status"
    if command -v ufw &>/dev/null; then
        ufw status verbose 2>/dev/null || echo "ufw not configured"
    elif command -v firewall-cmd &>/dev/null; then
        firewall-cmd --state 2>/dev/null || echo "firewalld not running"
    else
        echo "No managed firewall detected"
    fi
}

check_open_files() {
    print_header "Users with Most Open Files"
    lsof 2>/dev/null | wc -l || echo "lsof not available"
    echo "Top users by open files:"
    lsof 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -rn | head -10 || true
}

main() {
    log "Starting security check"
    
    check_failed_logins
    check_successful_logins
    check_listening_ports
    check_cron
    check_selinux
    check_firewall
    check_open_files
    
    print_header "Security Check Complete"
}

main "$@"
