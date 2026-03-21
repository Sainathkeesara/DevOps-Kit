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
| Kubernetes | 12 | 7 | 1 | 3 |
| Kafka | 17 | 3 | 1 | 0 |
| Jenkins | 2 | 3 | 3 | 0 |
| Linux | 6 | 2 | 1 | 0 |
| Observability | 8 | 1 | 1 | 0 |
| OCI/Registry | 5 | 1 | 1 | 0 |
| CI/CD | 5 | 1 | 1 | 0 |
| Terraform | 1 | 0 | 0 | 0 |
| Ansible | 6 | 2 | 0 | 0 |
| Vault | 5 | 3 | 0 | 0 |
| Docker | 2 | 2 | 0 | 0 |
| Helm | 3 | 2 | 0 | 0 |

## Quick links

- [Helm + Terraform Full-Stack](docs/how-to/helm-terraform-fullstack/README.md)
- [Helm + Terraform Deploy Script](scripts/bash/helm_toolkit/helm-terraform/deploy-helm-terraform.sh)
- [Docker: Security best practices guide](docs/how-to/docker-security.md)
- [Jenkins: Commands reference](docs/reference/jenkins-commands.md)
- [Jenkins: Pipeline Groovy snippets](snippets/jenkins-scripted-pipeline-groovy.md)

## Contributing

All changes go through PR review. Scripts must include dry-run modes and safety guardrails. Documentation should follow the existing how-to and troubleshooting patterns.
