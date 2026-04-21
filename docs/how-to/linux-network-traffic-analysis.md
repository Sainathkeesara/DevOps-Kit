# Linux Network Traffic Analysis Project

## Purpose

This project provides comprehensive guidance on analyzing network traffic in Linux environments using packet capture tools like `nethogs` and `iftop`. It covers installation, configuration, and practical scenarios for monitoring network usage per process and interface.

## When to Use

- When you need to identify which processes are consuming the most bandwidth
- When troubleshooting network connectivity issues
- When monitoring real-time network traffic on servers
- When investigating suspicious outbound connections
- When performing network capacity planning
- When debugging application network behavior

## Prerequisites

- Linux server or workstation (Ubuntu 20.04+, RHEL 8+, Debian 11+)
- Root or sudo access for packet capture tools
- Basic understanding of TCP/IP networking
- Network interface with active connections

## Steps

### Step 1: Install Dependencies

Install the required network monitoring tools:

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y nethogs iftop tcpdump iptraf-ng

# RHEL/CentOS/Fedora
sudo dnf install -y nethogs iftop tcpdump iptraf-ng

# Verify installation
nethogs --version
iftop --version
```

### Step 2: Configure Network Monitoring

Create a configuration directory for network tools:

```bash
sudo mkdir -p /etc/nethogs /etc/iftop
sudo chmod 755 /etc/nethogs /etc/iftop
```

Configure nethogs defaults:

```bash
# /etc/nethogs/nethogs.conf
# Refresh rate in seconds
refreshrate 1

# Show IP addresses (not hostnames)
showip
```

### Step 3: Using NetHogs (Process-Based Monitoring)

NetHogs shows which processes are using the most bandwidth:

```bash
# Monitor all interfaces
sudo nethogs

# Monitor specific interface
sudo nethogs eth0

# Monitor with refresh rate (in tenths of a second)
sudo nethogs -t 5  # Refresh every 0.5 seconds

# Monitor multiple interfaces
sudo nethogs eth0 wlan0

# Non-interactive mode (useful for scripts)
echo "eth0" | sudo nethogs -t
```

Key NetHogs commands while running:
- `m`: Toggle between KB/s and KB/s or packets/s
- `s`: Show TCP socket traffic
- `r`: Reverse order (sort by sent/received)
- `q`: Quit

### Step 4: Using iftop (Interface-Based Monitoring)

iftop shows bandwidth usage per connection:

```bash
# Monitor all traffic on eth0
sudo iftop

# Show only connections to/from host
sudo iftop -f filter

# Display bandwidth in bytes (instead of bits)
sudo iftop -B

# Filter by port
sudo iftop -p -i eth0 -port 80

# Enable DNS resolution (slower)
sudo iftop -n

# Show only local traffic
sudo iftop -i eth0 -f "ip and not net 192.168.0.0/16"

# Non-interactive mode with output to file
sudo iftop -t > /tmp/iftop-output.txt
```

### Step 5: Advanced Packet Capture with tcpdump

For detailed packet analysis:

```bash
# Capture packets on interface
sudo tcpdump -i eth0 -w /tmp/capture.pcap

# Capture specific port
sudo tcpdump -i eth0 port 443 -w /tmp/https.pcap

# Capture with timestamp
sudo tcpdump -tttt -i eth0

# Display packet contents
sudo tcpdump -X -i eth0

# Filter by host
sudo tcpdump -i eth0 host 192.168.1.100

# Limit capture size
sudo tcpdump -i eth0 -c 100 -w /tmp/small.pcap
```

### Step 6: Creating a Network Health Check Script

Create `/usr/local/bin/network-health.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/network-health.log"
INTERFACE="${1:-eth0}"

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if interface exists
check_interface() {
    if ip link show "$INTERFACE" >/dev/null 2>&1; then
        log_info "Interface $INTERFACE exists"
    else
        log_info "ERROR: Interface $INTERFACE not found"
        exit 1
    fi
}

# Get network statistics
check_stats() {
    log_info "Network statistics for $INTERFACE:"
    ip -s link show "$INTERFACE" | grep -E "RX|TX|errors"
}

# Get connection count
check_connections() {
    local count
    count=$(ss -tan | wc -l)
    log_info "Active TCP connections: $count"
}

# Get top talking processes
check_top_processes() {
    log_info "Top network processes (by KB/s):"
    if command -v nethogs >/dev/null 2>&1; then
        timeout 2 sudo nethogs "$INTERFACE" 2>/dev/null || true
    fi
}

main() {
    log_info "=== Network Health Check ==="
    check_interface
    check_stats
    check_connections
    check_top_processes
    log_info "=== Check Complete ==="
}

main "$@"
```

Make it executable:

```bash
chmod +x /usr/local/bin/network-health.sh
```

## Verify

### Verification Commands

1. Verify NetHogs installation:
```bash
nethogs --version
# Should output version information
```

2. Verify iftop installation:
```bash
iftop -version
# Should output version information  
```

3. Test network monitoring script:
```bash
sudo /usr/local/bin/network-health.sh
# Should produce network statistics
```

4. Check active network connections:
```bash
ss -tuln | grep -E "LISTEN|ESTAB"
# Should show listening and established connections
```

5. Verify tcpdump works:
```bash
sudo tcpdump -i lo -c 1 loopback 2>&1 | head -5
# Should capture 1 packet on loopback
```

## Rollback

If network monitoring tools cause issues or are no longer needed:

```bash
# Ubuntu/Debian
sudo apt-get remove --purge nethogs iftop tcpdump iptraf-ng

# RHEL/CentOS
sudo dnf remove nethogs iftop tcpdump iptraf-ng

# Remove custom scripts
sudo rm -f /usr/local/bin/network-health.sh

# Remove logs
sudo rm -f /var/log/network-health.log
```

## Common Errors

| Error | Solution |
|-------|----------|
| `nethogs: command not found` | Install nethogs: `sudo apt-get install nethogs` or compile from source |
| `iftop: command not found` | Install iftop: `sudo apt-get install iftop` |
| `bash: set -euo pipefail: invalid option` | Update bash to version 4.1+ or remove problematic options |
| `command not found` in script | Check PATH includes `/usr/local/bin` or use full path |
| `Operation not permitted` with tcpdump | Use `sudo` or run with elevated privileges |
| `no suitable device found` | Verify network interface name with `ip link show` |
| High CPU usage with nethogs | Use `-t` option with higher value to reduce refresh rate |
| DNS resolution slow with iftop | Use `-n` to disable reverse DNS lookup |

## References

- [NetHogs Official Documentation](https://github.com/raboof/nethogs)
- [iftop Official Documentation](http://www.ex-parrot.com/pdw/iftop/)
- [tcpdump Manual](https://www.tcpdump.org/manpages/tcpdump.1.html)
- [Linux Network Administration Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/monitoring_and_managing_system_status_and_performance/configuring_network_monitoring_tools_monitoring_and_managing_system_status_and_performance)
- [ ss command manual](https://man7.org/linux/man-pages/man8/ss.8.html)
- [ ip command manual](https://man7.org/linux/man-pages/man8/ip.8.html)