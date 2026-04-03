# Linux Configuration Management with AIDE

## Purpose

Deploy and manage AIDE (Advanced Intrusion Detection Environment) for file integrity monitoring on Linux systems. This project provides comprehensive documentation, deployment scripts, and operational procedures for implementing file integrity checking as a core security control.

## When to use

- Implementing file integrity monitoring as part of a security compliance framework (CIS, PCI-DSS, HIPAA)
- Detecting unauthorized changes to system files, configurations, and binaries
- Establishing a baseline of known-good file states for incident response
- Meeting regulatory requirements for integrity verification
- Monitoring critical configuration files for drift from established baselines
- Detecting potential compromise after a security incident

## Prerequisites

- Linux server (Ubuntu 22.04, RHEL 9, or Debian 12)
- Root or sudo access
- Minimum 100MB free disk space for AIDE database
- Network connectivity for package repositories
- cron daemon running (for scheduled checks)

## Steps

### Step 1: Install AIDE

The installation script handles package installation for supported distributions:

```bash
#!/usr/bin/env bash
# Run as root
sudo ./aide-deploy.sh --install
```

The script supports:
- Ubuntu/Debian (apt)
- RHEL/CentOS/Fedora (dnf)

Installation includes:
- AIDE package installation
- Configuration file creation
- Directory structure setup

### Step 2: Initialize the database

Before running checks, establish a known-good baseline:

```bash
sudo ./aide-deploy.sh --init
```

This creates the initial database at `/var/lib/aide/aide.db`. The database stores file signatures (MD5, SHA256, etc.) for comparison during integrity checks.

### Step 3: Configure monitoring rules

The default configuration monitors:
- `/boot` - Boot files
- `/bin`, `/sbin` - System binaries
- `/usr` - User binaries
- `/etc` - Configuration files
- `/var/log` - Log directories
- Cron directories
- SSH configuration

Custom rules can be added to `/etc/aide/aide.conf.d/`:

```bash
# Example: Add custom monitoring
echo "/opt/myapp    MD5+sha256" | sudo tee -a /etc/aide/aide.conf.d/custom.conf
```

### Step 4: Run integrity checks

Manual check execution:

```bash
sudo ./aide-deploy.sh --check
```

The check compares current file states against the database and reports:
- Added files
- Removed files
- Modified files (with specific changes)

### Step 5: Update the database

After intentional system changes, update the baseline:

```bash
sudo ./aide-deploy.sh --update
```

This creates a new database and backs up the previous version.

### Step 6: Configure automated checks

The deployment script sets up daily cron execution:

```bash
# Cron runs at 3:00 AM daily
# Logs to /var/log/aide/daily-check.log
```

To modify the schedule:

```bash
sudo crontab -e
# Change: 0 3 * * * root /etc/cron.daily/aide-run.sh
```

## Verify

### Verify AIDE installation

```bash
# Check AIDE version
aide --version

# Check configuration
aide --check --config=/etc/aide/aide.conf --verbose=0
```

### Verify database exists

```bash
ls -la /var/lib/aide/aide.db
```

### Verify cron job

```bash
sudo cat /etc/cron.d/aide
sudo ls -la /etc/cron.daily/aide-run.sh
```

### Test dry-run mode

```bash
# Preview what would happen without making changes
sudo DRY_RUN=true ./aide-deploy.sh --install
sudo DRY_RUN=true ./aide-deploy.sh --check
```

### Verify monitoring coverage

```bash
# List all monitored directories
grep "^/" /etc/aide/aide.conf | grep -v "^!"

# Check specific file monitoring
aide --check --config=/etc/aide/aide.conf --report=stdout | head -20
```

## Rollback

### Rollback database to previous version

```bash
sudo ./aide-deploy.sh --rollback
```

This restores from the most recent backup in `/var/lib/aide/aide.db.backup.*`.

### Manual rollback steps

```bash
# List available backups
ls -la /var/lib/aide/aide.db.backup.*

# Restore specific backup
sudo cp /var/lib/aide/aide.db.backup.20260315 /var/lib/aide/aide.db
```

### Remove AIDE completely

```bash
# Debian/Ubuntu
sudo apt-get remove --purge aide

# RHEL/CentOS
sudo dnf remove aide

# Remove data
sudo rm -rf /var/lib/aide
sudo rm -rf /var/log/aide
```

## Common errors

### Error: "Database not found"

**Symptom:** `aide: database not found` when running --check

**Solution:** Run initialization first:
```bash
sudo aide-deploy.sh --init
```

### Error: "Permission denied"

**Symptom:** Cannot read files during check

**Solution:** Run as root:
```bash
sudo aide-deploy.sh --check
```

### Error: "Configuration file not found"

**Symptom:** AIDE cannot find configuration

**Solution:** Install with default config:
```bash
sudo aide-deploy.sh --install
```

### Error: "Out of space"

**Symptom:** Database creation fails

**Solution:** Free disk space or exclude directories:
```bash
# Edit /etc/aide/aide.conf
# Add: !/var/log/large-directory
```

### Error: "Changes detected"

**Symptom:** AIDE reports modified files after system update

**Solution:** Update database after intentional changes:
```bash
sudo aide-deploy.sh --update
```

### Error: "Cron job not running"

**Symptom:** No daily checks occurring

**Solution:** Enable cron and verify:
```bash
sudo systemctl enable cron
sudo systemctl status cron
sudo ls -la /etc/cron.daily/aide-run.sh
```

### Error: "Database locked"

**Symptom:** Cannot run check or update

**Solution:** Check for running AIDE processes:
```bash
ps aux | grep aide
sudo pkill -9 aide
```

## References

- [AIDE Official Documentation](https://aide.github.io/) (2026-01-15)
- [AIDE GitHub Repository](https://github.com/aide/aide) (2026-02-01)
- [CIS Linux Benchmark - File Integrity](https://www.cisecurity.org/benchmark/centos_linux) (2026-01-15)
- [Red Hat AIDE Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/security_hardening/configuring-file-integrity-checking_security-hardening) (2026-01-20)
- [Ubuntu AIDE Package](https://packages.ubuntu.com/jammy/aide) (2026-01-15)
