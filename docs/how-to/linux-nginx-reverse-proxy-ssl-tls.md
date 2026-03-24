# Nginx Reverse Proxy with SSL/TLS Termination

## Purpose

This guide explains how to set up Nginx as a reverse proxy with SSL/TLS termination for backend application servers. The configuration provides secure HTTPS access to applications running on internal ports, with modern security headers and performance optimizations.

## When to Use

Use this reverse proxy setup when you need to:

- Expose HTTP backend services via HTTPS
- Terminate SSL/TLS at Nginx for centralized certificate management
- Load balance across multiple backend servers
- Add security headers to protect against common web vulnerabilities
- Enable WebSocket proxying for real-time applications
- Redirect HTTP traffic to HTTPS automatically
- Serve multiple domains from a single Nginx instance

## Prerequisites

### Required Components
- **Nginx** (v1.18+ for Ubuntu 20.04, v1.20+ for RHEL 8+) — web server and reverse proxy
- **OpenSSL** — for SSL certificate generation
- **Certbot** (optional) — for Let's Encrypt automatic certificates
- **systemd** — for service management

### System Requirements
- **OS**: Ubuntu 20.04/22.04, Debian 11/12, RHEL 8/9, AlmaLinux 9
- **Privileges**: Root access for installation and configuration
- **RAM**: 512MB minimum (2GB+ recommended for production)
- **CPU**: 1+ core
- **Network**: Domain name pointing to server IP (for SSL certificates)

### Network Requirements
- Port 80: HTTP (for Let's Encrypt challenges and HTTP→HTTPS redirect)
- Port 443: HTTPS (for secure proxy)
- Backend port: The port your application listens on (default 8080)

## Steps

### Step 1: Prepare the System

Ensure your system is up to date and install required packages:

```bash
# Update system packages
sudo apt-get update && sudo apt-get upgrade -y

# Install required packages
sudo apt-get install -y nginx openssl certbot python3-certbot-nginx

# Verify Nginx installation
nginx -v
# Expected: nginx version: nginx/1.18.0 (or higher)
```

For RHEL/CentOS:
```bash
sudo dnf update -y
sudo dnf install -y nginx openssl certbot python3-certbot-nginx
```

### Step 2: Create the Nginx Reverse Proxy Configuration

Create the Nginx configuration file for your domain:

```bash
sudo nano /etc/nginx/sites-available/your-domain.com.conf
```

Add the following configuration:

```nginx
upstream backend_app {
    server 127.0.0.1:8080;
    keepalive 32;
}

# HTTP to HTTPS redirect
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    location / {
        return 301 https://$host$request_uri;
    }

    # Let's Encrypt ACME challenge
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
}

# HTTPS server block
server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;

    # SSL Certificate Configuration
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    # Modern SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;

    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data:;" always;

    # Proxy Configuration
    location / {
        proxy_pass http://backend_app;
        proxy_http_version 1.1;

        # Pass original headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;

        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
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
}
```

### Step 3: Enable the Site Configuration

```bash
# Create symbolic link to enable the site
sudo ln -s /etc/nginx/sites-available/your-domain.com.conf /etc/nginx/sites-enabled/

# Remove default site if present
sudo rm -f /etc/nginx/sites-enabled/default

# Test the configuration
sudo nginx -t
# Expected output:
# nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
# nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### Step 4: Configure Firewall

```bash
# UFW (Ubuntu/Debian)
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw enable
sudo ufw status

# firewalld (RHEL/CentOS)
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

### Step 5: Obtain SSL Certificate

#### Option A: Let's Encrypt (Recommended)

```bash
# Obtain certificate with automatic Nginx configuration
sudo certbot --nginx -d your-domain.com -d www.your-domain.com \
    --email admin@your-domain.com --agree-tos --non-interactive

# Test automatic renewal
sudo certbot renew --dry-run

# Check renewal timer
sudo systemctl list-timers | grep certbot
```

#### Option B: Self-Signed Certificate (Testing Only)

```bash
# Generate self-signed certificate
sudo mkdir -p /etc/ssl/private

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=your-domain.com"

# Update configuration to use self-signed cert
# Change in server block:
# ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
# ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
```

### Step 6: Start Nginx

```bash
# Enable and start Nginx
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl status nginx
# Verify it's running
curl -I http://localhost
curl -I https://localhost
```

### Step 7: Configure Backend Application

Ensure your backend application is running:

```bash
# Example: Start a simple Node.js app on port 8080
# node app.js &

# Or use a test server
python3 -m http.server 8080 &

# Test the backend directly
curl http://localhost:8080

# Test through Nginx proxy
curl -I http://localhost
curl -I https://localhost
```

### Step 8: Advanced Configuration - Load Balancing

For multiple backend servers:

```nginx
upstream backend_cluster {
    least_conn;
    
    server backend1.example.com:8080 weight=3;
    server backend2.example.com:8080 weight=2;
    server backend3.example.com:8080 weight=1;
    
    keepalive 32;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://backend_cluster;
        # ... rest of proxy configuration
    }
}
```

### Step 9: Configure WebSocket Proxying

For applications using WebSockets:

```nginx
location /ws/ {
    proxy_pass http://backend_app;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_read_timeout 86400;
    proxy_send_timeout 86400;
}
```

## Verify

### Verify Nginx is Running

```bash
# Check service status
sudo systemctl status nginx

# Check listening ports
sudo ss -tlnp | grep nginx
# Expected:
# LISTEN 0 511 *:80 *:* users:(("nginx",pid=1234,fd=6))
# LISTEN 0 511 *:443 *:* users:(("nginx",pid=1234,fd=7))

# Test HTTP redirect
curl -I http://your-domain.com
# Expected: HTTP/1.1 301 Moved Permanently
# Location: https://your-domain.com/

# Test HTTPS
curl -I https://your-domain.com
# Expected: HTTP/1.1 200 OK

# Test health endpoint
curl https://your-domain.com/nginx-health
# Expected: healthy
```

### Verify SSL Certificate

```bash
# Check SSL certificate
openssl s_client -connect your-domain.com:443 -servername your-domain.com </dev/null 2>/dev/null | openssl x509 -noout -dates

# Check SSL grade
curl -I https://your-domain.com | grep -i ssl
# Or use: https://www.ssllabs.com/ssltest/

# Verify certificate contents
sudo certbot certificates
```

### Verify Security Headers

```bash
# Check security headers
curl -I https://your-domain.com | grep -iE "x-frame|x-content|x-xss|referrer"

# Expected headers:
# X-Frame-Options: SAMEORIGIN
# X-Content-Type-Options: nosniff
# X-XSS-Protection: 1; mode=block
# Referrer-Policy: strict-origin-when-cross-origin
```

### Verify Proxy Functionality

```bash
# Check X-Forwarded headers
curl -H "X-Custom-Header: test" -I https://your-domain.com

# View Nginx access logs
sudo tail -f /var/log/nginx/access.log

# View Nginx error logs
sudo tail -f /var/log/nginx/error.log
```

## Rollback

### Remove Nginx Configuration

```bash
# Stop Nginx
sudo systemctl stop nginx

# Disable the site
sudo rm -f /etc/nginx/sites-enabled/your-domain.com.conf

# Remove configuration files
sudo rm -f /etc/nginx/sites-available/your-domain.com.conf

# Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

### Remove SSL Certificates

```bash
# Let's Encrypt
sudo certbot delete --cert-name your-domain.com

# Self-signed
sudo rm -f /etc/ssl/private/nginx-selfsigned.key
sudo rm -f /etc/ssl/certs/nginx-selfsigned.crt
```

### Restore Firewall

```bash
# UFW
sudo ufw delete allow 80/tcp
sudo ufw delete allow 443/tcp

# firewalld
sudo firewall-cmd --permanent --remove-port=80/tcp
sudo firewall-cmd --permanent --remove-port=443/tcp
sudo firewall-cmd --reload
```

### Complete Uninstall

```bash
# Stop and disable Nginx
sudo systemctl stop nginx
sudo systemctl disable nginx

# Remove packages (Ubuntu/Debian)
sudo apt-get remove --purge nginx openssl certbot python3-certbot-nginx
sudo apt-get autoremove

# Remove configuration
sudo rm -rf /etc/nginx
sudo rm -rf /var/log/nginx
sudo rm -rf /var/www/html

# Remove SSL certificates
sudo rm -rf /etc/letsencrypt
```

## Common Errors

### Error: "nginx: [emerg] bind() to 0.0.0.0:443 failed"

**Solution**: Another service is using port 443. Check and stop it:

```bash
sudo ss -tlnp | grep :443
sudo systemctl stop <service-using-443>
# Or kill the process: sudo kill <PID>
```

### Error: "SSL_do_handshake() failed"

**Solution**: Check SSL certificate paths and permissions:

```bash
# Verify certificate files exist
ls -la /etc/letsencrypt/live/your-domain.com/

# Check certificate validity
openssl x509 -in /etc/letsencrypt/live/your-domain.com/cert.pem -noout -dates

# Fix permissions
sudo chmod 644 /etc/letsencrypt/live/your-domain.com/fullchain.pem
sudo chmod 600 /etc/letsencrypt/live/your-domain.com/privkey.pem
```

### Error: "502 Bad Gateway"

**Solution**: Backend service is not running or not accessible:

```bash
# Check backend is running
curl http://127.0.0.1:8080

# Check Nginx error logs
sudo tail -50 /var/log/nginx/error.log

# Verify backend configuration in Nginx
grep -A5 "proxy_pass" /etc/nginx/sites-available/your-domain.conf
```

### Error: "504 Gateway Timeout"

**Solution**: Increase timeout values or check backend performance:

```nginx
# Add to location block:
proxy_connect_timeout 300s;
proxy_send_timeout 300s;
proxy_read_timeout 300s;
```

```bash
# Reload Nginx
sudo systemctl reload nginx
```

### Error: "Too many redirects"

**Solution**: Check for redirect loops in configuration:

```bash
# Check configuration for redirect loops
grep -r "return 301\|return 302" /etc/nginx/sites-available/

# Check backend application redirects
curl -I http://127.0.0.1:8080
```

### Error: "WebSocket connection failed"

**Solution**: Ensure WebSocket headers are properly configured:

```nginx
location / {
    proxy_pass http://backend;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```

```bash
# Test WebSocket
curl -i -N \
    -H "Connection: Upgrade" \
    -H "Upgrade: websocket" \
    -H "Sec-WebSocket-Version: 13" \
    -H "Sec-WebSocket-Key: test" \
    https://your-domain.com/ws/
```

### Error: "Permission denied" accessing Unix socket

**Solution**: Check socket file permissions:

```bash
# Check socket file
ls -la /var/run/nginx.sock

# Add user to the socket group
sudo usermod -a -G www-data $USER
newgrp www-data

# Or fix socket permissions in Nginx
# Add to /etc/nginx/nginx.conf:
user www-data;
```

## References

- [Nginx Reverse Proxy Documentation](https://nginx.org/en/docs/http/ngx_http_proxy_module.html)
- [Nginx SSL Configuration](https://nginx.org/en/docs/http/ngx_http_ssl_module.html)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- [Certbot Documentation](https://certbot.eff.org/)
- [Let's Encrypt](https://letsencrypt.org/)
- [Security Headers Reference](https://owasp.org/www-project-secure-headers/)
- [WebSocket Proxying](https://www.nginx.com/blog/websocket-nginx/)
