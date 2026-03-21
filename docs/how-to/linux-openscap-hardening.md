# Linux OpenSCAP Hardening Automation

## Purpose

Automate security compliance scanning and remediation for Linux systems using OpenSCAP. This guide covers running compliance scans against security benchmarks (STIG, CIS, PCI-DSS), generating remediation scripts, and applying fixes automatically.

## When to use

- Running scheduled compliance scans for security audits
- Hardening new Linux systems against security benchmarks
- Verifying system compliance after changes
- Generating remediation reports for manual or automated fixes
- Meeting regulatory compliance requirements (STIG, CIS, PCI-DSS)

## Prerequisites

- RHEL 8/9, CentOS Stream 8/9, Fedora 38+, or derivative
- Root or sudo privileges
- OpenSCAP scanner installed (`openscap-scanner` package)
- Internet access to download SCAP content (or pre-downloaded content)
- At least 2GB free disk space for reports

## Steps

### 1. Install OpenSCAP

```bash
# RHEL/CentOS/Fedora
sudo dnf install -y openscap-scanner

# Ubuntu/Debian
sudo apt-get install -y openscap-scanner
```

### 2. Run a Dry-Run Scan

Always preview changes before applying:

```bash
sudo ./scripts/bash/linux_toolkit/security/openscap-hardening.sh \
    --dry-run \
    --profile xccdf_org.ssgproject.content_profile_stig-rhel8-draft
```

This shows:
- Which controls pass/fail
- What changes would be made (without making them)
- Estimated scan time

### 3. Run Full Compliance Scan

Generate detailed XML and HTML reports:

```bash
sudo ./scripts/bash/linux_toolkit/security/openscap-hardening.sh \
    --profile xccdf_org.ssgproject.content_profile_stig-rhel8-draft \
    --report
```

Reports are saved to `/var/log/openscap/`:
- `scan-results-YYYYMMDD-HHMMSS.xml` - Machine-readable results
- `scan-report-YYYYMMDD-HHMMSS.html` - Human-readable report

### 4. Review Failed Controls

Check the HTML report or XML results:

```bash
# View failed controls
grep 'result="fail"' /var/log/openscap/scan-results-*.xml | head -20

# Count by severity
grep -c 'result="fail"' /var/log/openscap/scan-results-*.xml
```

### 5. Generate Remediation Script

Create a bash script with fixes for all failed controls:

```bash
# Generate (not apply) remediation script
sudo ./scripts/bash/linux_toolkit/security/openscap-hardening.sh \
    --profile xccdf_org.ssgproject.content_profile_stig-rhel8-draft
```

Output: `/var/log/openscap/remediation-script-*.sh`

### 6. Review Remediation Script

Before applying, review the generated script:

```bash
sudo less /var/log/openscap/remediation-script-*.sh

# Check specific changes
grep -E "^[^#]*=" /var/log/openscap/remediation-script-*.sh | head -30
```

### 7. Apply Remediation

When ready, apply fixes with backup:

```bash
# Auto-remediate with backup (recommended)
sudo ./scripts/bash/linux_toolkit/security/openscap-hardening.sh \
    --profile xccdf_org.ssgproject.content_profile_stig-rhel8-draft \
    --auto-remediate
```

The script:
- Creates backup in `/var/backup/openscap-YYYYMMDD-HHMMSS/`
- Applies all non-disruptive fixes
- Runs post-remediation scan to verify

### 8. Available Profiles

```bash
# List all available profiles
oscap info /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml | grep "Profile.*id:"
```

Common profiles:
| Profile ID | Description |
|---|---|
| `xccdf_org.ssgproject.content_profile_stig-rhel8-draft` | DISA STIG |
| `xccdf_org.ssgproject.content_profile_cis` | CIS Benchmarks |
| `xccdf_org.ssgproject.content_profile_ospp` | OSPP |
| `xccdf_org.ssgproject.content_profile_pci-dss` | PCI-DSS |

## Verify

### Post-Scan Verification

```bash
# Check pass/fail ratio
cd /var/log/openscap
latest_xml=$(ls -t scan-results-*.xml | head -1)
pass_count=$(grep -c 'result="pass"' "$latest_xml")
fail_count=$(grep -c 'result="fail"' "$latest_xml")
echo "Pass: $pass_count, Fail: $fail_count"

# View HTML report
xdg-open scan-report-*.html
```

### Compliance Percentage

```bash
total=$((pass_count + fail_count))
percentage=$((pass_count * 100 / total))
echo "Compliance: $percentage%"
```

Expected: > 90% for most compliance frameworks

## Rollback

If remediation causes issues:

```bash
# Find backup directory
ls -lt /var/backup/openscap-*/

# Restore from backup
sudo cp -rp /var/backup/openscap-YYYYMMDD-HHMMSS/* /

# Restore specific file
sudo cp /var/backup/openscap-YYYYMMDD-HHMMSS/etc/ssh/sshd_config /etc/ssh/sshd_config
sudo systemctl restart sshd
```

## Common Errors

### Error: "No SCAP datastream found"

**Cause**: SCAP content not installed

**Resolution**:
```bash
# RHEL/CentOS
sudo dnf install -y scap-security-guide

# Or download manually
wget https://access.redhat.com/security/data/scap/v2/RHEL8/rhel-8.8-oscap-latest.zip
```

### Error: "Permission denied"

**Cause**: Script requires root privileges

**Resolution**:
```bash
sudo ./openscap-hardening.sh --dry-run
```

### Error: "Scan timeout"

**Cause**: Large system or slow storage

**Resolution**:
```bash
# Reduce scan scope with specific profile
--profile xccdf_org.ssgproject.content_profile_cis
```

### Error: "Remediation failed"

**Cause**: Conflicting system configuration

**Resolution**:
- Review backup: `ls /var/backup/openscap-YYYYMMDD-HHMMSS/`
- Restore manually: `sudo cp /var/backup/openscap-*/etc/* /etc/`
- Report issue to security team

## References

- OpenSCAP Documentation: https://www.open-scap.org/
- DISA STIG: https://public.cyber.mil/stigs/
- CIS Benchmarks: https://www.cisecurity.org/benchmark/linux
- Red Hat SCAP: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/security_hardening
