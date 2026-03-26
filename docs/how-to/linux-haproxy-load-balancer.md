# Linux Load Balancer with HAProxy

## Purpose

Deploy and configure HAProxy as a Layer 4/7 load balancer on Ubuntu 24.04 LTS to distribute traffic across multiple backend servers. This guide covers installation, configuration for HTTP and TCP workloads, SSL/TLS termination, health checks, logging, and monitoring with Prometheus exporter.

## When to use

- You need to distribute incoming traffic across multiple application servers
- You require SSL/TLS termination at the load balancer layer
- You want health-check-based automatic failover for backend services
- You are replacing a cloud load balancer with a self-hosted alternative
- You need Layer 7 routing (path-based, header-based) or Layer 4 TCP proxying

## Prerequisites

- Ubuntu 24.04 LTS (or Ubuntu 22.04 LTS) with root access
- Minimum 1 CPU core, 512 MB RAM (production: 2+ cores, 2 GB+ RAM)
- At least 2 backend servers with HTTP services running on a known port
- DNS records or /etc/hosts entries for backend hostnames
- Ports 80, 443, and 8404 (stats) open in firewall
- TLS certificate and private key for SSL termination (Let's Encrypt or CA-issued)

```bash
# Verify prerequisites
lsb_release -a                                    # Ubuntu 24.04 or 22.04
nproc                                             # >= 1 core
free -h                                           # >= 512 MB available
ss -tlnp | grep ':80 \|:443 '                     # ports 80/443 not in use
curl -s http://backend1:8080/health               # backend reachable
curl -s http://backend2:8080/health               # backend reachable
```

## Steps

### Step 1 — Install HAProxy

```bash
apt-get update
apt-get install -y haproxy

# Verify installation
haproxy -v
# Expected: HAProxy version 2.8.x or 2.9.x

systemctl enable haproxy
systemctl status haproxy
```

### Step 2 — Backup default configuration

```bash
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak.$(date +%Y%m%d)
```

### Step 3 — Configure frontend and backend (HTTP)

Create `/etc/haproxy/haproxy.cfg`:

```haproxy
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

    # TLS tuning
    ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets
    tune.ssl.default-dh-param 2048

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    option  forwardfor
    option  http-server-close
    timeout connect 5000
    timeout client  50000
    timeout server  50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http

# --- HTTP frontend (redirect to HTTPS) ---
frontend http_front
    bind *:80
    http-request redirect scheme https code 301 unless { ssl_fc }

# --- HTTPS frontend ---
frontend https_front
    bind *:443 ssl crt /etc/haproxy/certs/site.pem alpn h2,http/1.1
    mode http

    # Security headers
    http-response set-header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
    http-response set-header X-Content-Type-Options "nosniff"
    http-response set-header X-Frame-Options "DENY"

    # Add X-Forwarded-For
    http-request set-header X-Forwarded-Proto https

    # ACL: path-based routing
    acl is_api path_beg /api/
    acl is_static path_beg /static/ /assets/

    use_backend api_servers if is_api
    use_backend static_servers if is_static
    default_backend app_servers

# --- Stats page ---
frontend stats
    bind *:8404
    mode http
    stats enable
    stats uri /stats
    stats refresh 10s
    stats admin if LOCALHOST
    stats auth admin:changeme
```

### Step 4 — Configure backend server pools

Append to `/etc/haproxy/haproxy.cfg`:

```haproxy
# --- Application backend ---
backend app_servers
    mode http
    balance roundrobin
    option httpchk GET /health
    http-check expect status 200

    server app1 10.0.1.10:8080 check inter 5s fall 3 rise 2 weight 100
    server app2 10.0.1.11:8080 check inter 5s fall 3 rise 2 weight 100
    server app3 10.0.1.12:8080 check inter 5s fall 3 rise 2 weight 100 backup

# --- API backend ---
backend api_servers
    mode http
    balance source
    option httpchk GET /api/health
    http-check expect status 200

    server api1 10.0.1.20:8080 check inter 5s fall 3 rise 2
    server api2 10.0.1.21:8080 check inter 5s fall 3 rise 2

# --- Static content backend ---
backend static_servers
    mode http
    balance roundrobin
    option httpchk GET /health
    http-check expect status 200

    server static1 10.0.1.30:8080 check inter 10s fall 2 rise 2
    server static2 10.0.1.31:8080 check inter 10s fall 2 rise 2
```

### Step 5 — Prepare TLS certificate

```bash
mkdir -p /etc/haproxy/certs

# Option A: Combine Let's Encrypt cert and key
cat /etc/letsencrypt/live/example.com/fullchain.pem \
    /etc/letsencrypt/live/example.com/privkey.pem \
    > /etc/haproxy/certs/site.pem

chmod 600 /etc/haproxy/certs/site.pem

# Option B: Self-signed for testing only
openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
    -keyout /etc/haproxy/certs/site.key \
    -out /etc/haproxy/certs/site.crt \
    -subj "/CN=haproxy.example.com"
cat /etc/haproxy/certs/site.crt /etc/haproxy/certs/site.key > /etc/haproxy/certs/site.pem
chmod 600 /etc/haproxy/certs/site.pem
```

### Step 6 — Configure rsyslog for HAProxy logging

Create `/etc/rsyslog.d/49-haproxy.conf`:

```bash
cat > /etc/rsyslog.d/49-haproxy.conf << 'EOF'
$ModLoad imudp
$UDPServerRun 514
local0.* /var/log/haproxy.log
local1.* /var/log/haproxy.log
EOF

systemctl restart rsyslog
```

### Step 7 — Validate and start HAProxy

```bash
# Validate configuration syntax
haproxy -c -f /etc/haproxy/haproxy.cfg
# Expected: Configuration file is valid

# Start HAProxy
systemctl restart haproxy

# Verify it is running and listening
systemctl status haproxy
ss -tlnp | grep haproxy
# Expected: listening on :80, :443, :8404
```

### Step 8 — Install and configure HAProxy Prometheus exporter

```bash
cd /tmp
wget https://github.com/prometheus/haproxy_exporter/releases/download/v0.15.0/haproxy_exporter-0.15.0.linux-amd64.tar.gz
tar xzf haproxy_exporter-0.15.0.linux-amd64.tar.gz
cp haproxy_exporter-0.15.0.linux-amd64/haproxy_exporter /usr/local/bin/
chmod +x /usr/local/bin/haproxy_exporter

# Create systemd service
cat > /etc/systemd/system/haproxy-exporter.service << 'EOF'
[Unit]
Description=HAProxy Prometheus Exporter
After=haproxy.service
Requires=haproxy.service

[Service]
ExecStart=/usr/local/bin/haproxy_exporter --haproxy.scrape-uri="http://admin:changeme@localhost:8404/stats;csv"
Restart=always
User=haproxy
Group=haproxy

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable haproxy-exporter
systemctl start haproxy-exporter

# Verify exporter is running
curl -s http://localhost:9101/metrics | head -20
```

### Step 9 — Configure log rotation

Create `/etc/logrotate.d/haproxy`:

```bash
cat > /etc/logrotate.d/haproxy << 'EOF'
/var/log/haproxy.log {
    daily
    rotate 14
    missingok
    notifempty
    compress
    delaycompress
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
EOF
```

### Step 10 — Configure firewall

```bash
ufw allow 80/tcp comment 'HAProxy HTTP'
ufw allow 443/tcp comment 'HAProxy HTTPS'
ufw allow 8404/tcp comment 'HAProxy Stats'
ufw reload
```

## Verify

```bash
# 1. Check HAProxy process is running
systemctl is-active haproxy
# Expected: active

# 2. Verify configuration syntax
haproxy -c -f /etc/haproxy/haproxy.cfg
# Expected: Configuration file is valid

# 3. Test HTTP → HTTPS redirect
curl -sI http://localhost/ | head -5
# Expected: HTTP/1.1 301 Moved, Location: https://...

# 4. Test HTTPS frontend (self-signed cert requires -k)
curl -sk https://localhost/health
# Expected: HTTP 200 from backend

# 5. Verify backend health checks
curl -s 'http://admin:changeme@localhost:8404/stats;csv' | grep -E 'app_servers|api_servers'
# Expected: UP status for each backend server

# 6. Check Prometheus metrics
curl -s http://localhost:9101/metrics | grep haproxy_up
# Expected: haproxy_up 1

# 7. Verify logs are being written
tail -5 /var/log/haproxy.log
# Expected: recent connection logs

# 8. Test path-based routing
curl -sk https://localhost/api/health
# Expected: response from api_servers backend
```

## Rollback

```bash
# Stop HAProxy and exporter
systemctl stop haproxy-exporter
systemctl stop haproxy
systemctl disable haproxy
systemctl disable haproxy-exporter

# Restore original configuration
cp /etc/haproxy/haproxy.cfg.bak.$(date +%Y%m%d) /etc/haproxy/haproxy.cfg
systemctl restart haproxy

# If completely removing
apt-get remove --purge -y haproxy
rm -rf /etc/haproxy/certs
rm /etc/rsyslog.d/49-haproxy.conf
rm /etc/systemd/system/haproxy-exporter.service
systemctl daemon-reload
systemctl restart rsyslog

# Remove firewall rules
ufw delete allow 80/tcp
ufw delete allow 443/tcp
ufw delete allow 8404/tcp
```

## Common errors

**Error: `[ALERT] 085/143000 (1234) : Parsing [/etc/haproxy/haproxy.cfg:42] : 'bind' : 'crt' is not enabled in this build`**
Cause: HAProxy compiled without OpenSSL support.
Fix: Install the OpenSSL-enabled build: `apt-get install haproxy=2.8.*` or compile from source with `USE_OPENSSL=1`.

**Error: `[ALERT] 085/143000 (1234) : Starting frontend https_front: cannot bind socket [0.0.0.0:443]`**
Cause: Port 443 already in use or HAProxy lacks capability to bind privileged ports.
Fix: `ss -tlnp | grep ':443'` to find the conflicting process. Stop it or use `setcap 'cap_net_bind_service=+ep' /usr/sbin/haproxy`.

**Error: Backend servers showing DOWN in stats page**
Cause: Health check endpoint not returning HTTP 200, or firewall blocking connectivity.
Fix: `curl http://<backend-ip>:<port>/health` from the HAProxy host. Check backend firewall rules. Increase `fall` threshold if transient.

**Error: `503 Service Unavailable` on all requests**
Cause: All backend servers in a pool are DOWN (health checks failing).
Fix: Check `/var/log/haproxy.log` for health check failures. Verify backends are running. Temporarily add `option redispatch` and `retries 3` to the backend section.

**Error: SSL handshake failures — `SSL routines:ssl3_get_record:wrong version number`**
Cause: Client connecting to HTTPS port with plain HTTP, or TLS version mismatch.
Fix: Ensure clients connect with HTTPS. Verify `ssl-default-bind-options` matches client TLS capabilities.

**Error: Prometheus exporter shows `haproxy_up 0`**
Cause: Exporter cannot reach HAProxy stats page. Wrong credentials or stats not enabled.
Fix: Verify stats frontend is bound and accessible: `curl http://admin:changeme@localhost:8404/stats`. Check exporter `--haproxy.scrape-uri` matches the stats URL and credentials.

## References

- HAProxy Documentation 2.8 — https://docs.haproxy.org/2.8/intro.html (accessed 2026-03-26)
- HAProxy Configuration Manual — https://docs.haproxy.org/2.8/configuration.html (accessed 2026-03-26)
- HAProxy Prometheus Exporter — https://github.com/prometheus/haproxy_exporter (accessed 2026-03-26)
- Ubuntu HAProxy Wiki — https://ubuntu.com/server/docs/load-balancer-haproxy (accessed 2026-03-26)
- Mozilla SSL Configuration Generator — https://ssl-config.mozilla.org/ (accessed 2026-03-26)
