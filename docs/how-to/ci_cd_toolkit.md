# ci_cd_toolkit

## Purpose

CLI helpers for CI/CD pipeline management, GitHub Actions workflow validation, and action maintenance. Provides linting, health checks, and generation tools for GitHub Actions workflows.

## When to use

- Validating workflow syntax before committing
- Checking for outdated GitHub Actions
- Monitoring pipeline health across repositories
- Generating starter workflow templates
- Debugging CI/CD failures

## Prerequisites

- Bash 4.0+
- yq (YAML processor): https://github.com/mikefarah/yq
- jq (JSON processor)
- gh CLI (for pipeline health): https://cli.github.com/
- actionlint (for workflow linting): https://github.com/rhysd/actionlint

## Scripts

### lint-workflows.sh

Validate GitHub Actions workflow files using actionlint.

```bash
# Lint all workflows
./scripts/bash/ci_cd_toolkit/github/lint-workflows.sh

# Strict mode (exit on warnings)
./scripts/bash/ci_cd_toolkit/github/lint-workflows.sh --strict

# Ignore patterns
./scripts/bash/ci_cd_toolkit/github/lint-workflows.sh -i "test*" -i "*.bak.yml"

# Custom workflow directory
./scripts/bash/ci_cd_toolkit/github/lint-workflows.sh ./ci/workflows
```

Install actionlint:
```bash
# macOS
brew install actionlint

# Linux
curl -sL https://github.com/rhysd/actionlint/releases/latest/download/actionlint_$(uname -s)_$(uname -m).tar.gz | tar xz -C /tmp
sudo mv /tmp/actionlint /usr/local/bin/
```

### validate-workflow.sh

Syntax and structure validation without external tools (beyond yq).

```bash
# Basic validation
./scripts/bash/ci_cd_toolkit/github/validate-workflow.sh .github/workflows/ci.yml

# With schema check
./scripts/bash/ci_cd_toolkit/github/validate-workflow.sh deploy.yml -s

# Verbose output
./scripts/bash/ci_cd_toolkit/github/validate-workflow.sh ci.yml -v
```

Checks performed:
- YAML syntax validity
- Required keys (on, jobs)
- Job dependencies exist
- Action references have version tags
- Secret usage patterns

### pipeline-health.sh

Check recent workflow runs and status.

```bash
# Check current repo
./scripts/bash/ci_cd_toolkit/github/pipeline-health.sh

# Check specific repo
./scripts/bash/ci_cd_toolkit/github/pipeline-health.sh -r myorg/myrepo

# Include runner status
./scripts/bash/ci_cd_toolkit/github/pipeline-health.sh -r myorg/myrepo --check-runners

# Filter by workflow
./scripts/bash/ci_cd_toolkit/github/pipeline-health.sh -r myorg/myrepo -w "CI" -l 5
```

### check-action-updates.sh

Detect outdated GitHub Actions in workflows.

```bash
# Dry-run check (default)
./scripts/bash/ci_cd_toolkit/github/check-action-updates.sh

# Check custom directory
./scripts/bash/ci_cd_toolkit/github/check-action-updates.sh -d ./ci

# Auto-update patch versions
./scripts/bash/ci_cd_toolkit/github/check-action-updates.sh --auto-patch --execute
```

### generate-workflow.sh

Generate starter workflow files.

```bash
# CI workflow for Node.js
./scripts/bash/ci_cd_toolkit/github/generate-workflow.sh -t ci -p node -o .github/workflows/ci.yml

# Deployment workflow
./scripts/bash/ci_cd_toolkit/github/generate-workflow.sh -t deploy -o .github/workflows/deploy.yml

# Release workflow
./scripts/bash/ci_cd_toolkit/github/generate-workflow.sh -t release -o .github/workflows/release.yml

# PR checks
./scripts/bash/ci_cd_toolkit/github/generate-workflow.sh -t pr -o .github/workflows/pr.yml

# Force overwrite
./scripts/bash/ci_cd_toolkit/github/generate-workflow.sh -t ci -p python -o ci.yml -f
```

## Verify

Install prerequisites:
```bash
# macOS
brew install yq jq gh actionlint

# Verify installations
yq --version
jq --version
gh --version
actionlint --version
```

Make scripts executable:
```bash
chmod +x scripts/bash/ci_cd_toolkit/github/*.sh
```

Test with sample workflow:
```bash
# Create test directory
mkdir -p .github/workflows

# Generate a test workflow
./scripts/bash/ci_cd_toolkit/github/generate-workflow.sh -t ci -p node -o .github/workflows/test.yml

# Validate it
./scripts/bash/ci_cd_toolkit/github/validate-workflow.sh .github/workflows/test.yml

# Lint it
./scripts/bash/ci_cd_toolkit/github/lint-workflows.sh
```

## Rollback

If workflow updates break:

```bash
# Restore from backup (check-action-updates.sh creates .bak files)
cp .github/workflows/ci.yml.bak.* .github/workflows/ci.yml

# Or revert with git
git checkout .github/workflows/ci.yml
```

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `yq not found` | Missing yq binary | `brew install yq` or download from GitHub |
| `actionlint not found` | Missing actionlint | Install from https://github.com/rhysd/actionlint |
| `gh auth required` | GitHub CLI not logged in | Run `gh auth login` |
| `No workflow files` | Wrong directory path | Verify `.github/workflows` exists |
| `YAML syntax error` | Invalid YAML structure | Check indentation and special characters |
| `Missing 'on' trigger` | Workflow missing trigger | Add `on: push:` or similar |
| `Job needs unknown job` | Dependency not defined | Ensure all `needs:` jobs exist |

## References

- https://docs.github.com/en/actions
- https://github.com/rhysd/actionlint
- https://cli.github.com/manual/
- https://github.com/mikefarah/yq
