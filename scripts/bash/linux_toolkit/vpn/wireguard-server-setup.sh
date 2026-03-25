#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# WireGuard VPN Server Setup Automation Script
# Purpose: Automate WireGuard VPN server installation and configuration on Linux
# Requirements: Ubuntu 20.04+, Debian 11+, RHEL 8+, Rocky Linux 9+
# Safety: Dry-run mode supported via DRY_RUN=1
###############################################################################

DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"
SERVER_IP="${SERVER_IP:-}"
CLIENT_NAME="${CLIENT_NAME:-client1}"
SERVER_PORT="${SERVER_PORT:-51820}"
VPN_NETWORK="${VPN_NETWORK:-10.0.0.0/24}"

log() {
    local level="$1"
    shift
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
    echo "$msg"
}

info() { log "INFO" "$@"; }
warn() { log "WARN" "$@"; }
error() { log "ERROR" "$@"; }

dry_run() {
    if [ "$DRY_RUN" = "true" ]; then
        info "[dry-run] $*"
        return 0
    fi
    return 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "This script must be run as root"
        exit 1
    fi
}

detect_os() {
    if command_exists apt-get; then
        echo "debian"
    elif command_exists dnf; then
        echo "rhel"
    else
        error "Unsupported OS"
        exit 1
    fi
}

install_wireguard() {
    local os="$1"
    info "Installing WireGuard..."

    dry_run "Would install WireGuard" || {
        if [ "$os" = "debian" ]; then
            apt-get update
            apt-get install -y wireguard wireguard-tools iptables iputils-ping curl wget
        elif [ "$os" = "rhel" ]; then
            dnf install -y wireguard-tools iptables curl wget
            dnf install -y kmod-wireguard || true
        fi
    }
}

generate_keys() {
    local wg_dir="/etc/wireguard"
    
    info "Generating WireGuard keys..."

    dry_run "Would generate WireGuard keys" || {
        mkdir -p "$wg_dir"
        chmod 700 "$wg_dir"
        
        wg genkey | tee "$wg_dir/privatekey"
        cat "$wg_dir/privatekey" | wg pubkey | tee "$wg_dir/publickey"
        
        chmod 600 "$wg_dir/privatekey"
        chmod 644 "$wg_dir/publickey"
        
        info "Keys generated in $wg_dir"
    }
}

get_server_private_key() {
    local key
    key=$(cat /etc/wireguard/privatekey 2>/dev/null) || true
    if [ -z "$key" ]; then
        error "Server private key not found"
        return 1
    fi
    echo "$key"
}

get_server_public_key() {
    local key
    key=$(cat /etc/wireguard/publickey 2>/dev/null) || true
    if [ -z "$key" ]; then
        error "Server public key not found"
        return 1
    fi
    echo "$key"
}

create_server_config() {
    local wg_conf="/etc/wireguard/wg0.conf"
    local server_key
    server_key=$(get_server_private_key) || return 1
    
    info "Creating WireGuard server configuration..."

    dry_run "Would create server config" || {
        cat > "$wg_conf" <<EOF
[Interface]
PrivateKey = $server_key
Address = $VPN_NETWORK
ListenPort = $SERVER_PORT
SaveConfig = true

PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF
        chmod 600 "$wg_conf"
    }
}

configure_firewall() {
    info "Configuring firewall..."

    dry_run "Would configure firewall" || {
        # Enable IP forwarding
        echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-wireguard.conf
        sysctl -p
        
        if command_exists ufw; then
            ufw allow "$SERVER_PORT/udp" comment 'WireGuard'
        elif command_exists firewall-cmd; then
            firewall-cmd --permanent --add-port="${SERVER_PORT}/udp"
            firewall-cmd --permanent --add-masquerade
            firewall-cmd --reload
        fi
        
        iptables -A INPUT -p udp --dport "$SERVER_PORT" -j ACCEPT 2>/dev/null || true
    }
}

generate_client_config() {
    local output_dir="/etc/wireguard/clients"
    local client_key
    local server_key
    
    info "Generating client configuration for $CLIENT_NAME..."

    dry_run "Would generate client config" || {
        mkdir -p "$output_dir"
        
        # Generate client keys
        client_key=$(wg genkey)
        echo "$client_key" > "$output_dir/${CLIENT_NAME}.private"
        
        server_key=$(get_server_public_key) || return 1
        
        # Generate client config
        cat > "$output_dir/${CLIENT_NAME}.conf" <<EOF
[Interface]
PrivateKey = $client_key
Address = 10.0.0.2/24
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = $server_key
Endpoint = ${SERVER_IP}:${SERVER_PORT}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF
        
        chmod 600 "$output_dir/${CLIENT_NAME}.conf"
        
        # Add peer to server config
        local peer_pubkey
        peer_pubkey=$(echo "$client_key" | wg pubkey)
        
        if ! grep -q "$peer_pubkey" /etc/wireguard/wg0.conf 2>/dev/null; then
            echo "" >> /etc/wireguard/wg0.conf
            echo "[Peer]" >> /etc/wireguard/wg0.conf
            echo "PublicKey = $peer_pubkey" >> /etc/wireguard/wg0.conf
            echo "AllowedIPs = 10.0.0.2/32" >> /etc/wireguard/wg0.conf
            echo "PersistentKeepalive = 25" >> /etc/wireguard/wg0.conf
        fi
        
        info "Client config saved to $output_dir/${CLIENT_NAME}.conf"
    }
}

start_wireguard() {
    info "Starting WireGuard..."

    dry_run "Would start WireGuard" || {
        # Stop if running
        wg-quick down wg0 2>/dev/null || true
        
        # Start WireGuard
        wg-quick up wg0
        
        # Enable on boot
        systemctl enable wg-quick@wg0
        
        info "WireGuard started successfully"
    }
}

verify_installation() {
    info "Verifying WireGuard installation..."

    local errors=0

    # Check interface
    if ip link show wg0 >/dev/null 2>&1; then
        info "WireGuard interface wg0 exists"
    else
        warn "WireGuard interface wg0 not found"
        ((errors++))
    fi

    # Check WireGuard status
    if wg show >/dev/null 2>&1; then
        info "WireGuard is running"
        wg show
    else
        warn "WireGuard is not running"
        ((errors++))
    fi

    # Check listening port
    if ss -ulnp 2>/dev/null | grep -q ":$SERVER_PORT "; then
        info "WireGuard listening on port $SERVER_PORT"
    else
        warn "WireGuard not listening on port $SERVER_PORT"
        ((errors++))
    fi

    # Check IP forwarding
    if [ "$(cat /proc/sys/net/ipv4/ip_forward)" = "1" ]; then
        info "IP forwarding enabled"
    else
        warn "IP forwarding not enabled"
        ((errors++))
    fi

    if [ $errors -eq 0 ]; then
        info "Verification completed successfully"
    else
        warn "Verification completed with $errors error(s)"
    fi

    return $errors
}

show_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
    -h, --help              Show this help message
    -d, --dry-run           Run in dry-run mode (no changes made)
    -v, --verbose          Enable verbose output
    --server-ip IP          Server public IP address (required)
    --server-port PORT      WireGuard listen port (default: 51820)
    --client-name NAME      Client name for config generation (default: client1)
    --vpn-network CIDR      VPN network range (default: 10.0.0.0/24)

Examples:
    $0 --server-ip 203.0.113.10
    $0 --server-ip 203.0.113.10 --dry-run
    $0 --server-ip 203.0.113.10 --client-name office-laptop
EOF
}

main() {
    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                ;;
            -v|--verbose)
                VERBOSE=true
                ;;
            --server-ip)
                SERVER_IP="${2:-}"
                shift
                ;;
            --server-ip=*)
                SERVER_IP="${arg#*=}"
                ;;
            --server-port)
                SERVER_PORT="${2:-51820}"
                shift
                ;;
            --server-port=*)
                SERVER_PORT="${arg#*=}"
                ;;
            --client-name)
                CLIENT_NAME="${2:-client1}"
                shift
                ;;
            --client-name=*)
                CLIENT_NAME="${arg#*=}"
                ;;
            --vpn-network)
                VPN_NETWORK="${2:-10.0.0.0/24}"
                shift
                ;;
            --vpn-network=*)
                VPN_NETWORK="${arg#*=}"
                ;;
        esac
        shift 2>/dev/null || true
    done

    if [ -z "$SERVER_IP" ]; then
        error "Server IP is required. Use --server-ip option."
        show_help
        exit 1
    fi

    info "Starting WireGuard VPN setup..."
    info "Server IP: $SERVER_IP"
    info "Server Port: $SERVER_PORT"
    info "VPN Network: $VPN_NETWORK"
    info "Dry-run mode: $DRY_RUN"

    check_root
    local os=$(detect_os)

    install_wireguard "$os"
    generate_keys
    create_server_config
    configure_firewall
    generate_client_config
    start_wireguard
    verify_installation

    info "WireGuard VPN setup complete"
    info "Client config: /etc/wireguard/clients/${CLIENT_NAME}.conf"
    info "Server public key: $(get_server_public_key)"
}

main "$@"