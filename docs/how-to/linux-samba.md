# Samba File Server Setup

## Purpose

This guide explains how to set up a Samba file server for cross-platform file sharing between Linux, Windows, and macOS systems. Samba implements the SMB/CIFS protocol, allowing seamless file sharing across heterogeneous networks.

## When to Use

Use this guide when you need to:
- Share files between Linux and Windows workstations
- Create a centralized file storage solution
- Set up a home or office network file server
- Integrate with existing Active Directory domains
- Provide guest-accessible file shares
- Create user-specific private shares with authentication

## Prerequisites

### System Requirements
- **OS**: Ubuntu 22.04+, RHEL 9+, Debian 12+, or SUSE 15+
- **RAM**: Minimum 512MB, recommended 1GB+
- **Disk**: Depends on storage needs (minimum 10GB recommended)
- **Network**: Static IP recommended for production

### Software Requirements
- Samba server (`smbd`)
- Samba client (`smbclient`) for testing
- CIFS utilities (`cifs-utils`) for mounting shares
- `testparm` for configuration validation

### Network Requirements
- Port 445 (SMB over TCP)
- Port 139 (SMB over NetBIOS)
- Firewall rules configured to allow above ports

### Knowledge Prerequisites
- Basic Linux command line knowledge
- Understanding of Linux file permissions
- Familiarity with systemd (for service management)

## Steps

### Step 1: Install Samba

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install -y samba smbclient samba-common-bin cifs-utils
```

**RHEL/CentOS:**
```bash
sudo dnf install -y samba samba-common cifs-utils
```

**Verify installation:**
```bash
smbd --version
testparm -s
```

### Step 2: Prepare the Script

The automation script is located at:
```
scripts/bash/linux/samba-setup.sh
```

Make it executable:
```bash
chmod +x scripts/bash/linux/samba-setup.sh
```

### Step 3: Run the Samba Setup

**Basic installation and configuration:**
```bash
sudo ./scripts/bash/linux/samba-setup.sh --install
```

**Custom share name:**
```bash
sudo ./scripts/bash/linux/samba-setup.sh --install \
  --share-name companyfiles \
  --share-path /data/company
```

**Custom username:**
```bash
sudo ./scripts/bash/linux/samba-setup.sh --install \
  --username admin \
  --group-name admins
```

**Dry-run mode (testing):**
```bash
sudo ./scripts/bash/linux/samba-setup.sh --dry-run --install
```

### Step 4: Configure User Access

After initial setup, create additional users:

```bash
# Create system user
sudo useradd -M -s /sbin/nologin jdoe

# Add Samba password
sudo smbpasswd -a jdoe

# Enable the user
sudo smbpasswd -e jdoe
```

### Step 5: Access the Share

**From Linux (using smbclient):**
```bash
smbclient //servername/share -U username
```

**From Linux (mounting as filesystem):**
```bash
# Create mount point
sudo mkdir -p /mnt/samba

# Mount the share
sudo mount -t cifs //192.168.1.100/share /mnt/samba \
  -o user=username,password=password

# Or with credentials file
sudo mount -t cifs //192.168.1.100/share /mnt/samba \
  -o credentials=/root/.smbcredentials
```

**From macOS:**
```bash
# Using Finder
Go > Connect to Server
smb://192.168.1.100/share

# Using command line
mount_smbfs //username@servername/share /Volumes/share
```

**From Windows:**
```bash
# In File Explorer address bar
\\192.168.1.100\share

# Or map as network drive
net use Z: \\192.168.1.100\share /user:username password
```

### Step 6: Configure Firewall

**UFW (Ubuntu/Debian):**
```bash
sudo ufw allow 445/tcp
sudo ufw allow 139/tcp
sudo ufw reload
```

**firewalld (RHEL):**
```bash
sudo firewall-cmd --permanent --add-service=samba
sudo firewall-cmd --reload
```

### Step 7: Manage the Service

```bash
# Check status
sudo systemctl status smb

# Restart after config changes
sudo systemctl restart smb

# Enable on boot
sudo systemctl enable smb
```

## Verify

### Check Service Status
```bash
systemctl is-active smb
smbstatus
```

### Test Configuration
```bash
testparm -s
```

### List Available Shares
```bash
smbclient -L localhost -N
```

### Verify Share Directory
```bash
ls -la /srv/samba/share
```

### Check Process
```bash
pgrep -a smbd
```

## Rollback

### Remove Samba Completely
```bash
# Stop services
sudo systemctl stop smb nmb

# Remove packages (Ubuntu)
sudo apt purge samba smbclient samba-common-bin

# Remove configuration
sudo rm -rf /etc/samba
sudo rm -rf /srv/samba
```

### Restore Original Config
```bash
# If you backed up during setup
sudo cp /etc/samba/smb.conf.backup.YYYYMMDDHHMMSS /etc/samba/smb.conf
sudo systemctl restart smb
```

### Remove User Shares
```bash
# Delete Samba user
sudo smbpasswd -x username

# Delete system user
sudo userdel -r username

# Remove share directory
sudo rm -rf /srv/samba/share
```

## Common Errors

### Error: "Connection refused"

**Cause**: Samba service not running
**Solution**: 
```bash
sudo systemctl start smb
sudo systemctl enable smb
```

### Error: "NT_STATUS_ACCESS_DENIED"

**Cause**: User not in valid user list or wrong password
**Solution**:
```bash
# Check user exists in Samba
sudo pdbedit -L

# Reset password
sudo smbpasswd -a username
```

### Error: "Tree connect failed: NT_STATUS_BAD_NETWORK_NAME"

**Cause**: Share doesn't exist or name mismatch
**Solution**:
```bash
# Verify share name in config
testparm -s

# Check share path exists
ls -la /srv/samba/
```

### Error: "Permission denied" on mount

**Cause**: SELinux or AppArmor blocking
**Solution**:
```bash
# RHEL: Set SELinux context
sudo setsebool -P samba_enable_home_dirs on

# Ubuntu: Check AppArmor
sudo aa-complain /usr/sbin/smbd
```

### Error: "No route to host"

**Cause**: Firewall blocking or network issue
**Solution**:
```bash
# Check firewall rules
sudo iptables -L -n | grep 445

# Test connectivity
nc -zv 192.168.1.100 445
```

### Error: "Password mismatch"

**Cause**: SMB password different from system password
**Solution**:
```bash
# Set new Samba password
sudo smbpasswd -a username
```

### Error: "Invalid syntax" in testparm

**Cause**: Configuration file syntax error
**Solution**:
```bash
# Restore backup
sudo cp /etc/samba/smb.conf.backup.* /etc/samba/smb.conf

# Or validate manually
testparm -v
```

## References

- [Samba Wiki](https://wiki.samba.org/)
- [Samba Official Documentation](https://www.samba.org/samba/docs/)
- [Samba Security Advisory](https://www.samba.org/samba/security/)
- [Ubuntu Server Guide - Samba](https://ubuntu.com/server/docs/samba)
- [RHEL Samba Documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/managing_file_systems_and_storage/serving-files-with-samba)
- [Samba FAQ](https://www.samba.org/samba/docs/current/man_samba-faq.html)