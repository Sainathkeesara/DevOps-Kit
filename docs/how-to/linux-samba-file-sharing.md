# Linux File Sharing with Samba

## Purpose

Deploy and configure Samba as a file sharing server on Ubuntu 24.04 LTS to provide SMB/CIFS network shares accessible from Windows, macOS, and Linux clients. This guide covers installation, share configuration, user management, security hardening, and firewall setup.

## When to use

- You need cross-platform file sharing between Linux, Windows, and macOS
- You want centralized file storage accessible over a local network
- You are replacing a Windows file server with a Linux-based alternative
- You need authenticated access with per-share permissions
- You want to integrate with existing Active Directory or use standalone authentication

## Prerequisites

- Ubuntu 24.04 LTS (or Ubuntu 22.04 LTS) with root access
- Minimum 1 CPU core, 512 MB RAM (production: 2+ cores, 2 GB+ RAM)
- At least one dedicated data partition or directory for shared files
- Network connectivity between server and clients on ports 445/tcp and 139/tcp
- DNS resolution or static IP for the Samba server

```bash
# Verify prerequisites
lsb_release -a                                    # Ubuntu 24.04 or 22.04
nproc                                             # >= 1 core
free -h                                           # >= 512 MB available
ss -tlnp | grep -E ':445|:139'                    # ports not in use
df -h /srv/samba                                  # sufficient disk space for shares
```

## Steps

### Step 1 — Install Samba

```bash
apt-get update
apt-get install -y samba samba-common-bin smbclient

# Verify installation
smbd --version
# Expected: Version 4.19.x or 4.20.x

systemctl enable smbd nmbd
systemctl status smbd
```

### Step 2 — Backup default configuration

```bash
cp /etc/samba/smb.conf /etc/samba/smb.conf.bak.$(date +%Y%m%d)
```

### Step 3 — Create share directories

```bash
mkdir -p /srv/samba/shared
mkdir -p /srv/samba/department
mkdir -p /srv/samba/readonly

# Set ownership
chown root:root /srv/samba/shared
chown root:root /srv/samba/department
chown root:root /srv/samba/readonly

# Set base permissions
chmod 2770 /srv/samba/shared
chmod 2770 /srv/samba/department
chmod 2755 /srv/samba/readonly
```

### Step 4 — Configure Samba

Replace `/etc/samba/smb.conf` with:

```ini
[global]
   workgroup = WORKGROUP
   server string = Samba Server %v
   server role = standalone server
   security = user
   map to guest = never

   # Logging
   log file = /var/log/samba/log.%m
   max log size = 5000
   log level = 2

   # Protocol settings
   server min protocol = SMB2
   server max protocol = SMB3
   smb encrypt = desired

   # Performance
   socket options = TCP_NODELAY IPTOS_LOWDELAY
   read raw = yes
   write raw = yes
   max xmit = 65535
   dead time = 15

   # Security
   restrict anonymous = 2
   disable netbios = yes
   smb ports = 445

   # Printer support disabled
   load printers = no
   printing = bsd
   printcap name = /dev/null

# --- Public authenticated share ---
[shared]
   path = /srv/samba/shared
   browseable = yes
   read only = no
   valid users = @smbgroup
   force group = smbgroup
   create mask = 0660
   directory mask = 2770
   force create mode = 0660
   force directory mode = 2770

# --- Department share (restricted access) ---
[department]
   path = /srv/samba/department
   browseable = yes
   read only = no
   valid users = @deptgroup
   force group = deptgroup
   create mask = 0660
   directory mask = 2770
   force create mode = 0660
   force directory mode = 2770

# --- Read-only share ---
[readonly]
   path = /srv/samba/readonly
   browseable = yes
   read only = yes
   guest ok = no
   valid users = @smbgroup
```

### Step 5 — Create Samba users

```bash
# Create system groups
groupadd -f smbgroup
groupadd -f deptgroup

# Create system user and add to Samba
useradd -M -s /usr/sbin/nologin shareuser1 2>/dev/null || true
usermod -aG smbgroup shareuser1
echo "shareuser1:SecurePass123!" | chpasswd
smbpasswd -a shareuser1
smbpasswd -e shareuser1

# Create department user
useradd -M -s /usr/sbin/nologin deptuser1 2>/dev/null || true
usermod -aG deptgroup deptuser1
usermod -aG smbgroup deptuser1
echo "deptuser1:SecurePass456!" | chpasswd
smbpasswd -a deptuser1
smbpasswd -e deptuser1
```

### Step 6 — Validate configuration

```bash
# Test Samba configuration syntax
testparm -s /etc/samba/smb.conf
# Expected: Loaded services file OK

# Verify share listing
smbclient -L localhost -U shareuser1
# Expected: lists shared, department, readonly shares
```

### Step 7 — Configure AppArmor (if enabled)

```bash
# Allow Samba to access custom share paths
cat > /etc/apparmor.d/local/usr.sbin.smbd << 'EOF'
/srv/samba/** rwlk,
EOF

apparmor_parser -r /etc/apparmor.d/usr.sbin.smbd
```

### Step 8 — Restart Samba services

```bash
systemctl restart smbd nmbd
systemctl status smbd

# Verify listening ports
ss -tlnp | grep -E 'smbd|:445'
# Expected: LISTEN on 0.0.0.0:445
```

### Step 9 — Configure firewall

```bash
ufw allow Samba comment 'Samba file sharing'
ufw reload
ufw status verbose
# Expected: Samba ALLOW from Anywhere
```

### Step 10 — Set up log rotation

```bash
cat > /etc/logrotate.d/samba << 'EOF'
/var/log/samba/log.* {
    daily
    rotate 14
    missingok
    notifempty
    compress
    delaycompress
    postrotate
        systemctl reload smbd > /dev/null 2>&1 || true
    endscript
}
EOF
```

## Verify

```bash
# 1. Check Samba services are running
systemctl is-active smbd && systemctl is-active nmbd
# Expected: active active

# 2. Verify configuration syntax
testparm -s /etc/samba/smb.conf 2>&1 | head -3
# Expected: Loaded services file OK

# 3. List available shares
smbclient -L localhost -N 2>&1 | grep -E 'Disk|IPC'
# Expected: shared, department, readonly listed as Disk

# 4. Test authenticated share access
smbclient //localhost/shared -U shareuser1 -c 'ls'
# Expected: lists files in /srv/samba/shared

# 5. Test write access
echo "test-file" | smbclient //localhost/shared -U shareuser1 -c 'put - testfile.txt'
# Expected: putting file testfile.txt

# 6. Test read-only share denies writes
echo "test" | smbclient //localhost/readonly -U shareuser1 -c 'put - test.txt' 2>&1
# Expected: NT_STATUS_ACCESS_DENIED

# 7. Verify permissions on share directories
ls -la /srv/samba/
# Expected: correct ownership and SGID bits

# 8. Check firewall rules
ufw status | grep Samba
# Expected: Samba ALLOW
```

## Rollback

```bash
# Stop Samba services
systemctl stop smbd nmbd
systemctl disable smbd nmbd

# Restore original configuration
cp /etc/samba/smb.conf.bak.$(date +%Y%m%d) /etc/samba/smb.conf

# Remove share directories
rm -rf /srv/samba/shared /srv/samba/department /srv/samba/readonly

# Remove Samba users
smbpasswd -x shareuser1 2>/dev/null || true
smbpasswd -x deptuser1 2>/dev/null || true

# Remove system users and groups
userdel shareuser1 2>/dev/null || true
userdel deptuser1 2>/dev/null || true
groupdel smbgroup 2>/dev/null || true
groupdel deptgroup 2>/dev/null || true

# Remove firewall rules
ufw delete allow Samba
ufw reload

# Remove logrotate config
rm -f /etc/logrotate.d/samba

# Optional: purge Samba packages
apt-get remove --purge -y samba samba-common-bin smbclient
```

## Common errors

**Error: `session setup failed: NT_STATUS_LOGON_FAILURE`**
Cause: Username/password mismatch or user not added to Samba database.
Fix: Re-add the user with `smbpasswd -a <username>`. Verify with `pdbedit -L -v <username>`.

**Error: `tree connect failed: NT_STATUS_BAD_NETWORK_NAME`**
Cause: Share name does not match configuration or path does not exist.
Fix: Check `[share]` section in `smb.conf`. Verify path exists: `ls -la /srv/samba/<share>`.

**Error: `NT_STATUS_ACCESS_DENIED` on write operations**
Cause: Filesystem permissions deny the Samba user. Samba's `valid users` allows access but OS permissions still apply.
Fix: `chown root:smbgroup /srv/samba/shared && chmod 2770 /srv/samba/shared`. Verify the user is in the group: `groups <username>`.

**Error: `smbd: bind failed on port 445`**
Cause: Port 445 already in use (e.g., by another SMB service or system smb).
Fix: `ss -tlnp | grep ':445'` to find the conflicting process. Stop it with `systemctl stop <service>`.

**Error: `Connection to <host> failed: Error NT_STATUS_CONNECTION_REFUSED`**
Cause: Firewall blocking port 445 or smbd not running.
Fix: `ufw status` to verify Samba rule exists. `systemctl status smbd` to verify service is running.

**Error: `testparm` reports `WARNING: no lock directory`**
Cause: Lock directory `/var/run/samba` missing or wrong permissions.
Fix: `mkdir -p /var/run/samba && chmod 755 /var/run/samba && systemctl restart smbd`.

## References

- Samba Official Documentation — https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html (accessed 2026-03-26)
- Samba Wiki — https://wiki.samba.org/index.php/Main_Page (accessed 2026-03-26)
- Ubuntu Samba Guide — https://ubuntu.com/server/docs/samba-file-server (accessed 2026-03-26)
- Samba Security — https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html#SECURITY (accessed 2026-03-26)
- AppArmor Samba Profile — https://wiki.ubuntu.com/DebuggingApparmor (accessed 2026-03-26)
