# Quick Links

## Getting Started
- [README](../README.md) - Repository overview and purpose
- [CHANGELOG](../CHANGELOG.md) - Version history and updates

## Tools
- [k8s_toolkit](how-to/k8s_toolkit.md) - Safe kubectl helper scripts (drain, rollout, restart with dry-run, logs, exec, debug, report, configmap, ingress, pvc)
- [oci_registry_toolkit](how-to/oci_registry_toolkit.md) - OCI registry helpers (list repos/tags, find old tags, keepalive plans, auth diagnostics)
- [ci_cd_toolkit](how-to/ci_cd_toolkit.md) - CI/CD pipeline helpers (workflow linting, health checks, action updates, workflow generation)
- [observability_toolkit](how-to/observability_toolkit.md) - Prometheus, Grafana, Loki, Jaeger, OTel query and health scripts
- [linux_toolkit](how-to/linux_toolkit.md) - Linux system administration scripts (health check, disk usage, service management, network diagnostics)

## Kafka
- [kafka_toolkit Usage](how-to/kafka_toolkit.md)
- [Kafka Cheatsheet](../snippets/kafka-cheatsheet.md)
- [Topic List](../scripts/bash/kafka_toolkit/topics/topic-list.sh)
- [Topic Create](../scripts/bash/kafka_toolkit/topics/topic-create.sh)
- [Topic Config](../scripts/bash/kafka_toolkit/topics/topic-config.sh)
- [Topic Delete](../scripts/bash/kafka_toolkit/topics/topic-delete.sh)
- [Consumer Groups](../scripts/bash/kafka_toolkit/consumers/consumer-groups.sh)
- [Message Produce/Consume](../scripts/bash/kafka_toolkit/messaging/produce-message.sh)
- [Cluster Health](../scripts/bash/kafka_toolkit/admin/cluster-health.sh)
- [ACL Management](../scripts/bash/kafka_toolkit/acl/manage-acls.sh)
- [Consumer Lag Monitoring](../scripts/bash/kafka_toolkit/monitoring/consumer-lag.sh)
- [Throughput Check](../scripts/bash/kafka_toolkit/monitoring/throughput-check.sh)
- [Partition Reassignment](../scripts/bash/kafka_toolkit/partitions/partition-reassign.sh)

## Topics
- [Kubernetes](#kubernetes)
- [Scripting](#scripting)
- [Troubleshooting](#troubleshooting)
- [Observability](#observability)

## Kubernetes
- [k8s_toolkit Usage](how-to/k8s_toolkit.md)
- [Kubectl Cheatsheet](../snippets/kubectl-cheatsheet.md)
- [Pod Debugging Guide](../docs/troubleshooting/k8s-pod-debug.md)
- [Namespace Report Script](../scripts/bash/k8s_toolkit/report/namespace-report.sh)
- [Debug Pod Interactive](../scripts/bash/k8s_toolkit/debug/debug-pod.sh)
- [Drain Node](../scripts/bash/k8s_toolkit/node/drain-node.sh)
- [Rollout Status](../scripts/bash/k8s_toolkit/rollout-status.sh)
- [Restart Pod](../scripts/bash/k8s_toolkit/pod/restart-pod.sh)
- [Pod Logs](../scripts/bash/k8s_toolkit/pod/pod-logs.sh)
- [Exec Pod](../scripts/bash/k8s_toolkit/pod/exec-pod.sh)
- [ConfigMap Manager](../scripts/bash/k8s_toolkit/configmap/configmap-manager.sh)
- [Ingress Diagnostics](../scripts/bash/k8s_toolkit/ingress/ingress-diagnostics.sh)
- [PVC Monitor](../scripts/bash/k8s_toolkit/pvc/pvc-monitor.sh)

## Container Registries
- [oci_registry_toolkit Usage](how-to/oci_registry_toolkit.md)
- [OCI Registry Cheatsheet](../snippets/oci-registry-cheatsheet.md)
- [List Repositories](../scripts/bash/oci_registry_toolkit/registry/list-repos.sh)
- [List Tags](../scripts/bash/oci_registry_toolkit/registry/list-tags.sh)
- [Find Old Tags](../scripts/bash/oci_registry_toolkit/tags/find-old-tags.sh)
- [Keepalive Pull Plan](../scripts/bash/oci_registry_toolkit/tools/keepalive-pull-plan.sh)
- [Auth Diagnostics](../scripts/bash/oci_registry_toolkit/auth/check-auth.sh)

## CI/CD
- [ci_cd_toolkit Usage](how-to/ci_cd_toolkit.md)
- [CI/CD Cheatsheet](../snippets/ci-cd-cheatsheet.md)
- [Lint Workflows](../scripts/bash/ci_cd_toolkit/github/lint-workflows.sh)
- [Validate Workflow](../scripts/bash/ci_cd_toolkit/github/validate-workflow.sh)
- [Pipeline Health](../scripts/bash/ci_cd_toolkit/github/pipeline-health.sh)
- [Check Action Updates](../scripts/bash/ci_cd_toolkit/github/check-action-updates.sh)
- [Generate Workflow](../scripts/bash/ci_cd_toolkit/github/generate-workflow.sh)

## Observability
- [observability_toolkit Usage](how-to/observability_toolkit.md)
- [Observability Cheatsheet](../snippets/observability-cheatsheet.md)
- [Prometheus Targets Status](../scripts/bash/observability_toolkit/prometheus/targets-status.sh)
- [Check Alert](../scripts/bash/observability_toolkit/prometheus/check-alert.sh)
- [Query Metrics](../scripts/bash/observability_toolkit/prometheus/query-metrics.sh)
- [Query Logs (Loki)](../scripts/bash/observability_toolkit/loki/query-logs.sh)
- [Grafana Health Check](../scripts/bash/observability_toolkit/grafana/health-check.sh)
- [Query Traces (Jaeger)](../scripts/bash/observability_toolkit/jaeger/query-traces.sh)
- [OTel Collector Health](../scripts/bash/observability_toolkit/otel/collector-health.sh)
- [Stack Health Check](../scripts/bash/observability_toolkit/stack-health.sh)

## Linux Administration
- [linux_toolkit Usage](how-to/linux_toolkit.md)
- [Linux Cheatsheet](../snippets/linux-cheatsheet.md)
- [System Health Check](../scripts/bash/linux_toolkit/system/health-check.sh)
- [Disk Usage Analysis](../scripts/bash/linux_toolkit/system/disk-usage.sh)
- [Service Management](../scripts/bash/linux_toolkit/service/manage-services.sh)
- [Network Diagnostics](../scripts/bash/linux_toolkit/network/net-diag.sh)
- [Process Manager](../scripts/bash/linux_toolkit/process/process-manager.sh)
- [Security Check](../scripts/bash/linux_toolkit/security/security-check.sh)

## Scripting
- [Bash Scripts](../scripts/bash/)
- [Python Scripts](../scripts/python/)
- [PowerShell Scripts](../scripts/powershell/)
- [Script Guidelines](../scripts/README.md)

## Templates
- [Kubernetes Templates](../templates/k8s/)
- [Docker Templates](../templates/docker/)
- [Terraform Templates](../templates/terraform/)
- [Project Starters](../templates/project-starters/)

## Reference
- [Glossary](../00_index/glossary.md)
- [Runbooks](../docs/runbooks/)
- [Concepts](../docs/concepts/)
