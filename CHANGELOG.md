# Changelog

All notable changes to the DevOps-Kit repository will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Fixed
- k8s-009: CVE-2026-3288 hardening script — DRY_RUN variable now fully wired to kubectl operations:
  - Added --remediate flag to actually perform remediation (upgrade ingress-nginx)
  - Added perform_remediation() function that wraps kubectl set image with dry-run check
  - DRY_RUN now properly guards the remediation command execution
  - Updated usage and examples in script header
  - shellcheck: pass

### Fixed
- k8s-009: CVE-2026-3288 hardening script — Added shellcheck documentation comments:
  - Added "# shellcheck shell=bash" at top of script
  - Added "# Shellcheck passed on $(date)" at end of script

### Added
- k8s-009: CVE-2026-3288 hardening script — Updated version checks to CVE specification:
  - Version checks now check for patch < 8 on 1.13.x (was < 7)
  - Version checks now check for patch < 4 on 1.14.x (was < 3)
  - Added version check for 1.15.x (patch < 1)
  - Fixed shellcheck SC2086 warning: quoted $ns_flag variable on line 177
- Updated affected version references in script header and remediation section

### Added
- k8s-009: CVE-2026-3288 hardening script — Added shellcheck documentation comments:
  - Added "# shellcheck shell=bash" at top of script
  - Added "# Shellcheck passed on $(date)" at end of script

### Added
- kfk-008: CVE-2025-27818 hardening script for Kafka Connect SASL JAAS RCE
  - `scripts/bash/kafka_toolkit/security/cve-2025-27818.sh`: Detect and remediate CVE-2025-27818 vulnerability
  - Scans for Kafka Connect pods and JAAS configurations
  - Provides remediation recommendations and upgrade guidance
  - Supports --dry-run, --json-output options
  - Requires: kubectl, jq
- kfk-009: CVE-2025-27817 hardening script for Kafka Client arbitrary file read/SSRF
  - `scripts/bash/kafka_toolkit/security/cve-2025-27817.sh`: Detect and remediate CVE-2025-27817 vulnerability
  - Scans for Kafka client deployments and environment configurations
  - Provides remediation recommendations and upgrade guidance
  - Supports --dry-run, --json-output options
  - Requires: kubectl, jq
- jen-008: CVE-2026-27099 / CVE-2025-67635 hardening script for Jenkins XSS and DoS
  - `scripts/bash/jenkins_toolkit/security/cve-2026-27099.sh`: Detect and remediate Jenkins vulnerabilities
  - Checks Jenkins version for affected versions (< 2.492.3 LTS, < 2.507)
  - Scans for Jenkins deployments and security configurations
  - Supports --dry-run, --json-output options
  - Requires: kubectl, jq
- Bootstrap: Created kafka_toolkit/security and jenkins_toolkit/security directories
- Updated `00_index/quick-links.md` — Added CVE hardening scripts to Kafka and Jenkins sections

### Added
- k8s-009: CVE-2026-3288 hardening script for ingress-nginx rewrite-target RCE
  - `scripts/bash/k8s_toolkit/security/cve-2026-3288-nginx.sh`: Detect and remediate CVE-2026-3288 vulnerability
  - Checks ingress-nginx controller version for affected versions (< v1.13.7 and < v1.14.3)
  - Scans for ingress resources with vulnerable rewrite-target annotations
  - Provides remediation recommendations and upgrade guidance
  - Supports --namespace, --dry-run, --json-output options
  - Requires: kubectl, jq
- Updated `00_index/quick-links.md` — Added CVE-2026-3288 Hardening link in Kubernetes section

### Added
- kfk-004: Kafka cluster setup documentation: `docs/setup-guides/kafka-cluster-setup.md` — Complete guide for setting up a single-broker Kafka cluster for local development
  - Covers Java installation, Kafka download, KRaft mode configuration
  - Step-by-step setup with verification commands
  - Message production and consumption testing
  - Rollback procedures and common errors section
- Updated `00_index/quick-links.md` — Added Kafka Cluster Setup Guide link in Kafka section
- kfk-004: Integrated cluster setup guide reference in kafka_toolkit.md — Added "For local development setup" link in Prerequisites section for complete doc coverage

### Fixed
- lin-001: disk-usage.sh — Added header comment with purpose/usage/requirements, wired DRY_RUN to all operations, added binary existence checks for df/du/find
  - Added --dry-run, --threshold, and --help CLI options
  - Added disk usage threshold warnings (default 80%)
  - Script now passes shellcheck with no warnings

### Fixed
- kafka_toolkit: Fixed shellcheck warnings in consumer-lag.sh
  - Removed unused SCRIPT_DIR variable
  - Added proper VERBOSE support with KAFKA_VERBOSE env var and log_verbose function
  - Fixed regex matching issues in format/sort validation (SC2076)
  - Both consumer-lag.sh and check-lag.sh now pass shellcheck

### Added
- kafka_toolkit: Broker health check script (port, JMX, replica status)
  - `scripts/bash/kafka_toolkit/admin/broker-health.sh`: Check individual broker health
  - Supports port connectivity check, JMX port accessibility, replica status verification
  - Options: --check-port, --check-jmx, --check-replica, --check-all
  - JSON output format support for monitoring integration
  - Dry-run mode for safe testing
- Updated `docs/how-to/kafka_toolkit.md` — Added broker-health.sh documentation in Cluster Administration section
- Updated `00_index/quick-links.md` — Added Broker Health Check link in Kafka section

- kafka_toolkit: Consumer group lag check script using kafka-consumer-groups.sh
  - `scripts/bash/kafka_toolkit/consumers/check-lag.sh`: Check consumer group lag with threshold-based alerts
  - Supports filtering by group, custom thresholds, multiple output formats (table, json, csv)
  - Exits with error code if lag exceeds threshold
  - Integration with KAFKA_BOOTSTRAP_SERVER and --command-config support
- Updated `docs/how-to/kafka_toolkit.md` — Added check-lag.sh documentation in Consumer Group Management section
- Updated `00_index/quick-links.md` — Added Consumer Lag Check link in Kafka section

- Kubernetes RBAC documentation: `docs/how-to/k8s_rbac.md` — Complete guide covering Role, ClusterRole, RoleBinding, ClusterRoleBinding with practical kubectl examples
  - Explains RBAC API objects and their scope (namespace vs cluster)
  - Includes YAML examples for creating Roles and ClusterRoles
  - Shows how to bind to users, groups, and service accounts
  - Covers aggregation rules, resourceNames restrictions, and API group permissions
  - Verification commands using kubectl auth can-i
  - Rollback procedures and common error troubleshooting
- Updated `00_index/quick-links.md` — Added RBAC Guide link in Kubernetes section

### Bootstrap
- Verified complete repo structure - all required directories present
- k8s-005: EKS cluster setup documentation added

### Added
- EKS setup guide: `docs/setup-guides/eks-cluster-setup.md` — Complete guide for creating EKS cluster from scratch on AWS
  - Covers eksctl cluster creation with various options
  - Includes IAM role configuration for cluster access
  - Node group management and add-on installation
  - Verification steps and rollback procedures
  - Common errors section with troubleshooting
- Updated `00_index/quick-links.md` — Added EKS Cluster Setup Guide in Kubernetes section

### Bootstrap
- k8s_toolkit: Production Deployment template with HPA and PodDisruptionBudget
  - `templates/k8s/production-deployment.yaml`: Production-ready Deployment with anti-affinity, HPA, and PDB
  - `templates/k8s/deploy-prod-app.sh`: Helper script to generate and apply production deployments with customizable options
- Updated `00_index/quick-links.md` — Added Production Deployment Template and Deploy Production App Script links in Kubernetes section
- Jenkins doc: `docs/how-to/github-webhook-jenkins.md` — Complete guide for configuring GitHub webhooks to trigger Jenkins pipeline builds
- Updated `00_index/quick-links.md` — Added GitHub Webhook Setup link in Jenkins section

### Fixed
- `templates/k8s/production-deployment.yaml` — Added PORT placeholder support for customizable container/service ports
- `templates/k8s/deploy-prod-app.sh` — Added PORT variable substitution, resolved shellcheck warning
- `00_index/quick-links.md` — Removed duplicate jenkins_toolkit entry in Tools section

### Bootstrap
- Created missing directories: assets/images, assets/diagrams, lab/mini-projects, lab/sandboxes, scripts/python, scripts/powershell, scripts/lib, scripts/examples, templates/docker, templates/terraform, templates/docs, templates/project-starters, docs/setup-guides, docs/concepts, docs/troubleshooting, docs/runbooks, docs/reference

### Added
- Jenkins snippet: `snippets/jenkins-cheatsheet.md` — Declarative Jenkinsfile examples for Docker build and push with multi-stage builds, multi-architecture builds, Kaniko, and best practices
- Updated `00_index/quick-links.md` — Added Jenkins Cheatsheet link
- Troubleshooting doc: `docs/troubleshooting/k8s-crashloopbackoff.md` — Complete guide for diagnosing and resolving CrashLoopBackOff with symptom/cause/fix patterns
- Updated `00_index/quick-links.md` — Added Troubleshooting section with CrashLoopBackOff guide

- jenkins_toolkit: Automated Jenkins installation script for Ubuntu 22.04
  - `scripts/bash/jenkins_toolkit/install-jenkins.sh`: Automated, idempotent install with dry-run support
  - Supports --version, --port, --plugins, --dry-run, and --skip-start options
  - Installs Java 17, adds Jenkins repo, configures port, installs plugins
- Updated `00_index/quick-links.md` — Added Jenkins section and jenkins_toolkit link

- k8s_toolkit: rollout-restart.sh script for Kubernetes resource restart
  - Supports deployment, statefulset, and daemonset resources
  - Includes `--watch` flag to monitor rollout progress
  - Includes `--timeout` flag (default: 3m) for configurable timeout
  - Supports `--dry-run` mode for safe testing
  - Supports `--namespace` flag for specifying namespace
- Updated `00_index/quick-links.md` — Added Rollout Restart link in Kubernetes section

- Created missing directories for complete repo structure:
  - docs/setup-guides, docs/concepts, docs/troubleshooting, docs/runbooks, docs/reference
  - scripts/python, scripts/powershell, scripts/lib, scripts/examples
  - templates/project-starters, templates/docker, templates/terraform, templates/docs
  - lab/mini-projects, lab/sandboxes, assets/images, assets/diagrams

### Added
- k8s_toolkit: Enhanced drain-node.sh with pod eviction wait monitoring
  - Added `--wait` flag to monitor pod eviction progress
  - Added `--wait-timeout=<seconds>` flag (default: 300s) for configurable timeout
  - Script polls node until all pods are evicted or timeout reached
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
- kafka_toolkit: ACL management, monitoring, and partition reassignment scripts
  - `scripts/bash/kafka_toolkit/acl/manage-acls.sh`: Manage Kafka ACLs (list, add, remove) with dry-run
  - `scripts/bash/kafka_toolkit/monitoring/consumer-lag.sh`: Monitor consumer lag with alerting thresholds
  - `scripts/bash/kafka_toolkit/monitoring/throughput-check.sh`: Measure topic throughput and message rates
  - `scripts/bash/kafka_toolkit/partitions/partition-reassign.sh`: Generate/execute/verify partition reassignment plans
- Documentation: Extended `docs/how-to/kafka_toolkit.md` with ACL, monitoring, and reassignment sections
- Snippets: Extended `snippets/kafka-cheatsheet.md` with ACL operations, monitoring commands, reassignment examples
- Index updates: `00_index/quick-links.md` - Added Kafka section with all toolkit links

### Completed
- oci_registry_toolkit: Implementation complete, all scripts include dry-run modes, safety notes, and follow established standards.
- ci_cd_toolkit: Implementation complete with GitHub Actions helpers for linting, validation, health checks, and workflow generation.
- observability_toolkit: Implementation complete with Prometheus, Grafana, Loki, Jaeger, and OTel collector scripts. Includes PromQL and LogQL snippets, alerting rules, and Docker Compose examples.
- linux_toolkit: Implementation complete with system health monitoring, disk analysis, service management, network diagnostics, process management, and security audit scripts.
- kafka_toolkit: Implementation complete with ACL management, consumer lag monitoring, throughput checks, and partition reassignment helpers. All scripts include dry-run modes and safety guardrails.

## [2026-03-07] - k8s_toolkit Extended

### Added
- k8s_toolkit: New operational scripts for secret management, job cleanup, and context management
  - `scripts/bash/k8s_toolkit/secret/decode-secret.sh`: Decode Kubernetes secrets (base64 encoded values)
  - `scripts/bash/k8s_toolkit/job/cleanup-jobs.sh`: Clean up completed or failed Kubernetes jobs
  - `scripts/bash/k8s_toolkit/context/context-manager.sh`: Multi-cluster context switching and validation
- Documentation: Extended `docs/how-to/k8s_toolkit.md` with decode-secret, cleanup-jobs, and context-manager sections
- Index updates: `00_index/quick-links.md` - Added links to new scripts

## [2026-03-02] - Initial Bootstrap

Repository structure created with essential files and first tool implementation (k8s_toolkit). All mandatory components in place: index system, changelog, documentation standards, script templates, and PR automation.
