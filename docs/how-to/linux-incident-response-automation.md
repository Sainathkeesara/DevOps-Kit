# Linux Incident Response Automation with Forensic Toolkit

## Purpose

This guide describes how to use the Linux Incident Response Automation Script for collecting digital forensic evidence during security incidents. The script automates the collection of volatile and non-volatile data essential for incident investigation while maintaining chain of custody through cryptographic hashing.

## When to use

Use this automation when:

- A security incident has been detected on a Linux system
- You need to rapidly collect forensic evidence before remediation
- Performing post-mortem analysis of a compromised system
- Conducting internal security assessments requiring evidence collection
- Responding to potential data breach or unauthorized access

## Prerequisites

### Required
- Root or sudo privileges for full evidence collection
- Bash 4.0 or higher
- Sufficient disk space in output directory (minimum 10GB recommended for full forensic mode)
- Network connectivity for external storage (recommended for evidence storage)

### Optional (for full forensic mode)
- `dc3dd` - Enhanced dd for forensics: `apt install dc3dd`
- `forensic-tools` - Additional forensic utilities: `apt install forensic-tools`
- External storage device for evidence (recommended)

### Tested Operating Systems
- RHEL 7/8/9
- Ubuntu 20.04/22.04
- Debian 11/12
- CentOS Stream 8/9

## Steps

### Step 1: Prepare the evidence collection environment

Connect external storage for evidence:

```bash
# Identify external storage device
lsblk
mount /dev/sdX1 /mnt/evidence
```

Create a case identifier for chain of custody:

```bash
export CASE_ID="INC-$(date +%Y%m%d)-001"
export EXAMINER_NAME="Your Name"
```

### Step 2: Run in dry-run mode first

Always preview collection steps before execution:

```bash
sudo ./scripts/bash/linux_toolkit/security/forensics/incident-response.sh \
    --dry-run \
    --case-id "$CASE_ID" \
    --examiner "$EXAMINER_NAME"
```

Review the output to understand what will be collected.

### Step 3: Execute standard incident response collection

Run the full collection:

```bash
sudo ./scripts/bash/linux_toolkit/security/forensics/incident-response.sh \
    --output /mnt/evidence/incident-$(date +%Y%m%d-%H%M%S) \
    --case-id "$CASE_ID" \
    --examiner "$EXAMINER_NAME"
```

### Step 4: Execute full forensic mode (optional)

For complete forensic collection including memory dump:

```bash
sudo ./scripts/bash/linux_toolkit/security/forensics/incident-response.sh \
    --output /mnt/evidence/incident-$(date +%Y%m%d-%H%M%S) \
    --full-forensic \
    --case-id "$CASE_ID" \
    --examiner "$EXAMINER_NAME"
```

Note: Full forensic mode requires significant time and disk space.

### Step 5: Verify evidence integrity

After collection completes, verify hash integrity:

```bash
cd /mnt/evidence/incident-YYYYMMDD-HHMMSS
sha256sum -c hashes/manifest.sha256
```

## Verify

### Verify collection completed successfully

Check the manifest:

```bash
cat MANIFEST.txt
```

Expected output includes:
- Case ID and examiner information
- Collection timestamp
- Total files collected
- Hash algorithm used

### Verify specific artifacts collected

```bash
# Check for suspicious processes identified
cat processes/suspicious-processes.txt

# Review network connections at time of incident
cat network/ss-tunap.txt

# Check authentication logs
cat logs/last.txt
cat logs/secure 2>/dev/null || cat logs/auth.log
```

### Verify chain of custody

```bash
# Review timeline of collection events
cat timeline.txt

# Check hash manifest
head -20 hashes/manifest.sha256
```

## Rollback

This script is read-only and does not modify the system. No rollback is required.

However, if you need to stop collection mid-process:

```bash
# Press Ctrl+C to abort
# Evidence already collected will remain in output directory
# Review timeline.txt for what was completed
```

## Common errors

### "Required command not found"

**Error**: `Required command 'xxx' not found`

**Solution**: Install missing utilities:
```bash
# RHEL/CentOS
sudo yum install util-linux procps-ng lsof net-tools

# Ubuntu/Debian
sudo apt install util-linux procps lsof net-tools
```

### "Permission denied" errors

**Error**: `Permission denied` when collecting certain files

**Solution**: Run with sudo:
```bash
sudo ./incident-response.sh ...
```

Some system files require root privileges.

### "No space left on device"

**Error**: Disk full during collection

**Solution**: 
1. Free up space or use larger external storage
2. Exclude large directories with additional flags
3. Collect only specific artifacts as needed

### Memory dump fails

**Error**: `dd: /dev/mem: Operation not permitted`

**Solution**: 
- On modern systems, /dev/mem may be restricted
- Use LiME (Linux Memory Extractor) for memory acquisition:
```bash
# Install LiME
git clone https://github/504ensicsLabs/LiME.git
cd LiME/src
make
sudo insmod lime.ko "path=/tmp/memory.lime format=lime"
```

## References

- NIST SP 800-86: Guide to Integrating Forensic Techniques into Incident Response
- SANS Incident Response Process: https://www.sans.org/security-resources/incident-response/
- DFIR (Digital Forensics and Incident Response) Methodology
- The Incident Response Book: https://www.incident-response.org/
- Chain of Custody Best Practices: https://www.nist.gov/topics/cyber-security/chain-custody
- Linux Forensics Medium Articles: https://medium.com/@拆
