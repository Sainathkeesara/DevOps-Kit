# Automated Backup Solution with Rsync and Retention Policy

## Purpose

This guide describes how to implement an automated backup solution using rsync with configurable retention policies. The solution supports local and remote backups, provides incremental backup capabilities through hard links, and includes automatic cleanup of old backups based on retention settings.

## When to Use

Use this backup solution when you need to:

- Create reliable file-level backups of Linux systems
- Implement incremental backups that save disk space through hard linking
- Automate retention policy enforcement (automatically delete backups older than N days)
- Back up to local storage, NFS mounts, or remote systems via SSH
- Add encryption for sensitive data at rest

## Prerequisites

### Required Tools
- **rsync** (version 3.2.x or higher) — install via `apt-get install rsync` or `yum install rsync`
- **find** (GNU findutils) — usually pre-installed on Linux systems
- **bash** (version 4.0+) — for shell script features

### Optional Tools
- **GPG** — for encryption (`apt-get install gnupg`)
- **SSH** — for remote backups via `user@host:/path`
- **mailx/sendmail** — for email notifications

### Permissions
- Read access to source directories
- Write access to destination directory
- Execute permission on the backup script

## Steps

### Step 1: Obtain the Backup Script

The backup script is located at:
```
/DevOps-Kit/scripts/bash/linux_toolkit/backup/backup-rsync-retention.sh
```

Copy it to your preferred location:
```bash
cp /DevOps-Kit/scripts/bash/linux_toolkit/backup/backup-rsync-retention.sh /usr/local/bin/backup.sh
chmod +x /usr/local/bin/backup.sh
```

### Step 2: Run a Dry-Run (Recommended First Step)

Always start with a dry-run to understand what will be copied:
```bash
backup.sh --source /data --destination /backup
```

The output shows:
- Files that would be transferred
- Files that would be deleted
- Total data that would be copied
- No changes are made to the filesystem

### Step 3: Execute Your First Backup

When satisfied with the dry-run output, execute the actual backup:
```bash
backup.sh --source /data --destination /backup --run
```

This creates a timestamped backup directory:
```
/backup/backup-data-2026-03-23_111919/
```

### Step 4: Configure Retention Policy

By default, backups are kept for 30 days. To adjust:
```bash
# Keep backups for 7 days
backup.sh --source /home --destination /backup --retention-days 7 --run

# Keep backups for 90 days
backup.sh --source /data --destination /backup --retention-days 90 --run
```

### Step 5: Set Up Automated Scheduling

Add to cron for daily backups at 2 AM:
```bash
crontab -e

# Add this line:
0 2 * * * /usr/local/bin/backup.sh --source /data --destination /backup --run --log /var/log/backup.log
```

### Step 6: Configure Remote Backup (Optional)

For remote backups via SSH:
```bash
backup.sh --source /data --destination user@backup-server:/mnt/backups --run
```

Ensure SSH key-based authentication is configured:
```bash
ssh-copy-id user@backup-server
```

### Step 7: Enable Encryption (Optional)

For sensitive data, enable GPG encryption:
```bash
backup.sh --source /data --destination /backup --encrypt --run
```

**Note:** You must have GPG keys set up. First-time setup:
```bash
gpg --gen-key  # Follow prompts
gpg --list-keys  # Note your key ID
```

### Step 8: Exclude Specific Files/Directories

Create an exclude file:
```bash
cat > /etc/backup-excludes.txt << EOF
*.tmp
*.temp
.cache
.git/objects
node_modules/
EOF
```

Use it in backup:
```bash
backup.sh --source /data --destination /backup --exclude-file /etc/backup-excludes.txt --run
```

## Verify

### Verify Backup Completion

Check that backup completed successfully:
```bash
# List all backups
ls -la /backup/

# Check manifest log
cat /backup/.backup-manifest.log

# Verify file count
find /backup/backup-* -type f | wc -l
```

### Verify Dry-Run vs Actual

Dry-run output:
```
...
backup-data-2026-03-23_111919/
sent 1,234 bytes received 56 bytes 2,580.00 bytes/sec
total size is 123,456 speedup is 98.76
```

Actual run output:
```
...
backup-data-2026-03-23_111919/
Number of regular files: 1,234
Total file size: 123,456 MB
```

### Test Retention Policy

To test retention without waiting:
```bash
# Create a test old backup
mkdir -p /backup/backup-test-2020-01-01

# Run with 0 day retention
backup.sh --source /data --destination /backup --retention-days 0 --run

# Verify old backup was removed
ls /backup/
```

## Rollback

### Restore from Backup

To restore a specific backup:
```bash
# Restore entire backup
rsync -a /backup/backup-data-2026-03-23_111919/ /data-restore/

# Restore specific file
cp /backup/backup-data-2026-03-23_111919/path/to/file /original/location/
```

### Recover from Failed Backup

If backup fails:
1. Check log file: `/backup/.rsync-log` or your specified log
2. Verify source is accessible: `ls -la $SOURCE`
3. Verify destination has space: `df -h $DESTINATION`
4. Re-run with verbose: `backup.sh --source /data --destination /backup --verbose --run`

### Remove Broken Backup

If a backup is corrupted:
```bash
rm -rf /backup/backup-data-2026-03-23_111919
```

## Common Errors

### Error: "rsync not found"
**Solution:** Install rsync:
```bash
# Debian/Ubuntu
apt-get install rsync

# RHEL/CentOS
yum install rsync
```

### Error: "Permission denied" on destination
**Solution:** Check destination permissions:
```bash
ls -la /backup/
chown $(whoami):$(whoami) /backup/
chmod 755 /backup/
```

### Error: "No space left on device"
**Solution:** Free up space or use larger destination:
```bash
df -h /backup/
# Or use remote destination
backup.sh --source /data --destination user@server:/backups --run
```

### Error: "SSH connection failed" (remote backups)
**Solution:** Verify SSH key authentication:
```bash
ssh -v user@backup-server
# Fix SSH issues before using remote backup
```

### Error: "GPG encryption failed"
**Solution:** Verify GPG setup:
```bash
gpg --list-keys
# If no keys, generate: gpg --gen-key
```

### Warning: "Remote retention not fully implemented"
**Explanation:** When using remote SSH destinations, the retention policy cleanup cannot run automatically. Manually clean old remote backups periodically:
```bash
ssh user@backup-server "find /mnt/backups -maxdepth 1 -type d -name 'backup-*' -mtime +30 -exec rm -rf {} +"
```

### Warning: "Dry-run mode is default"
**Explanation:** This is intentional safety behavior. Always run with `--run` to actually execute the backup after verifying with dry-run output.

## References

- [Rsync Manual](https://rsync.samba.org/documentation.html)
- [GNU Findutils](https://www.gnu.org/software/findutils/)
- [Hard Links for Backups](https://rsync.samba.org/FAQ.html#3)
- [GPG Documentation](https://gnupg.org/documentation/)

## Additional Options

### Incremental Backup Explanation

The script uses rsync's hard-linking feature (`-H` flag). This means:
- First backup: copies all files
- Subsequent backups: only copies changed files
- Unchanged files are hard-linked, saving disk space
- Each backup appears as a complete snapshot

### Monitoring

Add health check to monitoring:
```bash
# Check last backup age
find /backup -maxdepth 1 -type d -name "backup-*" -mtime +1 -print

# If output is not empty, backup is stale
```

### Backup Verification

Add periodic restore test:
```bash
# Test restore to temp location
rsync -avn /backup/backup-*/ /tmp/backup-test/ | head -20
```