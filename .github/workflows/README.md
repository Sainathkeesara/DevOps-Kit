# GitHub Actions Workflows

This directory contains GitHub Actions workflow definitions for the DevOps-Kit repository.

## Workflows

- **pr-validation.yml** - Runs linting and type checking on PRs
- **auto-merge.yml** - Automated merging for trivial changes (docs, typos)
- **tool-testing.yml** - Executes script tests in isolated environments

## Standards

- All workflows must specify `permissions: read-all`
- Use reusable composite actions from `.github/actions/` when possible
- Jobs should be atomic and independent
- Always include `continue-on-error: false` for critical jobs

## Branch Protection

Protected branches:
- `master` - Requires PR reviews, status checks, linear history
- `staging` - Requires PR reviews, allows force-push from maintainers

## CODEOWNERS

See `CODEOWNERS` file for ownership definitions.
