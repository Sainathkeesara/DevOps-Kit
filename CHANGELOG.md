# Changelog

All notable changes to the DevOps-Kit repository will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- Initial repository bootstrap with complete directory structure
- k8s_toolkit: Safe kubectl helper scripts for common operations
  - `scripts/bash/k8s_toolkit/node/drain-node.sh`: Safely drain a Kubernetes node
  - `scripts/bash/k8s_toolkit/node/rollout-status.sh`: Monitor deployment rollout status
  - `scripts/bash/k8s_toolkit/pod/restart-pod.sh`: Restart a pod with graceful termination
  - `scripts/bash/k8s_toolkit/pod/pod-logs.sh`: Stream pod logs with options
  - `scripts/bash/k8s_toolkit/debug/debug-pod.sh`: Interactive pod debugging
  - `scripts/bash/k8s_toolkit/report/namespace-report.sh`: Generate namespace resource report
- Documentation: `docs/how-to/k8s_toolkit.md` - Complete usage guide
- Snippets: `snippets/kubectl-cheatsheet.md` - Quick kubectl reference
- Template updates: `templates/k8s/deployment-monitor.sh`
- Bootstrap files: README, CHANGELOG, index files, PR template, CODEOWNERS

### Changed
- N/A (initial release)

### Deprecated
- N/A

### Fixed
- N/A

### Security
- N/A

## [2026-03-02] - Initial Bootstrap

Repository structure created with essential files and first tool implementation (k8s_toolkit). All mandatory components in place: index system, changelog, documentation standards, script templates, and PR automation.
