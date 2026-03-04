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
 - oci_registry_toolkit: OCI registry helper scripts
   - `scripts/bash/oci_registry_toolkit/registry/list-repos.sh`: List repositories in a registry
   - `scripts/bash/oci_registry_toolkit/registry/list-tags.sh`: List tags for a repository
   - `scripts/bash/oci_registry_toolkit/tags/find-old-tags.sh`: Find old/unused tags based on age or pattern
   - `scripts/bash/oci_registry_toolkit/tools/keepalive-pull-plan.sh`: Generate script to pull artifacts for offline/keepalive
   - `scripts/bash/oci_registry_toolkit/auth/check-auth.sh`: Diagnose registry authentication issues
 - Documentation: `docs/how-to/oci_registry_toolkit.md` - Complete usage guide
 - Snippets: `snippets/oci-registry-cheatsheet.md` - OCI registry quick reference
 - Index updates: `00_index/quick-links.md` - Added OCI/Container Registries section
 - kafka_toolkit: Apache Kafka helper scripts for topic and consumer management
   - `scripts/bash/kafka_toolkit/topics/list-topics.sh`: List topics with optional detailed view and under-replicated filter
   - `scripts/bash/kafka_toolkit/topics/describe-topic.sh`: Get detailed topic information with partition/replica status
   - `scripts/bash/kafka_toolkit/topics/topic-create.sh`: Create topics with validation and safe defaults
   - `scripts/bash/kafka_toolkit/consumers/consumer-lag-check.sh`: Check consumer group lag and offsets
   - `scripts/bash/kafka_toolkit/diagnostics/test-produce-consume.sh`: Verify connectivity with test messages
 - Documentation: `docs/how-to/kafka_toolkit.md` - Complete usage guide following DOC STANDARD
 - Snippets: `snippets/kafka-cheatsheet.md` - Quick reference for Kafka CLI commands
 - Index updates: `00_index/quick-links.md` - Added Kafka section with all tool links

### Changed
- N/A (initial release)

### Deprecated
- N/A

### Fixed
- N/A

### Security
- N/A

### Completed
- oci_registry_toolkit: Implementation complete, all scripts include dry-run modes, safety notes, and follow established standards.

## [2026-03-02] - Initial Bootstrap

Repository structure created with essential files and first tool implementation (k8s_toolkit). All mandatory components in place: index system, changelog, documentation standards, script templates, and PR automation.
