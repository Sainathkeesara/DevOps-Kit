# Linux DNS Server Setup with BIND9

## Purpose

This guide explains how to set up and configure a DNS server on Linux using BIND9 (Berkeley Internet Name Domain). BIND9 is the most widely used DNS server software on the internet, providing reliable name resolution for internal networks and domains.

## When to Use

Use this guide when you need to:
- Set up a private DNS server for an internal corporate network
- Create a local domain (e.g., `company.internal`) for your infrastructure
- Replace external DNS dependencies with self-hosted resolution
- Implement DNS-based service discovery in a private network
- Configure forward and reverse DNS zones for your network
- Set up DNS caching to improve query performance

## Prerequisites

### System Requirements
- **OS**: Ubuntu 20.04/22.04, Debian 11/12, RHEL 8/9, Rocky Linux 9, AlmaLinux 9
- **Architecture**: x86_64 or ARM64
- **RAM**: 512MB minimum (1GB+ recommended for production)
- **CPU**: 1+ cores
- **Disk**: 5GB+ available space
- **Network**: Static IP address configured

### Network Requirements
- Static internal IP address
- Firewall rules: TCP/UDP port 53 (DNS)
- Access to upstream DNS servers (e.g., 8.8.8.8, 1.1.1.1)

### Knowledge Prerequisites
- Basic Linux system administration
- Understanding of networking concepts (IP addressing, subnets, DNS)
- Familiarity with command-line operations

## Steps

### Step 1: Update System and Install BIND9

Update your package lists and install BIND9:

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y bind9 bind9utils bind9-doc dnsutils

# RHEL/CentOS
sudo dnf install -y bind bind-utils

# Rocky Linux / AlmaLinux
sudo dnf install -y bind bind-utils
```

### Step 2: Configure BIND9 Options

Edit the main BIND9 configuration file:

```bash
sudo nano /etc/bind/named.conf.options
```

Add the following configuration for a caching DNS server:

```conf
options {
    directory "/var/cache/bind";
    
    // Forward queries to upstream DNS servers
    forwarders {
        8.8.8.8;
        1.1.1.1;
        8.8.4.4;
    };
    
    // Allow queries from local network
    allow-query {
        localhost;
        10.0.0.0/8;    // Private network
        192.168.0.0/16; // Private network
    };
    
    // Enable recursion
    recursion yes;
    
    // Disable DNSSEC validation for internal zones (if needed)
    // dnssec-validation no;
    
    // Listen on localhost only (change for production)
    listen-on { 127.0.0.1; };
    
    // Log queries for debugging (disable in production)
    // querylog yes;
};
```

### Step 3: Create Forward and Reverse Zones

Create a forward zone for your internal domain:

```bash
sudo nano /etc/bind/named.conf.local
```

Add your zone definitions:

```conf
// Forward zone for internal.example.com
zone "internal.example.com" {
    type master;
    file "/etc/bind/zones/db.internal.example.com";
    allow-transfer { 10.0.0.0/8; };
};

// Reverse zone for 10.0.0.0/8
zone "0.0.10.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.10.0.0";
    allow-transfer { 10.0.0.0/8; };
};
```

### Step 4: Create Zone Files

Create the directory for zone files:

```bash
sudo mkdir -p /etc/bind/zones
```

Create the forward zone file:

```bash
sudo nano /etc/bind/zones/db.internal.example.com
```

Add the following content:

```zone
$TTL    604800
@       IN      SOA     ns.internal.example.com. admin.internal.example.com. (
                        2026032501  ; Serial (YYYYMMDDNN)
                        604800      ; Refresh
                        86400       ; Retry
                        2419200     ; Expire
                        604800 )    ; Negative Cache TTL

; Name servers
@       IN      NS      ns.internal.example.com.
@       IN      A       10.0.0.1

; Name server host
ns      IN      A       10.0.0.1

; Additional hosts
gateway IN      A       10.0.0.1
dhcp    IN      A       10.0.0.10
web01   IN      A       10.0.0.101
db01    IN      A       10.0.0.201
```

Create the reverse zone file:

```bash
sudo nano /etc/bind/zones/db.10.0.0
```

Add the following content:

```zone
$TTL    604800
@       IN      SOA     ns.internal.example.com. admin.internal.example.com. (
                        2026032501  ; Serial
                        604800      ; Refresh
                        86400       ; Retry
                        2419200     ; Expire
                        604800 )    ; Negative Cache TTL

; Name servers
@       IN      NS      ns.internal.example.com.
1       IN      PTR     ns.internal.example.com.
10      IN      PTR     dhcp.internal.example.com.
101     IN      PTR     web01.internal.example.com.
201     IN      PTR     db01.internal.example.com.
```

### Step 5: Set Permissions

Set proper permissions on configuration files:

```bash
sudo chown -R bind:bind /etc/bind/zones
sudo chmod 640 /etc/bind/zones/*
sudo chmod 640 /etc/bind/named.conf.local
```

### Step 6: Configure Firewall

Configure firewall rules to allow DNS traffic:

```bash
# UFW (Ubuntu)
sudo ufw allow 53/tcp
sudo ufw allow 53/udp

# firewalld (RHEL/CentOS)
sudo firewall-cmd --permanent --add-service=dns
sudo firewall-cmd --reload

# iptables (direct)
sudo iptables -A INPUT -p tcp --dport 53 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 53 -j ACCEPT
```

### Step 7: Start and Enable BIND9

Start the BIND9 service:

```bash
# Ubuntu/Debian
sudo systemctl enable bind9
sudo systemctl start bind9
sudo systemctl status bind9

# RHEL/CentOS
sudo systemctl enable named
sudo systemctl start named
sudo systemctl status named
```

### Step 8: Configure Client DNS

Configure Linux clients to use your DNS server:

```bash
# Add to /etc/resolv.conf
nameserver 10.0.0.1

# Or use systemd-resolved for Ubuntu
sudo mkdir -p /etc/systemd/resolved.conf.d
echo "[Resolve]" | sudo tee /etc/systemd/resolved.conf.d/dns.conf
echo "DNS=10.0.0.1" | sudo tee -a /etc/systemd/resolved.conf.d/dns.conf
sudo systemctl restart systemd-resolved
```

## Verify

### Verify BIND9 is Running

```bash
# Check service status
sudo systemctl status bind9

# Check if listening on port 53
sudo ss -tulnp | grep :53

# Test DNS query
dig @localhost google.com

# Query internal domain
dig @localhost ns.internal.example.com
```

### Verify Zone Configuration

```bash
# Check zone syntax
sudo named-checkzone internal.example.com /etc/bind/zones/db.internal.example.com

# Test zone transfer
dig axfr internal.example.com @localhost
```

### Verify Logging

```bash
# Check system logs
sudo journalctl -u bind9 -f

# Check query logs (if enabled)
sudo tail -f /var/log/named/query.log
```

## Rollback

### Stop BIND9 Service

```bash
# Stop and disable service
sudo systemctl stop bind9
sudo systemctl disable bind9
```

### Remove Configuration

```bash
# Remove BIND9 packages
# Ubuntu/Debian
sudo apt-get remove -y bind9 bind9utils bind9-doc

# RHEL/CentOS
sudo dnf remove -y bind bind-utils

# Remove configuration
sudo rm -rf /etc/bind/zones
```

### Reset Firewall

```bash
# UFW
sudo ufw delete allow 53/tcp
sudo ufw delete allow 53/udp

# firewalld
sudo firewall-cmd --permanent --remove-service=dns
sudo firewall-cmd --reload
```

## Common Errors

### Error: " rndc: connect failed: 127.0.0.1#953: connection refused"

**Solution**: Ensure BIND9 is running and rndc key is configured.

```bash
# Check if named is running
sudo systemctl status named

# Generate rndc key
sudo rndc-confgen -a
```

### Error: "zone serial number must be incremented"

**Solution**: Update the serial number in zone files before reloading.

```bash
# Edit zone file and increment serial
sudo nano /etc/bind/zones/db.internal.example.com
# Change 2026032501 to 2026032502

# Reload zone
sudo rndc reload
```

### Error: "access denied"

**Solution**: Check file permissions and SELinux context.

```bash
# Fix permissions
sudo chown -R bind:bind /etc/bind/zones

# For RHEL/CentOS with SELinux
sudo setsebool -P named_bind_http_port 1
sudo setsebool -P named_write_master_zones 1
```

### Error: "zone not loaded due to errors"

**Solution**: Validate zone file syntax.

```bash
# Check zone file syntax
sudo named-checkzone internal.example.com /etc/bind/zones/db.internal.example.com

# Check named.conf syntax
sudo named-checkconf
```

### Error: "dig: dig: couldn't get address"

**Solution**: Check network connectivity and firewall rules.

```bash
# Test connectivity
ping -c 3 8.8.8.8

# Check firewall
sudo iptables -L -n | grep 53
```

## References

- [BIND9 Official Documentation](https://www.bind9.net/documentation)
- [ISC BIND Knowledge Base](https://kb.isc.org/)
- [Ubuntu BIND9 Setup Guide](https://ubuntu.com/server/docs/dns-bind)
- [Red Hat BIND Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/managing_networking_infrastructure_services/dns)
- [DNS Security Extensions (DNSSEC)](https://www.cloudflare.com/dns/dnssec/)