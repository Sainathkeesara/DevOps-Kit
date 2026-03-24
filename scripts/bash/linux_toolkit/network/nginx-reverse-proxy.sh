#!/usr/bin/env bash
# =============================================================================
# Nginx Reverse Proxy Setup with SSL/TLS Termination
# =============================================================================
# Purpose: Install and configure Nginx as a reverse proxy with SSL/TLS termination
#          for backend application servers
# Usage: ./nginx-reverse-proxy.sh [--dry-run] [--install] [--ssl-only] [--domain DOMAIN]
# Requirements: root privileges, systemd, OpenSSL
# Safety Notes:
#   - Always run with --dry-run first to preview all changes
#   - This script modifies firewall rules and creates systemd services
#   - SSL certificates require domain validation for production use
#   - Backup existing nginx configuration before running
# Tested OS: Ubuntu 20.04/22.04, Debian 11/12, RHEL 8/9, AlmaLinux 9
# =============================================================================

set -euo pipefail

DRY_RUN="${DRY_RUN:-true}"
INSTALL_NGINX="${INSTALL_NGINX:-false}"
SSL_ONLY="${SSL_ONLY:-false}"
DOMAIN="${DOMAIN:-example.com}"
EMAIL="${EMAIL:-admin@example.com}"
BACKEND_PORT="${BACKEND_PORT:-8080}"
NGINX_PORT_HTTP="${NGINX_PORT_HTTP:-80}"
NGINX_PORT_HTTPS="${NGINX_PORT_HTTPS:-443}"
LETSENCRYPT="${LETSENCRYPT:-true}"
CERT_PATH="/etc/letsencrypt/live/${DOMAIN}"
NGINX_CONF="/etc/nginx"
NGINX_SITES="/etc/nginx/sites-available"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Install and configure Nginx reverse proxy with SSL/TLS termination

OPTIONS:
    --dry-run          Preview all changes without executing (default: true)
    --install         Actually install and configure (requires --dry-run=false)
    --ssl-only        Configure SSL only, skip HTTP setup
    --domain DOMAIN   Domain name for SSL certificate (default: example.com)
    --email EMAIL     Email for Let's Encrypt notifications (default: admin@example.com)
    --backend PORT    Backend service port to proxy to (default: 8080)
    -h, --help        Show this help message

Examples:
    $0 --dry-run
    $0 --dry-run --domain myapp.com --backend 3000
    DRY_RUN=false $0 --install --domain myapp.com --backend 8080

EOF
    exit 0
}

log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
}

check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        log "ERROR" "This script must be run as root"
        exit 1
    fi
}

check_dependencies() {
    log "INFO" "Checking dependencies..."
    
    local required_cmds=("nginx" "openssl" "systemctl")
    local missing_cmds=()
    
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_cmds+=("$cmd")
        fi
    done
    
    if [[ ${#missing_cmds[@]} -gt 0 ]]; then
        log "WARN" "Missing commands: ${missing_cmds[*]}"
        if [[ "$INSTALL_NGINX" == "true" ]]; then
            log "INFO" "Installing missing dependencies..."
            install_nginx
        else
            log "ERROR" "Run with --install to install missing dependencies"
            exit 1
        fi
    fi
    
    log "INFO" "Dependency check complete"
}

install_nginx() {
    log "INFO" "Installing Nginx..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would install Nginx"
        return 0
    fi
    
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -qq
        apt-get install -y nginx openssl certbot python3-certbot-nginx
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y nginx openssl certbot python3-certbot-nginx
    elif command -v yum >/dev/null 2>&1; then
        yum install -y nginx openssl certbot python3-certbot-nginx
    else
        log "ERROR" "Unsupported package manager"
        exit 1
    fi
    
    log "INFO" "Nginx installed successfully"
}

generate_self_signed_cert() {
    local cert_dir="$1"
    local domain="$2"
    
    log "INFO" "Generating self-signed SSL certificate for $domain..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would generate self-signed certificate"
        return 0
    fi
    
    mkdir -p "$cert_dir"
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$cert_dir/privkey.pem" \
        -out "$cert_dir/fullchain.pem" \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$domain" \
        2>/dev/null
    
    chmod 600 "$cert_dir/privkey.pem"
    chmod 644 "$cert_dir/fullchain.pem"
    
    log "INFO" "Self-signed certificate generated at $cert_dir"
}

configure_firewall() {
    log "INFO" "Configuring firewall rules..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would configure firewall"
        return 0
    fi
    
    if command -v ufw >/dev/null 2>&1; then
        ufw --force enable 2>/dev/null || true
        ufw allow 22/tcp comment "SSH" 2>/dev/null || true
        ufw allow "$NGINX_PORT_HTTP/tcp" comment "HTTP" 2>/dev/null || true
        ufw allow "$NGINX_PORT_HTTPS/tcp" comment "HTTPS" 2>/dev/null || true
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-service=ssh 2>/dev/null || true
        firewall-cmd --permanent --add-port="${NGINX_PORT_HTTP}/tcp" 2>/dev/null || true
        firewall-cmd --permanent --add-port="${NGINX_PORT_HTTPS}/tcp" 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
    fi
    
    log "INFO" "Firewall configured"
}

create_proxy_config() {
    local domain="$1"
    local backend="$2"
    
    log "INFO" "Creating Nginx reverse proxy configuration for $domain..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would create proxy configuration"
        return 0
    fi
    
    mkdir -p "$NGINX_SITES" "$NGINX_SITES_ENABLED"
    
    local config_file="${NGINX_SITES}/${domain}.conf"
    
    cat > "$config_file" <<PROXY_CONFIG
# Nginx reverse proxy configuration for $domain
# Generated on $(date)

upstream backend_${domain} {
    server 127.0.0.1:${backend};
    keepalive 32;
}

# Redirect HTTP to HTTPS
server {
    listen ${NGINX_PORT_HTTP};
    server_name ${domain} www.${domain};

    location / {
        return 301 https://\$host\$request_uri;
    }

    # Let's Encrypt challenges
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
}

# HTTPS server block
server {
    listen ${NGINX_PORT_HTTPS} ssl http2;
    server_name ${domain} www.${domain};

    # SSL configuration
    ssl_certificate ${CERT_PATH}/fullchain.pem;
    ssl_certificate_key ${CERT_PATH}/privkey.pem;
    
    # SSL security settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;

    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data:;" always;

    # Main location - proxy to backend
    location / {
        proxy_pass http://backend_${domain};
        proxy_http_version 1.1;
        
        # Headers
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        
        # Connection upgrades for WebSocket
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffering
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 16k;
        proxy_busy_buffers_size 24k;
    }

    # Health check endpoint
    location /nginx-health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
PROXY_CONFIG

    # Enable the site
    if [[ ! -L "${NGINX_SITES_ENABLED}/${domain}.conf" ]]; then
        ln -sf "${NGINX_SITES}/${domain}.conf" "${NGINX_SITES_ENABLED}/${domain}.conf"
    fi
    
    # Disable default site if exists
    if [[ -L "${NGINX_SITES_ENABLED}/default" ]]; then
        rm -f "${NGINX_SITES_ENABLED}/default"
    fi
    
    # Test nginx configuration
    if nginx -t 2>&1 | grep -q "syntax is ok"; then
        log "INFO" "Nginx configuration is valid"
    else
        log "ERROR" "Nginx configuration test failed"
        return 1
    fi
    
    log "INFO" "Proxy configuration created at $config_file"
}

obtain_letsencrypt_cert() {
    local domain="$1"
    local email="$2"
    
    log "INFO" "Obtaining Let's Encrypt certificate for $domain..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would obtain Let's Encrypt certificate"
        return 0
    fi
    
    if command -v certbot >/dev/null 2>&1; then
        certbot --nginx -d "$domain" -d "www.$domain" \
            --email "$email" --agree-tos --non-interactive \
            --redirect --hsts --stale-tests-days 30 \
            || log "WARN" "Let's Encrypt certificate generation may have failed"
    else
        log "WARN" "Certbot not available, using self-signed certificate"
        generate_self_signed_cert "$CERT_PATH" "$domain"
    fi
}

start_nginx() {
    log "INFO" "Starting Nginx..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would start Nginx"
        return 0
    fi
    
    systemctl enable nginx
    systemctl restart nginx
    systemctl status nginx --no-pager || true
    
    log "INFO" "Nginx started successfully"
}

print_summary() {
    log "INFO" "=============================================="
    log "INFO" "  Nginx Reverse Proxy Setup Complete"
    log "INFO" "=============================================="
    log "INFO" "Domain           : $DOMAIN"
    log "INFO" "Backend Port     : $BACKEND_PORT"
    log "INFO" "HTTP Port        : $NGINX_PORT_HTTP"
    log "INFO" "HTTPS Port       : $NGINX_PORT_HTTPS"
    log "INFO" "SSL Provider     : $LETSENCRYPT"
    log "INFO" ""
    log "INFO" "Configuration    : ${NGINX_SITES}/${DOMAIN}.conf"
    log "INFO" "SSL Certificate  : $CERT_PATH"
    log "INFO" ""
    log "INFO" "Commands:"
    log "INFO" "  nginx -t            # Test configuration"
    log "INFO" "  systemctl status nginx # Check status"
    log "INFO" "  journalctl -u nginx -f # View logs"
    log "INFO" "  certbot renew --dry-run # Test renewal"
    log "INFO" "=============================================="
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --install)
                INSTALL_NGINX="true"
                shift
                ;;
            --ssl-only)
                SSL_ONLY="true"
                shift
                ;;
            --domain)
                DOMAIN="$2"
                CERT_PATH="/etc/letsencrypt/live/${DOMAIN}"
                shift 2
                ;;
            --email)
                EMAIL="$2"
                shift 2
                ;;
            --backend)
                BACKEND_PORT="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
    done
    
    log "INFO" "Nginx Reverse Proxy Setup Starting..."
    log "INFO" "Dry-run mode: $DRY_RUN"
    log "INFO" "Domain: $DOMAIN"
    log "INFO" "Backend: $BACKEND_PORT"
    
    check_root
    check_dependencies
    
    if [[ "$SSL_ONLY" != "true" ]]; then
        configure_firewall
    fi
    
    generate_self_signed_cert "$CERT_PATH" "$DOMAIN"
    create_proxy_config "$DOMAIN" "$BACKEND_PORT"
    
    if [[ "$LETSENCRYPT" == "true" ]]; then
        obtain_letsencrypt_cert "$DOMAIN" "$EMAIL"
    fi
    
    start_nginx
    print_summary
    
    log "INFO" "Setup complete"
}

main "$@"
