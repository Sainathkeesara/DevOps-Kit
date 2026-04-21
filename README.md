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
| Kubernetes | 14 | 7 | 1 | 3 |
| Kafka | 17 | 3 | 2 | 0 |
| Jenkins | 2 | 5 | 4 | 1 |
| Linux | 24 | 24 | 2 | 0 |
| Observability | 8 | 1 | 1 | 0 |
| OCI/Registry | 5 | 1 | 1 | 0 |
| CI/CD | 5 | 1 | 1 | 0 |
| Terraform | 9 | 12 | 1 | 14 |
| Ansible | 7 | 3 | 1 | 0 |
| Vault | 7 | 3 | 1 | 0 |
| Docker | 4 | 2 | 1 | 0 |
| Helm | 3 | 3 | 0 | 0 |

## Quick links

- [Jenkins CLI commands reference](snippets/jenkins-cli-commands.md) — Jenkins CLI with 80+ commands (2026-04-19)
- [Ansible playbook best practices](docs/how-to/ansible-playbook-best-practices.md) — Ansible playbook guide (2026-04-19)
- [Kafka topics commands](snippets/kafka-topics-commands.md) — Kafka topics CLI one-liners (2026-04-18)
- [Jenkins commands](docs/reference/jenkins-commands.md) — Jenkins CLI 50+ commands (2026-04-18)
- [Linux commands reference](snippets/linux-commands.md) — Linux bash one-liners (2026-04-18)

## Contributing

All changes go through PR review. Scripts must include dry-run modes and safety guardrails. Documentation should follow the existing how-to and troubleshooting patterns.
