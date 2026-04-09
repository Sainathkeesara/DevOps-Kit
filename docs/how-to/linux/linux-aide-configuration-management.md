# Linux Configuration Management with AIDE

## Purpose

This guide walks through setting up and using AIDE (Advanced Intrusion Detection Environment) for file integrity monitoring on Linux systems. AIDE creates a database of file attributes and can detect unauthorized changes to critical system files.

## When to use

- Monitor critical system files for unauthorized modifications
- Detect intrusions or malware that modify system binaries
- Validate system integrity after security incidents
- Meet compliance requirements for file integrity monitoring
- Establish a baseline of expected file states

## Prerequisites

- Linux system (tested on RHEL 9, Ubuntu 22.04, Debian 12)
- Root or sudo access
- AIDE package available in system repositories
- Minimum 100MB disk space for AIDE database
-cron or systemd timer for scheduled checks

## Steps

### 1. Install AIDE

**RHEL/Rocky/AlmaLinux:**
```bash
sudo dnf install -y aide
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install -y aide
```

**Verify installation:**
```bash
aide --version
```

### 2. Initialize AIDE Database

```bash
sudo aide --init
```

This creates `/var/lib/aide/aide.db.new` (the initial baseline). Rename to activate:
```bash
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
```

### 3. Configure AIDE

Edit `/etc/aide/aide.conf`:

```bash
# Monitor critical system directories
/etc     NORMAL
/bin     NORMAL
/sbin    NORMAL
/usr/bin NORMAL
/usr/sbin NORMAL
/var     NORMAL
/root    NORMAL

# Exclude temporary directories
/var/log  NORMAL
/var/tmp  NORMAL
/tmp      NORMAL

# Database and log locations
DATABASE=file:/var/lib/aide/aide.db
DATABASEOUT=file:/var/lib/aide/aide.db.new
REPORTFILE=file:/var/log/aide/aide.log
```

### 4. Run Initial Check

```bash
sudo aide --check
```

Expected output shows no differences initially (since the database was just created from the current system state).

### 5. Create Automated Daily Checks

Create systemd timer `/etc/systemd/system/aide-check.timer`:

```bash
[Unit]
Description=AIDE File Integrity Check Timer

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

Create service `/etc/systemd/system/aide-check.service`:

```bash
[Unit]
Description=AIDE File Integrity Check

[Service]
Type=oneshot
ExecStart=/usr/bin/aide --check
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now aide-check.timer
```

### 6. Update Database After Legitimate Changes

After system updates or configuration changes, update the database:

```bash
sudo aide --update
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
```

### 7. Email Alert Integration

Install mail utility:
```bash
# RHEL
sudo dnf install -y mailx

# Ubuntu
sudo apt install -y mailutils
```

Update the systemd service to send email:

```bash
ExecStart=/usr/bin/aide --check | mail -s "AIDE Report $(hostname)" admin@example.com
```

### 8. Verify AIDE is Running

```bash
# Check timer status
sudo systemctl status aide-check.timer

# List next run time
systemctl list-timers --all | grep aide
```

## Verify

### Verify AIDE Database Exists

```bash
ls -la /var/lib/aide/aide.db
```

### Verify Configuration is Valid

```bash
sudo aide --config-check
```

Expected output: `OK`

### Verify Cron Job or Timer

```bash
# For systemd timer
sudo systemctl list-timers --all | grep aide

# For cron
sudo crontab -l | grep aide
```

### Run Manual Check and Verify Output

```bash
sudo aide --check | head -20
```

If changes detected, output shows:
- File path
- Attributes that changed (permissions, checksum, etc.)
- Old and new values

## Rollback

### Restore Original File

If AIDE detects unauthorized changes to a specific file:

```bash
# Find the package that owns the file
rpm -qf /path/to/file

# Reinstall the original
sudo dnf reinstall <package-name>
```

### Restore Entire System from Backup

```bash
# Use your backup system to restore
sudo aide --init  # Reinitialize baseline AFTER restore
```

### Disable AIDE Monitoring

```bash
sudo systemctl stop aide-check.timer
sudo systemctl disable aide-check.timer
```

## Common Errors

### "Database not found"

```
Error: Unable to open database '/var/lib/aide/aide.db'
```
**Fix:** Run `sudo aide --init` to create the initial database.

### "Permission denied"

```
Cannot open '/var/log/aide/aide.log'
```
**Fix:** Ensure the log directory exists and is writable: `sudo mkdir -p /var/log/aide && sudo chmod 755 /var/log/aide`

### "Database outdated"

```
Warning: Database was created more than 90 days ago
```
**Fix:** Update the database: `sudo aide --update`

### "Regex error in config"

```
Error: Invalid regex pattern
```
**Fix:** Check `/etc/aide/aide.conf` for typos in file paths. Use full paths without wildcards unless properly formatted.

### "Out of disk space"

```
Cannot write database
```
**Fix:** Free up disk space or move database to a larger partition. Compress old logs: `sudo journalctl --vacuum-time=30d`

## References

- AIDE Official Documentation: https://aide.github.io/
- Red Hat Security Guide - File Integrity: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/security_hardening/chap-security_hardening-file_integrity
- NIST SP 800-53 Rev 5 - Configuration Management: https://csrc.nist.gov/publications/sp800/53b/sp800-53b.pdf
- AIDE Manual Page: `man aide.conf`