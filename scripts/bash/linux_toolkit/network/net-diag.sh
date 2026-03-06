#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

print_header() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

check_interfaces() {
    print_header "Network Interfaces"
    ip -br addr show
}

check_routes() {
    print_header "Routing Table"
    ip route show
}

check_connections() {
    local limit="${1:-50}"
    print_header "Active Connections (Top ${limit} by state)"
    ss -tan | head -"$limit"
}

check_listening_ports() {
    print_header "Listening Ports"
    ss -tulpn | grep LISTEN
}

check_dns() {
    print_header "DNS Resolution Test"
    if [[ -f /etc/resolv.conf ]]; then
        echo "Nameservers:"
        cat /etc/resolv.conf | grep nameserver
    fi
    
    for host in google.com cloudflare.com; do
        echo "Testing: $host"
        timeout 3 nslookup "$host" 2>/dev/null || timeout 3 dig +short "$host" 2>/dev/null || timeout 3 getent hosts "$host" || echo "Failed to resolve $host"
    done
}

check_bandwidth() {
    print_header "Network Statistics"
    if command -v vnstat &>/dev/null; then
        vnstat -h 2>/dev/null || echo "vnstat data not available"
    else
        cat /proc/net/dev
    fi
}

ping_host() {
    local host="$1"
    local count="${2:-4}"
    print_header "Ping Test: $host"
    ping -c "$count" "$host"
}

port_scan() {
    local host="$1"
    local port="${2:-80}"
    print_header "Port Check: $host:$port"
    timeout 3 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null && echo "Port $port is open on $host" || echo "Port $port is closed or filtered on $host"
}

main() {
    local action="${1:-all}"
    
    if [[ "$action" == "interfaces" ]]; then
        check_interfaces
    elif [[ "$action" == "routes" ]]; then
        check_routes
    elif [[ "$action" == "connections" ]]; then
        check_connections 50
    elif [[ "$action" == "ports" ]]; then
        check_listening_ports
    elif [[ "$action" == "dns" ]]; then
        check_dns
    elif [[ "$action" == "ping" ]]; then
        local host="${2:-google.com}"
        ping_host "$host"
    elif [[ "$action" == "port" ]]; then
        local host="${2:-localhost}"
        local port="${3:-80}"
        port_scan "$host" "$port"
    else
        check_interfaces
        check_routes
        check_connections 20
        check_listening_ports
        check_dns
    fi
}

main "$@"
