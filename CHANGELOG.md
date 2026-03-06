# Changelog

All notable changes to the DevOps-Kit repository will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- kafka_toolkit: New operational scripts for Kafka management
  - `scripts/bash/kafka_toolkit/topics/topic-delete.sh`: Safe topic deletion with dry-run and consumer checks
  - `scripts/bash/kafka_toolkit/consumers/consumer-lag.sh`: Monitor consumer lag with threshold alerts
  - `scripts/bash/kafka_toolkit/partitions/partition-rebalance.sh`: Preferred replica election for partition leadership
  - Documentation: `docs/how-to/kafka_toolkit.md` - Added new script sections
  - Index updates: `00_index/quick-links.md` - Added Kafka section

### Changed
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
 - oci_registry_toolkit: OCI registry helper scripts
   - `scripts/bash/oci_registry_toolkit/registry/list-repos.sh`: List repositories in a registry
   - `scripts/bash/oci_registry_toolkit/registry/list-tags.sh`: List tags for a repository
   - `scripts/bash/oci_registry_toolkit/tags/find-old-tags.sh`: Find old/unused tags based on age or pattern
   - `scripts/bash/oci_registry_toolkit/tools/keepalive-pull-plan.sh`: Generate script to pull artifacts for offline/keepalive
   - `scripts/bash/oci_registry_toolkit/auth/check-auth.sh`: Diagnose registry authentication issues
 - Documentation: `docs/how-to/oci_registry_toolkit.md` - Complete usage guide
 - Snippets: `snippets/oci-registry-cheatsheet.md` - OCI registry quick reference
 - Index updates: `00_index/quick-links.md` - Added OCI/Container Registries section
- observability_toolkit: Prometheus, Grafana, Loki, Jaeger, OpenTelemetry scripts
   - `scripts/bash/observability_toolkit/prometheus/targets-status.sh`: Check Prometheus scrape targets health
   - `scripts/bash/observability_toolkit/prometheus/check-alert.sh`: Monitor Prometheus alerts
   - `scripts/bash/observability_toolkit/prometheus/query-metrics.sh`: Execute PromQL queries
   - `scripts/bash/observability_toolkit/loki/query-logs.sh`: Query Loki logs with LogQL
   - `scripts/bash/observability_toolkit/grafana/health-check.sh`: Check Grafana health and datasources
   - `scripts/bash/observability_toolkit/jaeger/query-traces.sh`: Query Jaeger distributed traces
   - `scripts/bash/observability_toolkit/otel/collector-health.sh`: Check OTel collector status
   - `scripts/bash/observability_toolkit/stack-health.sh`: Check all observability stack components
- Documentation: `docs/how-to/observability_toolkit.md` - Complete usage guide
- Snippets: `snippets/observability-cheatsheet.md` - PromQL, LogQL, alerting rules, Helm commands
- Index updates: `00_index/quick-links.md` - Added Observability section
- linux_toolkit: Linux system administration scripts
  - `scripts/bash/linux_toolkit/system/health-check.sh`: Comprehensive system health monitoring
  - `scripts/bash/linux_toolkit/system/disk-usage.sh`: Disk usage analysis and large file finder
  - `scripts/bash/linux_toolkit/service/manage-services.sh`: Systemd service management
  - `scripts/bash/linux_toolkit/network/net-diag.sh`: Network diagnostics and port checking
  - `scripts/bash/linux_toolkit/process/process-manager.sh`: Process management and monitoring
  - `scripts/bash/linux_toolkit/security/security-check.sh`: Security audit and login analysis
- Documentation: `docs/how-to/linux_toolkit.md` - Complete usage guide
- Snippets: `snippets/linux-cheatsheet.md` - Linux commands quick reference
- Index updates: `00_index/quick-links.md` - Added Linux Administration section

### Changed
- N/A (initial release)

### Deprecated
- N/A

### Fixed
- N/A

### Security
- N/A

- ci_cd_toolkit: CI/CD pipeline helpers for GitHub Actions
  - `scripts/bash/ci_cd_toolkit/github/lint-workflows.sh`: Validate workflows using actionlint
  - `scripts/bash/ci_cd_toolkit/github/validate-workflow.sh`: Syntax and structure validation
  - `scripts/bash/ci_cd_toolkit/github/pipeline-health.sh`: Check workflow run status and health
  - `scripts/bash/ci_cd_toolkit/github/check-action-updates.sh`: Detect outdated GitHub Actions
  - `scripts/bash/ci_cd_toolkit/github/generate-workflow.sh`: Generate starter workflow files
- Documentation: `docs/how-to/ci_cd_toolkit.md` - Complete usage guide
- Snippets: `snippets/ci-cd-cheatsheet.md` - CI/CD quick reference

### Completed
- oci_registry_toolkit: Implementation complete, all scripts include dry-run modes, safety notes, and follow established standards.
- ci_cd_toolkit: Implementation complete with GitHub Actions helpers for linting, validation, health checks, and workflow generation.
- observability_toolkit: Implementation complete with Prometheus, Grafana, Loki, Jaeger, and OTel collector scripts. Includes PromQL and LogQL snippets, alerting rules, and Docker Compose examples.
- linux_toolkit: Implementation complete with system health monitoring, disk analysis, service management, network diagnostics, process management, and security audit scripts.

## [2026-03-02] - Initial Bootstrap

Repository structure created with essential files and first tool implementation (k8s_toolkit). All mandatory components in place: index system, changelog, documentation standards, script templates, and PR automation.
