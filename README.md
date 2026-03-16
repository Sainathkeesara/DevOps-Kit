# DevOps-Kit

## What is this?

A curated collection of production-ready scripts, runbooks, and reference docs for common DevOps tools. Each entry is version-specific, scenario-grounded, and ready to adapt for real infrastructure work.

## Repository Structure

```
DevOps-Kit/
├─ 00_index/        → Navigation: topic index, quick links, glossary
├─ docs/
│  ├─ how-to/       → Step-by-step guides per tool
│  ├─ troubleshooting/ → Failure patterns and fixes
│  ├─ runbooks/     → Incident response procedures
│  └─ reference/    → Quick-reference tables and flags
├─ scripts/
│  ├─ bash/         → Shell scripts, organized by tool
│  └─ python/       → Python utilities
├─ snippets/        → Copy-paste ready one-liners and blocks
└─ templates/       → Starter configs for k8s, Terraform, Docker, etc.
```

## How to use this repo

1. **Find what you need**: Start with `00_index/quick-links.md` for the most useful resources
2. **Explore by tool**: Each tool has its own `toolkit/` directory with scripts, docs, and how-to guides
3. **Learn concepts**: Check `docs/concepts/` for deep dives into technologies
4. **Fix issues**: Look in `docs/troubleshooting/` for common problems and solutions

## Tools covered

| Tool | Scripts | Docs | Snippets | Templates |
|------|---------|------|----------|-----------|
| Kubernetes | 12 | 2 | 1 | 3 |
| Kafka | 17 | 2 | 1 | 0 |
| Jenkins | 2 | 2 | 1 | 0 |
| Linux | 6 | 1 | 1 | 0 |
| Observability | 8 | 1 | 1 | 0 |
| OCI/Registry | 5 | 1 | 1 | 0 |
| CI/CD | 5 | 1 | 1 | 0 |
| Terraform | 1 | 0 | 0 | 0 |
| Ansible | 2 | 1 | 0 | 0 |
| Vault | 3 | 1 | 0 | 0 |
| Docker | 1 | 0 | 0 | 0 |
| Helm | 2 | 0 | 0 | 0 |

## Quick links

- [Vault: CVE-2025-11621 AWS Auth bypass hardening script](scripts/bash/vault_toolkit/security/cve-2025-11621.sh)
- [Helm: CVE-2025-53547 Chart.yaml code injection hardening script](scripts/bash/helm_toolkit/security/cve-2025-53547-harden.sh)
- [Docker: CVE-2026-28400 Model Runner privilege escalation hardening script](scripts/bash/docker_toolkit/security/cve-2026-28400.sh)
- [Kafka: consumer lag troubleshooting guide](docs/troubleshooting/kafka-consumer-lag.md)
- [Kubernetes: drain node runbook](scripts/bash/k8s_toolkit/node/drain-node.sh)

## Contributing

All changes go through PR review. Scripts must include dry-run modes and safety guardrails. Documentation should follow the existing how-to and troubleshooting patterns.
