# Linux Cheatsheet

## System Information

| Command | Description |
|---------|-------------|
| `uname -a` | Kernel version and system info |
| `hostname` | Current hostname |
| `uptime` | System uptime |
| `cat /etc/os-release` | OS details |
| `lscpu` | CPU information |
| `lsblk` | Block devices |
| `free -h` | Memory usage |
| `df -h` | Disk usage |

## Process Management

| Command | Description |
|---------|-------------|
| `ps aux` | All running processes |
| `ps -ef` | Full process listing |
| `top` | Interactive process viewer |
| `htop` | Enhanced process viewer |
| `pkill <name>` | Kill processes by name |
| `kill -9 <pid>` | Force kill process |
| `pgrep <name>` | Find PIDs by name |
| `pstree` | Process tree |

## Service Management (systemd)

| Command | Description |
|---------|-------------|
| `systemctl status <service>` | Service status |
| `systemctl start <service>` | Start service |
| `systemctl stop <service>` | Stop service |
| `systemctl restart <service>` | Restart service |
| `systemctl enable <service>` | Enable at boot |
| `systemctl disable <service>` | Disable at boot |
| `systemctl --failed` | List failed services |
| `systemctl list-units --type=service` | All services |

## Networking

| Command | Description |
|---------|-------------|
| `ip addr` | Network interfaces |
| `ip route` | Routing table |
| `ss -tulpn` | Listening ports |
| `netstat -tulpn` | Legacy port listing |
| `curl -I <url>` | HTTP headers |
| `wget <url>` | Download file |
| `nslookup <domain>` | DNS lookup |
| `dig <domain>` | Detailed DNS query |
| `traceroute <host>` | Trace route |
| `mtr <host>` | Continuous traceroute |

## Disk Usage

| Command | Description |
|---------|-------------|
| `df -h` | Disk space usage |
| `du -sh <dir>` | Directory size |
| `du -h --max-depth=1` | Subdirectory sizes |
| `ls -lhS` | Files sorted by size |
| `ncdu` | Interactive disk analyzer |

## File Operations

| Command | Description |
|---------|-------------|
| `find / -name <file>` | Find file by name |
| `find / -mtime -7` | Files modified in 7 days |
| `locate <file>` | Quick file search |
| `tar -czf archive.tar.gz <dir>` | Create tar.gz |
| `tar -xzf archive.tar.gz` | Extract tar.gz |
| `rsync -av src/ dest/` | Sync directories |

## Logs

| Command | Description |
|---------|-------------|
| `tail -f /var/log/syslog` | Follow system log |
| `journalctl -u <service>` | Service journal |
| `journalctl -xe` | Recent system events |
| `less +G /var/log/auth.log` | Authentication log |

## Permissions

| Command | Description |
|---------|-------------|
| `chmod 755 <file>` | Set rwxr-xr-x |
| `chown user:group <file>` | Change owner |
| `chmod +x <script>` | Make executable |
| `getfacl <file>` | View ACLs |

## Users

| Command | Description |
|---------|-------------|
| `whoami` | Current user |
| `who` | Logged in users |
| `last` | Recent logins |
| `id` | User ID and groups |
| `sudo -i` | Switch to root |

## Performance

| Command | Description |
|---------|-------------|
| `top` | CPU/memory usage |
| `htop` | Interactive monitor |
| `iostat` | I/O statistics |
| `vmstat 1` | Virtual memory stats |
| `sar` | System activity reporter |
| `dstat` | Combined stats |

## Security

| Command | Description |
|---------|-------------|
| `fail2ban-client status` | Fail2ban status |
| `ufw status` | UFW firewall status |
| `iptables -L` | iptables rules |
| `aide --check` | File integrity |
| `rkhunter --check` | Rootkit detection |

## Cron

| Command | Description |
|---------|-------------|
| `crontab -e` | Edit crontab |
| `crontab -l` | List crontab |
| `systemctl status cron` | Cron service status |
