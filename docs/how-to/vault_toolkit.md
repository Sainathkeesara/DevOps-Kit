# vault_toolkit

Security hardening and operational scripts for HashiCorp Vault.

## Purpose

Provide security scanning and hardening scripts to detect and remediate vulnerabilities in HashiCorp Vault deployments.

## Scripts

| Script | Description |
|--------|-------------|
| `security/cve-2025-6000.sh` | Detect and remediate CVE-2025-6000 (Vault plugin directory RCE) |
| `security/cve-2025-5999.sh` | Detect and remediate CVE-2025-5999 (Vault privilege escalation to root) |

## Documentation

| Document | Description |
|----------|-------------|
| `vault-secure-deployment.md` | Comprehensive security hardening guide for Vault production deployments |

## Requirements

- `vault` CLI (installed and configured)
- `jq` for JSON processing
- Bash 4+

## Usage

### CVE-2025-6000: Plugin Directory RCE

```bash
# Basic scan
./scripts/bash/vault_toolkit/security/cve-2025-6000.sh

# Dry-run mode (preview without changes)
./scripts/bash/vault_toolkit/security/cve-2025-6000.sh --dry-run

# JSON output
./scripts/bash/vault_toolkit/security/cve-2025-6000.sh --json-output

# Apply remediation
./scripts/bash/vault_toolkit/security/cve-2025-6000.sh --remediate

# Preview remediation
./scripts/bash/vault_toolkit/security/cve-2025-6000.sh --remediate --dry-run
```

### CVE-2025-5999: Privilege Escalation to Root

```bash
# Basic scan
./scripts/bash/vault_toolkit/security/cve-2025-5999.sh

# Dry-run mode (preview without changes)
./scripts/bash/vault_toolkit/security/cve-2025-5999.sh --dry-run

# JSON output
./scripts/bash/vault_toolkit/security/cve-2025-5999.sh --json-output

# Apply remediation
./scripts/bash/vault_toolkit/security/cve-2025-5999.sh --remediate

# Preview remediation
./scripts/bash/vault_toolkit/security/cve-2025-5999.sh --remediate --dry-run
```

## References

- [CVE-2025-6000 - SentinelOne](https://www.sentinelone.com/vulnerability-database/cve-2025-6000/)
- [CVE-2025-5999 - Tenable](https://www.tenable.com/cve/CVE-2025-5999)
- [HashiCorp Vault Documentation](https://developer.hashicorp.com/vault/docs)
