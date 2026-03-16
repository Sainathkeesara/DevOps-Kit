# Ansible Toolkit (ansible_toolkit)

## Purpose

The ansible_toolkit provides security auditing scripts for Ansible playbooks, focusing on sensitive variable exposure vulnerabilities. These scripts help detect and remediate CVE-2025-14010, CVE-2026-0598, and other credential leakage issues in Ansible projects.

## When to use

Use ansible_toolkit scripts when you need to:
- Audit Ansible playbooks for sensitive variable exposure
- Check Ansible Automation Platform for CVE-2026-0598
- Check for missing `no_log` protection on sensitive tasks
- Detect hardcoded secrets in variable files
- Review environment variable security
- Identify debug tasks that may expose sensitive data

Do **not** use these in production as a security control - they are audit tools that help identify issues but do not prevent them.

## Prerequisites

- Bash 4.0 or higher
- Standard Unix tools: grep, awk, find
- Optional: ansible-playbook (for syntax validation)
- For CVE-2026-0598: curl, jq, AAP API access

## Installation

No installation required. Clone the DevOps-Kit repository:

```bash
git clone <repo> devops-kit
cd devops-kit
chmod +x scripts/bash/ansible_toolkit/security/*.sh
```

## Tools

### security/cve-2026-0598-audit.sh

Audits Ansible Automation Platform for CVE-2026-0598, an authentication bypass vulnerability in the Lightspeed API conversation endpoints. The vulnerability allows authenticated attackers to access conversations owned by other users.

```bash
./scripts/bash/ansible_toolkit/security/cve-2026-0598-audit.sh [--host=<aap_host>] [--token=<api_token>] [--dry-run] [--json-output] [--verbose]
```

**Arguments:**
- `--host=<aap_host>` - Ansible Automation Platform hostname
- `--user=<username>` - AAP username (default: admin)
- `--token=<api_token>` - AAP API token (or set AAP_TOKEN env var)
- `--output=<file>` - Save results to file
- `--dry-run` - Preview findings without API calls
- `--json-output` - Output results in JSON format
- `--verbose` - Enable verbose debug output

**Examples:**

Basic scan:
```bash
./scripts/bash/ansible_toolkit/security/cve-2026-0598-audit.sh --host=aap.example.com --token=your_token
```

With JSON output:
```bash
./scripts/bash/ansible_toolkit/security/cve-2026-0598-audit.sh --host=aap.example.com --token=your_token --json-output
```

**What CVE-2026-0598 checks:**
1. AAP version verification (must be patched)
2. Lightspeed service status and configuration
3. User conversation access audit logs
4. API endpoint vulnerability patterns
5. User permissions and roles

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

- CVE-2026-0598 — https://nvd.nist.gov/vuln/detail/CVE-2026-0598 (verified: 2026-03-16)
- CVE-2025-14010 — https://nvd.nist.gov/vuln/detail/CVE-2025-14010 (verified: 2026-03-14)
- Ansible Documentation — https://docs.ansible.com/ (verified: 2026-03-14)
- Ansible Vault — https://docs.ansible.com/ansible/latest/vault_guide/index.html (verified: 2026-03-14)
- no_log attribute — https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_loops.html#preventing-sensitive-output-from-showing-in-logs (verified: 2026-03-14)
