# Linux Commands Reference
Common bash one-liners for sysadmins

## Purpose
This document provides quick reference one-liner commands for Linux system administration tasks.

## When to use
- Quick reference for common sysadmin operations
- Copy-paste into scripts or terminal

## Prerequisites
- Linux system with bash
- Standard coreutils (top, ps, df, du, free, etc.)

## Commands

### Process Management
```bash
# Show top CPU-consuming processes
ps aux --sort=-%cpu | head -n 10

# Show top memory-consuming processes  
ps aux --sort=-%mem | head -n 10

# Kill all processes matching a name
pkill -f "process-name"

# Find process by name
pgrep -a "process-name"

# Show process tree
pstree -p

# List all zombie processes
ps aux | awk '$8 ~ /Z/ {print}'
```

### Disk Usage
```bash
# Show disk usage by directory (sorted)
du -sh /* 2>/dev/null | sort -rh | head -n 10

# Show disk usage for current directory
du -sh .

# Show inodes usage
df -i

# List mounted filesystems
mount | column -t

# Show disk I/O stats
iostat -x 1 5
```

### Memory
```bash
# Show memory usage summary
free -h

# Show memory usage in MB
free -m

# Clear pagecache
sync && echo 3 > /proc/sys/vm/drop_caches

# Show top memory consumers
smem -r -t
```

### Network
```bash
# Show listening ports
ss -tulpn

# Show established connections
ss -tn state established

# Find process using a port
lsof -i :8080

# Show network interface stats
ip -s link

# Flush DNS cache
systemd-resolve --flush-caches 2>/dev/null || service nscd restart 2>/dev/null || echo 3 > /proc/sys/net/ipv4/ip_local_port_range
```

### Users and Groups
```bash
# List all users
getent passwd | cut -d: -f1

# List users with UID > 1000
getent passwd | awk -F: '$3 >= 1000 {print $1}'

# Show last logged in users
last | head -n 20

# Add user to group
usermod -aG groupname username
```

### File Operations
```bash
# Find files modified in last 24 hours
find /path -type f -mtime -1

# Find files larger than 100MB
find /path -type f -size +100M

# Find duplicate files (by MD5)
find /path -type f -exec md5sum {} \; | sort | uniq -D -w 32

# Remove files older than 30 days
find /path -type f -mtime +30 -delete

# Count lines in all files
find /path -type f -name "*.log" -exec wc -l {} \; | awk '{sum+=$1} END {print sum}'
```

### System Info
```bash
# Show system uptime
uptime

# Show kernel version
uname -r

# Show CPU info
lscpu | grep -E 'Model name|CPU\(s\)|Thread|Core|Socket'

# Show PCI devices
lspci -v

# Show hardware summary
lshw -short
```

### Service Management (systemd)
```bash
# Show service status
systemctl status nginx

# Show failed services
systemctl --failed

# Show service logs
journalctl -u nginx -n 50 --no-pager

# Enable service at boot
systemctl enable nginx

# Restart service
systemctl restart nginx
```

### Archive and Compression
```bash
# Create tar.gz archive
tar -czf archive.tar.gz /path

# Extract tar.gz
tar -xzf archive.tar.gz

# Create zip archive
zip -r archive.zip /path

# Split large file
split -b 100M largefile.zip part_
```

### Text Processing
```bash
# Count unique words in file
cat file.txt | tr -s ' ' '\n' | sort | uniq -c | sort -rn

# Extract IP addresses from log
grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' logfile | sort -u

# Remove duplicate lines
awk '!seen[$0]++' file.txt

# Replace in-place
sed -i 's/old/new/g' file.txt
```

### SSH and Remote
```bash
# Copy SSH key to remote
ssh-copy-id user@host

# Keep SSH connection alive
ssh -o ServerAliveInterval=60 user@host

# Tunnel local port to remote
ssh -L 8080:localhost:80 user@host

# Copy files via SSH
scp -r /local/path user@host:/remote/path
```

## Verify
Test each command in a safe environment before using in production.

## Rollback
Most commands are read-only. For destructive operations, create backups first.

## Common errors
- Permission denied: Use sudo or run as root
- Command not found: Install required package
- Argument list too long: Use find with -exec instead of xargs

## References
- man ps, man top, man ss, man journalctl
- https://www.gnu.org/software/coreutils/manual/