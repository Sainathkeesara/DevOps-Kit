#!/usr/bin/env bash
#===============================================================================
# SPDX-FileCopyrightText: Copyright (c) 2026
# SPDX-License-Identifier: MIT
#
# linux-network-monitor.sh
#
# Purpose: Network traffic monitoring script using nethogs and iftop
#          Provides process-based and interface-based network monitoring
#
# Usage: ./linux-network-monitor.sh [--help] [--interface INTERFACE] 
#                                [--interval SECONDS] [--output FILE]
#                                [--verbose]
#
# Tested on: Ubuntu 20.04+, RHEL 8+, Debian 11+
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Configuration
#-------------------------------------------------------------------------------
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_VERSION="1.0.0"
LOG_FILE="/var/log/network-monitor.log"

# Default values
INTERFACE="${MONITOR_INTERFACE:-eth0}"
REFRESH_RATE="${MONITOR_REFRESH:-1}"
VERBOSE="${MONITOR_VERBOSE:-false}"
OUTPUT_FILE=""
DRY_RUN="${DRY_RUN:-false}"

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

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if interface exists
interface_exists() {
    ip link show "$1" >/dev/null 2>&1
}

# Get network interfaces
get_interfaces() {
    ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$'
}

# Monitor with nethogs
monitor_nethogs() {
    local interface="$1"
    local duration="${2:-10}"
    
    log_info "Starting NetHogs monitoring on $interface for ${duration}s..."
    
    if ! command_exists nethogs; then
        log_error "nethogs not found. Install with: sudo apt-get install nethogs"
        return 1
    fi
    
    if ! interface_exists "$interface"; then
        log_error "Interface $interface does not exist"
        return 1
    fi
    
    # Run nethogs in monitoring mode
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would run: sudo nethogs -t $interface"
    else
        timeout "$duration" sudo nethogs -d "$REFRESH_RATE" "$interface" 2>/dev/null || true
    fi
}

# Monitor with iftop
monitor_iftop() {
    local interface="$1"
    local duration="${2:-10}"
    
    log_info "Starting iftop monitoring on $interface for ${duration}s..."
    
    if ! command_exists iftop; then
        log_error "iftop not found. Install with: sudo apt-get install iftop"
        return 1
    fi
    
    if ! interface_exists "$interface"; then
        log_error "Interface $interface does not exist"
        return 1
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would run: sudo iftop -i $interface"
    else
        timeout "$duration" sudo iftop -i "$interface" 2>/dev/null || true
    fi
}

# Show network statistics
show_network_stats() {
    local interface="$1"
    
    log_info "=== Network Statistics for $interface ==="
    
    # Get IP address
    local ip_addr
    ip_addr=$(ip -4 addr show "$interface" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
    log_info "IP Address: ${ip_addr:-N/A}"
    
    # Get RX/TX bytes
    local rx_bytes tx_bytes
    rx_bytes=$(cat "/sys/class/net/$interface/statistics/rx_bytes" 2>/dev/null || echo "0")
    tx_bytes=$(cat "/sys/class/net/$interface/statistics/tx_bytes" 2>/dev/null || echo "0")
    log_info "RX: $(numfmt --grouping "$rx_bytes") bytes"
    log_info "TX: $(numfmt --grouping "$tx_bytes") bytes"
    
    # Get error counts
    local rx_errs tx_errs
    rx_errs=$(cat "/sys/class/net/$interface/statistics/rx_errors" 2>/dev/null || echo "0")
    tx_errs=$(cat "/sys/class/net/$interface/statistics/tx_errors" 2>/dev/null || echo "0")
    log_info "RX Errors: $rx_errs"
    log_info "TX Errors: $tx_errs"
    
    # Get packet counts
    local rx_pkt tx_pkt
    rx_pkt=$(cat "/sys/class/net/$interface/statistics/rx_packets" 2>/dev/null || echo "0")
    tx_pkt=$(cat "/sys/class/net/$interface/statistics/tx_packets" 2>/dev/null || echo "0")
    log_info "RX Packets: $(numfmt --grouping "$rx_pkt")"
    log_info "TX Packets: $(numfmt --grouping "$tx_pkt")"
}

# Show active connections
show_connections() {
    log_info "=== Active Network Connections ==="
    
    # TCP connections
    local tcp_count
    tcp_count=$(ss -tan | wc -l)
    log_info "TCP connections: $((tcp_count - 1))"
    
    # UDP connections
    local udp_count
    udp_count=$(ss -uan | wc -l)
    log_info "UDP connections: $((udp_count - 1))"
    
    # Top 10 connections by state
    log_info "Top connection states:"
    ss -tan | awk '{print $1}' | sort | uniq -c | sort -rn | head -5
}

# Show listening ports
show_listening_ports() {
    log_info "=== Listening Ports ==="
    ss -tuln | grep LISTEN | awk '{print $1, $5}' | column -t
}

# Quick bandwidth check
quick_bandwidth() {
    local interface="$1"
    
    log_info "=== Quick Bandwidth Check ==="
    
    # Get current bandwidth
    local rx1 tx1 rx2 tx2
    
    rx1=$(cat "/sys/class/net/$interface/statistics/rx_bytes" 2>/dev/null || echo "0")
    tx1=$(cat "/sys/class/net/$interface/statistics/tx_bytes" 2>/dev/null || echo "0")
    
    sleep 1
    
    rx2=$(cat "/sys/class/net/$interface/statistics/rx_bytes" 2>/dev/null || echo "0")
    tx2=$(cat "/sys/class/net/$interface/statistics/tx_bytes" 2>/dev/null || echo "0")
    
    local rx_rate tx_rate
    rx_rate=$((rx2 - rx1))
    tx_rate=$((tx2 - tx1))
    
    log_info "RX Rate: $(numfmt --grouping "$rx_rate") bytes/s ($(numfmt --to=iec --grouping "$rx_rate")B/s)"
    log_info "TX Rate: $(numfmt --grouping "$tx_rate") bytes/s ($(numfmt --to=iec --grouping "$tx_rate")B/s)"
}

# Usage information
usage() {
    cat << EOF
$SCRIPT_NAME v$SCRIPT_VERSION

Network traffic monitoring script using nethogs and iftop.

Usage: $SCRIPT_NAME [OPTIONS]

Options:
    -i, --interface IFACE   Network interface to monitor (default: eth0)
    -t, --interval SECONDS  Refresh interval in tenths of seconds (default: 1)
    -o, --output FILE       Output results to file
    -v, --verbose          Enable verbose output
    -d, --dry-run          Show what would be done without doing it
    -h, --help             Show this help message

Examples:
    $SCRIPT_NAME -i eth0
    $SCRIPT_NAME --interface wlan0 --verbose
    $SCRIPT_NAME --dry-run --interface eth0

EOF
}

#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--interface)
                INTERFACE="$2"
                shift 2
                ;;
            -t|--interval)
                REFRESH_RATE="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE="true"
                shift
                ;;
            -d|--dry-run)
                DRY_RUN="true"
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
    
    log_info "==========================================="
    log_info "Linux Network Monitor v$SCRIPT_VERSION"
    log_info "==========================================="
    log_info "Interface: $INTERFACE"
    log_info "Refresh Rate: ${REFRESH_RATE}s"
    log_info "Verbose: $VERBOSE"
    log_info "Dry Run: $DRY_RUN"
    
    # Check dependencies
    log_info "Checking dependencies..."
    
    local missing_deps=()
    for cmd in nethogs iftop; do
        if ! command_exists "$cmd"; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_warn "Missing dependencies: ${missing_deps[*]}"
        log_info "Install with: sudo apt-get install ${missing_deps[*]}"
    fi
    
    # Check interface
    if ! interface_exists "$INTERFACE"; then
        log_error "Interface $INTERFACE does not exist"
        log_info "Available interfaces: $(get_interfaces | tr '\n' ', ')"
        exit 1
    fi
    
    # Run monitoring
    log_info "Starting monitoring..."
    
    show_network_stats "$INTERFACE"
    show_connections
    show_listening_ports
    quick_bandwidth "$INTERFACE"
    
    log_info "Monitoring complete."
}

# Run main function
main "$@"