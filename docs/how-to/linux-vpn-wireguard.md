# Linux VPN Server Setup with WireGuard

## Purpose

This guide explains how to set up and configure a secure VPN server on Linux using WireGuard. WireGuard is a modern, high-performance VPN protocol that offers simplicity, speed, and strong security.

## When to Use

Use this guide when you need to:
- Set up a remote access VPN for employees working from home or traveling
- Create a site-to-site VPN between multiple office locations
- Establish a secure tunnel for accessing private network resources
- Replace legacy VPN solutions (OpenVPN, IPSec) with a more performant alternative
- Enable secure communications between cloud instances across different regions

## Prerequisites

### System Requirements
- **OS**: Ubuntu 20.04/22.04, Debian 11/12, RHEL 8/9, Rocky Linux 9, AlmaLinux 9
- **Architecture**: x86_64 or ARM64
- **RAM**: 512MB minimum (1GB+ recommended for production)
- **CPU**: 1+ cores
- **Disk**: 5GB+ available space
- **Network**: Static public IP address, open UDP ports (default 51820)

### Network Requirements
- Static public IP address or dynamic DNS
- UDP port 51820 open in firewall (configurable)
- Internet connectivity with proper routing

### Knowledge Prerequisites
- Basic Linux system administration
- Understanding of networking concepts (IP routing, NAT, firewall)
- Familiarity with command-line operations

## Steps

### Step 1: Update System and Install Dependencies

Update your package lists and install required packages:

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y wireguard wireguard-tools wireguard-dkms iptables iputils-ping curl wget

# RHEL/CentOS
sudo dnf install -y wireguard-tools iptables curl wget

# Enable IP forwarding
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-wireguard.conf
sudo sysctl -p
```

### Step 2: Generate Server Keys

Generate the WireGuard server private and public key pair:

```bash
# Create WireGuard directory
sudo mkdir -p /etc/wireguard
sudo chmod 700 /etc/wireguard

# Generate server keys
wg genkey | sudo tee /etc/wireguard/privatekey
sudo cat /etc/wireguard/privatekey | wg pubkey | sudo tee /etc/wireguard/publickey

# Set proper permissions
sudo chmod 600 /etc/wireguard/privatekey
sudo chmod 644 /etc/wireguard/publickey
```

### Step 3: Configure WireGuard Server

Create the WireGuard server configuration file:

```bash
sudo nano /etc/wireguard/wg0.conf
```

Add the following configuration:

```ini
# Server configuration
[Interface]
# Server's private key (from /etc/wireguard/privatekey)
PrivateKey = <SERVER_PRIVATE_KEY>
# VPN interface address
Address = 10.0.0.1/24
# Listen port
ListenPort = 51820
# Save configuration on shutdown
SaveConfig = true
# Firewall rules
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Example peer configuration
[Peer]
# Client's public key
PublicKey = <CLIENT_PUBLIC_KEY>
# Allowed IP addresses (client's VPN network)
AllowedIPs = 10.0.0.2/32
# Persistent keepalive (optional)
PersistentKeepalive = 25
```

### Step 4: Configure Firewall

Set up firewall rules to allow WireGuard traffic:

```bash
# UFW (Ubuntu)
sudo ufw allow 51820/udp

# firewalld (RHEL/CentOS)
sudo firewall-cmd --permanent --add-port=51820/udp
sudo firewall-cmd --permanent --add-masquerade
sudo firewall-cmd --reload

# iptables (direct)
sudo iptables -A INPUT -p udp --dport 51820 -j ACCEPT
sudo iptables -A FORWARD -i wg0 -j ACCEPT
sudo iptables -A FORWARD -o wg0 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

### Step 5: Start and Enable WireGuard

Start the WireGuard service:

```bash
# Start WireGuard
sudo wg-quick up wg0

# Enable on boot
sudo systemctl enable wg-quick@wg0

# Check status
sudo wg show
sudo wg showconf wg0
```

### Step 6: Generate Client Configuration

Create client configuration for connecting devices:

```bash
# Generate client keys
wg genkey | tee client-private.key
cat client-private.key | wg pubkey > client-public.key

# Create client configuration
cat > client.conf <<EOF
[Interface]
PrivateKey = <CLIENT_PRIVATE_KEY>
Address = 10.0.0.2/24
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>
Endpoint = your-server-ip:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF
```

## Verify

### Verify Server is Running

```bash
# Check WireGuard interface
ip addr show wg0

# Check WireGuard status
sudo wg show

# Check listening port
sudo ss -ulnp | grep 51820
```

### Verify Connectivity

```bash
# Ping VPN interface
ping -c 3 10.0.0.1

# Check routing
ip route

# Check firewall rules
sudo iptables -L -n -v
```

### Test from Client

```bash
# Import client config (Linux)
sudo wg-quick up wg0

# Check connection
sudo wg show

# Test connectivity
ping -c 3 10.0.0.1
```

## Rollback

### Stop WireGuard

```bash
# Stop WireGuard interface
sudo wg-quick down wg0

# Disable service
sudo systemctl disable wg-quick@wg0
```

### Remove Configuration

```bash
# Remove WireGuard packages
# Ubuntu/Debian
sudo apt-get remove -y wireguard-tools wireguard-dkms

# RHEL/CentOS
sudo dnf remove -y wireguard-tools

# Remove configuration
sudo rm -rf /etc/wireguard
```

### Reset Firewall

```bash
# UFW
sudo ufw delete allow 51820/udp

# firewalld
sudo firewall-cmd --permanent --remove-port=51820/udp
sudo firewall-cmd --permanent --remove-masquerade
sudo firewall-cmd --reload

# iptables
sudo iptables -D INPUT -p udp --dport 51820 -j ACCEPT
```

## Common Errors

### Error: "wg: interface: Operation not permitted"

**Solution**: Ensure kernel module is loaded and you have proper permissions.

```bash
# Check if WireGuard module is loaded
lsmod | grep wireguard

# Load module if needed
sudo modprobe wireguard

# Check permissions
sudo setcap cap_net_admin+ep /usr/bin/wg
```

### Error: "RTNETLINK answers: Operation not permitted"

**Solution**: Enable IP forwarding and check network configuration.

```bash
# Enable IP forwarding
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

# Make persistent
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-wireguard.conf
sudo sysctl -p
```

### Error: "Handshake did not complete"

**Solution**: Check firewall rules, network connectivity, and time synchronization.

```bash
# Check firewall on server
sudo iptables -L -n | grep 51820

# Check if port is accessible
nc -zvu your-server-ip 51820

# Check system time
timedatectl status
sudo timedatectl set-timezone UTC
```

### Error: "Cannot assign requested address"

**Solution**: Verify the address range is not conflicting with existing networks.

```bash
# Check existing interfaces
ip addr show

# Use a different address range
# Edit /etc/wireguard/wg0.conf and change Address = 10.0.0.1/24
```

### Error: "Peer is not responding"

**Solution**: Check peer configuration and network path.

```bash
# Verify peer is configured on server
sudo wg show

# Check endpoint is reachable
ping -c 3 your-server-ip

# Enable persistent keepalive
# Add PersistentKeepalive = 25 to [Peer] section
```

## References

- [WireGuard Official Documentation](https://www.wireguard.com/)
- [WireGuard Installation Guide](https://github.com/wireguard/wireguard-tools)
- [Ubuntu WireGuard Setup](https://ubuntu.com/tutorials/install-and-configure-wireguard-vpn-server)
- [Rocky Linux WireGuard Guide](https://docs.rockylinux.org/guides/security/wireguard_vpn/)
- [WireGuard Performance Benchmarks](https://www.wireguard.com/performance/)