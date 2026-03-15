# Topics Index

## Categories

### Setup Guides
Step-by-step instructions for installing and configuring tools and environments.

Location: `docs/setup-guides/`

### How-To
Practical guides for performing specific tasks with provided tools.

Location: `docs/how-to/`

### Concepts
Deep dives into technologies, patterns, and architectural decisions.

Location: `docs/concepts/`

### Troubleshooting
Symptom → cause → fix documentation for common issues.

Location: `docs/troubleshooting/`

### Runbooks
Operational procedures for incident response and routine checks.

Location: `docs/runbooks/`

### Reference
API docs, configuration references, and quick lookup material.

Location: `docs/reference/`

## Tools

| Tool | Status | Description | Documentation |
|-------|--------|-------------|---------------|
| k8s_toolkit | DONE | Safe kubectl helpers for node operations, pod management, debugging, and reporting | [how-to/k8s_toolkit.md](how-to/k8s_toolkit.md) |
| ansible_toolkit | DONE | Ansible security audit scripts (sensitive variable exposure, CVE-2025-14010) | [how-to/ansible_toolkit.md](how-to/ansible_toolkit.md) |
| vault_toolkit | DONE | Vault security hardening scripts (CVE-2025-6000 plugin directory RCE) | [how-to/vault_toolkit.md](how-to/vault_toolkit.md) |
| oci_registry_toolkit | PLANNED | OCI container registry management (list, cleanup, auth) | — |
| ci_cd_toolkit | PLANNED | CI/CD templates for GitHub Actions/Jenkins | — |
| observability_toolkit | PLANNED | Grafana/Prometheus/OTEL patterns and dashboards | — |
| linux_toolkit | PLANNED | Linux Mint/Ubuntu setup and troubleshooting scripts | — |

## Scripts

Scripts are organized by language in `scripts/`:
- **bash/** - Shell scripts for Unix-like systems
- **python/** - Cross-platform Python utilities
- **powershell/** - Windows PowerShell scripts

Each script includes comprehensive header documentation, safety guards, and dry-run modes where applicable.

## Snippets

Copy-paste ready code organized by technology in `snippets/`. Includes:
- Configuration snippets
- Command examples
- Query patterns

## Templates

Starter files and skeletons in `templates/`:
- `project-starters/` - Boilerplate for new projects
- `docker/` - Dockerfile and compose templates
- `k8s/` - Kubernetes manifest templates
- `terraform/` - Infrastructure as Code patterns
- `docs/` - Documentation templates
