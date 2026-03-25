#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# BIND9 DNS Server Setup Automation Script
# Purpose: Automate BIND9 DNS server installation and configuration on Linux
# Requirements: Ubuntu 20.04+, Debian 11+, RHEL 8+, Rocky Linux 9+
# Safety: Dry-run mode supported via DRY_RUN=1
###############################################################################

DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"
INTERNAL_DOMAIN="${INTERNAL_DOMAIN:-internal.example.com}"
INTERNAL_NETWORK="${INTERNAL_NETWORK:-10.0.0.0/8}"
NS_IP="${NS_IP:-10.0.0.1}"
FORWARDERS="${FORWARDERS:-8.8.8.8,1.1.1.1,8.8.4.4}"

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

install_bind() {
    local os="$1"
    info "Installing BIND9..."

    dry_run "Would install BIND9" || {
        if [ "$os" = "debian" ]; then
            apt-get update
            apt-get install -y bind9 bind9utils bind9-doc dnsutils
        elif [ "$os" = "rhel" ]; then
            dnf install -y bind bind-utils
        fi
    }
}

configure_named_options() {
    local config_file="/etc/bind/named.conf.options"
    info "Configuring BIND9 options..."

    dry_run "Would configure named.conf.options" || {
        cat > "$config_file" <<EOF
options {
    directory "/var/cache/bind";
    
    forwarders {
$(echo "$FORWARDERS" | tr ',' '\n' | while read fp; do echo "        $fp;"; done)
    };
    
    allow-query {
        localhost;
        $INTERNAL_NETWORK;
    };
    
    recursion yes;
    listen-on { 127.0.0.1; $NS_IP; };
    
    // DNSSEC validation
    dnssec-validation auto;
    
    // Logging
    channel default_log {
        file "/var/log/named/named.log" versions 3 size 5m;
        severity info;
        print-time yes;
        print-category yes;
    };
    category default { default_log; };
};
EOF
        chmod 644 "$config_file"
    }
}

create_zone_config() {
    local config_file="/etc/bind/named.conf.local"
    info "Creating zone configuration..."

    dry_run "Would create named.conf.local" || {
        mkdir -p /etc/bind/zones
        
        cat > "$config_file" <<EOF
zone "$INTERNAL_DOMAIN" {
    type master;
    file "/etc/bind/zones/db.$INTERNAL_DOMAIN";
    allow-transfer { $INTERNAL_NETWORK; };
};

zone "$(echo $INTERNAL_NETWORK | cut -d'/' -f1 | tr '.' '.')" {
    type master;
    file "/etc/bind/zones/db.$INTERNAL_NETWORK";
    allow-transfer { $INTERNAL_NETWORK; };
};
EOF
        chmod 640 "$config_file"
    }
}

create_forward_zone() {
    local zone_file="/etc/bind/zones/db.$INTERNAL_DOMAIN"
    info "Creating forward zone file..."

    dry_run "Would create forward zone" || {
        local serial=$(date +%Y%m%d01)
        cat > "$zone_file" <<EOF
\$TTL    604800
@       IN      SOA     ns.$INTERNAL_DOMAIN. admin.$INTERNAL_DOMAIN. (
                        $serial  ; Serial
                        604800      ; Refresh
                        86400       ; Retry
                        2419200     ; Expire
                        604800 )    ; Negative Cache TTL

; Name servers
@       IN      NS      ns.$INTERNAL_DOMAIN.
@       IN      A       $NS_IP

; Name server host
ns      IN      A       $NS_IP

; Additional hosts
gateway IN      A       $NS_IP
dhcp    IN      A       10.0.0.10
web01   IN      A       10.0.0.101
db01    IN      A       10.0.0.201
EOF
        chown bind:bind "$zone_file"
        chmod 640 "$zone_file"
    }
}

create_reverse_zone() {
    local zone_file="/etc/bind/zones/db.$INTERNAL_NETWORK"
    info "Creating reverse zone file..."

    dry_run "Would create reverse zone" || {
        local serial=$(date +%Y%m%d01)
        local reverse_net=$(echo $INTERNAL_NETWORK | cut -d'/' -f1 | tr '.' '.')
        
        cat > "$zone_file" <<EOF
\$TTL    604800
@       IN      SOA     ns.$INTERNAL_DOMAIN. admin.$INTERNAL_DOMAIN. (
                        $serial  ; Serial
                        604800      ; Refresh
                        86400       ; Retry
                        2419200     ; Expire
                        604800 )    ; Negative Cache TTL

; Name servers
@       IN      NS      ns.$INTERNAL_DOMAIN.
1       IN      PTR     ns.$INTERNAL_DOMAIN.
10      IN      PTR     dhcp.$INTERNAL_DOMAIN.
101     IN      PTR     web01.$INTERNAL_DOMAIN.
201     IN      PTR     db01.$INTERNAL_DOMAIN.
EOF
        chown bind:bind "$zone_file"
        chmod 640 "$zone_file"
    }
}

configure_firewall() {
    info "Configuring firewall..."

    dry_run "Would configure firewall" || {
        if command_exists ufw; then
            ufw allow 53/tcp comment 'DNS'
            ufw allow 53/udp comment 'DNS'
        elif command_exists firewall-cmd; then
            firewall-cmd --permanent --add-port=53/tcp
            firewall-cmd --permanent --add-port=53/udp
            firewall-cmd --reload
        fi
    }
}

start_bind() {
    info "Starting BIND9..."

    dry_run "Would start BIND9" || {
        # Create log directory
        mkdir -p /var/log/named
        chown bind:bind /var/log/named
        
        if command_exists systemctl; then
            systemctl enable bind9 2>/dev/null || systemctl enable named
            systemctl restart bind9 2>/dev/null || systemctl restart named
        fi
        
        info "BIND9 started successfully"
    }
}

verify_installation() {
    info "Verifying BIND9 installation..."

    local errors=0

    # Check service status
    if command_exists systemctl; then
        if systemctl is-active bind9 >/dev/null 2>&1 || systemctl is-active named >/dev/null 2>&1; then
            info "BIND9 is running"
        else
            warn "BIND9 is not running"
            ((errors++))
        fi
    fi

    # Check listening ports
    if ss -tulnp 2>/dev/null | grep -q ":53 "; then
        info "BIND9 is listening on port 53"
    else
        warn "BIND9 is not listening on port 53"
        ((errors++))
    fi

    # Test DNS query
    if command_exists dig; then
        if dig @localhost google.com +short >/dev/null 2>&1; then
            info "DNS queries are working"
        else
            warn "DNS queries are not working"
            ((errors++))
        fi
    fi

    # Test internal domain
    if command_exists dig; then
        if dig @localhost ns.$INTERNAL_DOMAIN +short >/dev/null 2>&1; then
            info "Internal domain resolution is working"
        else
            warn "Internal domain resolution may not be configured yet"
        fi
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
    --domain DOMAIN        Internal domain name (default: internal.example.com)
    --network NETWORK     Internal network CIDR (default: 10.0.0.0/8)
    --ns-ip IP            Name server IP address (default: 10.0.0.1)
    --forwarders IPs      Comma-separated list of forwarder IPs (default: 8.8.8.8,1.1.1.1,8.8.4.4)

Examples:
    $0 --domain mycompany.internal --network 192.168.1.0/24 --ns-ip 192.168.1.1
    $0 --dry-run
EOF
}

main() {
    for arg in "$@"; do
        case $arg in
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
            --domain)
                INTERNAL_DOMAIN="${2:-}"
                shift
                ;;
            --domain=*)
                INTERNAL_DOMAIN="${arg#*=}"
                ;;
            --network)
                INTERNAL_NETWORK="${2:-}"
                shift
                ;;
            --network=*)
                INTERNAL_NETWORK="${arg#*=}"
                ;;
            --ns-ip)
                NS_IP="${2:-}"
                shift
                ;;
            --ns-ip=*)
                NS_IP="${arg#*=}"
                ;;
            --forwarders)
                FORWARDERS="${2:-}"
                shift
                ;;
            --forwarders=*)
                FORWARDERS="${arg#*=}"
                ;;
        esac
        shift 2>/dev/null || true
    done

    info "Starting BIND9 DNS server setup..."
    info "Domain: $INTERNAL_DOMAIN"
    info "Network: $INTERNAL_NETWORK"
    info "NS IP: $NS_IP"
    info "Forwarders: $FORWARDERS"
    info "Dry-run mode: $DRY_RUN"

    check_root
    local os=$(detect_os)

    install_bind "$os"
    configure_named_options
    create_zone_config
    create_forward_zone
    create_reverse_zone
    configure_firewall
    start_bind
    verify_installation

    info "BIND9 DNS server setup complete"
    info "Internal domain: $INTERNAL_DOMAIN"
    info "Client config: add 'nameserver $NS_IP' to /etc/resolv.conf"
}

main "$@"