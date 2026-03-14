# Ansible Toolkit (ansible_toolkit)

## Purpose

The ansible_toolkit provides security auditing scripts for Ansible playbooks, focusing on sensitive variable exposure vulnerabilities. These scripts help detect and remediate CVE-2025-14010 and other credential leakage issues in Ansible projects.

## When to use

Use ansible_toolkit scripts when you need to:
- Audit Ansible playbooks for sensitive variable exposure
- Check for missing `no_log` protection on sensitive tasks
- Detect hardcoded secrets in variable files
- Review environment variable security
- Identify debug tasks that may expose sensitive data

Do **not** use these in production as a security control - they are audit tools that help identify issues but do not prevent them.

## Prerequisites

- Bash 4.0 or higher
- Standard Unix tools: grep, awk, find
- Optional: ansible-playbook (for syntax validation)

## Installation

No installation required. Clone the DevOps-Kit repository:

```bash
git clone <repo> devops-kit
cd devops-kit
chmod +x scripts/bash/ansible_toolkit/security/*.sh
```

## Tools

### vault-rotate.sh

Rotates Ansible vault passwords for encrypted files. This script helps you update vault passwords securely with backup support and dry-run mode.

```bash
./scripts/bash/ansible_toolkit/vault-rotate.sh [OPTIONS]
```

**Arguments:**
- `--vault-id=<id>` - Vault ID to rotate (default: default)
- `--old-password=<pwd>` - Current vault password (or set VAULT_PASSWORD env var)
- `--new-password=<pwd>` - New vault password (or set NEW_VAULT_PASSWORD env var)
- `--encrypted-file=<file>` - Encrypted file to re-encrypt (can be specified multiple times)
- `--encrypted-dir=<dir>` - Directory containing encrypted files (recursive)
- `--backup-dir=<dir>` - Directory for backups (default: <file>.bak)
- `--dry-run` - Preview changes without applying
- `--json-output` - Output results in JSON format
- `--verbose` - Enable verbose debug output

**Examples:**

Rotate password for a single encrypted file:
```bash
./scripts/bash/ansible_toolkit/vault-rotate.sh --encrypted-file=vars/secrets.yml --old-password=oldpass --new-password=newpass
```

Rotate password for all encrypted files in a directory:
```bash
./scripts/bash/ansible_toolkit/vault-rotate.sh --encrypted-dir=./vault --old-password=oldpass --new-password=newpass
```

Preview changes without applying:
```bash
./scripts/bash/ansible_toolkit/vault-rotate.sh --encrypted-file=vars/secrets.yml --dry-run
```

Use environment variables for passwords:
```bash
VAULT_PASSWORD=oldpass NEW_VAULT_PASSWORD=newpass ./scripts/bash/ansible_toolkit/vault-rotate.sh --encrypted-file=vars/secrets.yml
```

**Safety features:**
- Creates automatic backups before modifying files
- Supports dry-run mode to preview changes
- JSON output for integration with automation
- Vault ID support for multiple vault configurations

### security/cve-2025-14010-audit.sh

Audits Ansible playbooks for sensitive variable exposure (CVE-2025-14010). This vulnerability allows credentials to be exposed when Ansible runs with verbose mode (`-v`) or when sensitive variables lack proper `no_log` protection.

```bash
./scripts/bash/ansible_toolkit/security/cve-2025-14010-audit.sh [--path=<dir>] [--dry-run] [--json-output] [--verbose]
```

**Arguments:**
- `--path=<dir>` - Path to scan (default: current directory)
- `--dry-run` - Preview findings without detailed analysis
- `--json-output` - Output results in JSON format
- `--verbose` - Enable verbose debug output

**Examples:**

Scan current directory:
```bash
./scripts/bash/ansible_toolkit/security/cve-2025-14010-audit.sh
```

Scan a specific playbook directory:
```bash
./scripts/bash/ansible_toolkit/security/cve-2025-14010-audit.sh --path=/home/user/ansible-playbooks
```

Output JSON results:
```bash
./scripts/bash/ansible_toolkit/security/cve-2025-14010-audit.sh --json-output
```

## What the audit checks

The CVE-2025-14010 audit script checks for:

1. **Verbose flag usage** - Patterns that suggest verbose mode may be enabled
2. **Missing no_log** - Tasks (shell, command, script, template, copy) without `no_log: true`
3. **Environment variable secrets** - Sensitive values in environment variables
4. **Hardcoded secrets** - Passwords, tokens, API keys in variable files
5. **Debug tasks** - Debug tasks without no_log protection
6. **Unsafe lookups** - Usage of potentially unsafe lookup plugins

## Verify

After running the audit, review the findings:

- **High severity**: Tasks without no_log, hardcoded secrets
- **Medium severity**: Verbose patterns, missing no_log on debug
- **Low severity**: Lookup plugin usage

Follow the remediation recommendations provided in the output.

## Rollback

This is a read-only audit tool. It does not modify any files. No rollback is needed.

## Common errors

| Error | Cause | Fix |
|-------|-------|-----|
| "Missing dependencies" | Required tools not installed | Install grep, awk, find |
| "Directory does not exist" | Invalid scan path | Check the path exists |
| No findings found | No issues detected | This is good! |

## References

- CVE-2025-14010 — https://nvd.nist.gov/vuln/detail/CVE-2025-14010 (verified: 2026-03-14)
- Ansible Documentation — https://docs.ansible.com/ (verified: 2026-03-14)
- Ansible Vault — https://docs.ansible.com/ansible/latest/vault_guide/index.html (verified: 2026-03-14)
- no_log attribute — https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_loops.html#preventing-sensitive-output-from-showing-in-logs (verified: 2026-03-14)
