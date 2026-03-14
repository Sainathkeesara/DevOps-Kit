# Quick Links

## Getting Started
- [README](../README.md) - Repository overview and purpose
- [CHANGELOG](../CHANGELOG.md) - Version history and updates

## Tools
- [k8s_toolkit](how-to/k8s_toolkit.md) - Safe kubectl helper scripts (drain, rollout, restart with dry-run, logs, exec, debug, report)
- [jenkins_toolkit](how-to/jenkins_toolkit.md) - Jenkins automation scripts (install, plugins, configuration)
- [oci_registry_toolkit](how-to/oci_registry_toolkit.md) - OCI registry helpers (list repos/tags, find old tags, keepalive plans, auth diagnostics)
- [ci_cd_toolkit](how-to/ci_cd_toolkit.md) - CI/CD pipeline helpers (workflow linting, health checks, action updates, workflow generation)
- [observability_toolkit](how-to/observability_toolkit.md) - Prometheus, Grafana, Loki, Jaeger, OTel query and health scripts
- [linux_toolkit](how-to/linux_toolkit.md) - Linux system administration scripts (health check, disk usage, service management, network diagnostics)
- [terraform_toolkit](how-to/terraform_toolkit.md) - Terraform workflow scripts (init/plan/apply/destroy with sensitive value handling)

## Kafka
- [kafka_toolkit Usage](how-to/kafka_toolkit.md) - Prerequisites include [Kafka Cluster Setup Guide](docs/setup-guides/kafka-cluster-setup.md)
- [Kafka Cluster Setup Guide](docs/setup-guides/kafka-cluster-setup.md) - Single broker setup for local development
- [Kafka Cheatsheet](../snippets/kafka-cheatsheet.md)
- [Topic Management](../scripts/bash/kafka_toolkit/topics/topic-list.sh)
- [Consumer Groups](../scripts/bash/kafka_toolkit/consumers/consumer-groups.sh)
- [Consumer Lag Check](../scripts/bash/kafka_toolkit/consumers/check-lag.sh)
- [Message Produce/Consume](../scripts/bash/kafka_toolkit/messaging/produce-message.sh)
- [Cluster Health](../scripts/bash/kafka_toolkit/admin/cluster-health.sh)
- [Broker Health Check](../scripts/bash/kafka_toolkit/admin/broker-health.sh) - Port, JMX, replica status verification
- [ACL Management](../scripts/bash/kafka_toolkit/acl/manage-acls.sh)
- [Consumer Lag Monitoring](../scripts/bash/kafka_toolkit/monitoring/consumer-lag.sh)
- [Throughput Check](../scripts/bash/kafka_toolkit/monitoring/throughput-check.sh)
- [Partition Reassignment](../scripts/bash/kafka_toolkit/partitions/partition-reassign.sh)
- [CVE-2025-27818 Hardening](../scripts/bash/kafka_toolkit/security/cve-2025-27818.sh) - Kafka Connect SASL JAAS RCE vulnerability scanner
- [CVE-2025-27817 Hardening](../scripts/bash/kafka_toolkit/security/cve-2025-27817.sh) - Kafka Client arbitrary file read/SSRF vulnerability scanner

## Topics
- [Kubernetes](#kubernetes)
- [Scripting](#scripting)
- [Troubleshooting](#troubleshooting)
- [Observability](#observability)

## Troubleshooting
- [CrashLoopBackOff](docs/troubleshooting/k8s-crashloopbackoff.md)
- [Pod Debugging](docs/troubleshooting/k8s-pod-debug.md)

## Kubernetes
- [k8s_toolkit Usage](how-to/k8s_toolkit.md)
- [EKS Cluster Setup Guide](docs/setup-guides/eks-cluster-setup.md) - Complete guide for creating EKS cluster from scratch on AWS
- [Kubectl Cheatsheet](../snippets/kubectl-cheatsheet.md)
- [Pod Debugging Guide](../docs/troubleshooting/k8s-pod-debug.md)
- [Production Deployment Template](../templates/k8s/production-deployment.yaml) - Deployment + HPA + PDB with anti-affinity
- [Deploy Production App Script](../templates/k8s/deploy-prod-app.sh) - Generate and apply production deployment with customizable port
- [Namespace Report Script](../scripts/bash/k8s_toolkit/report/namespace-report.sh)
- [Debug Pod Interactive](../scripts/bash/k8s_toolkit/debug/debug-pod.sh)
- [Drain Node](../scripts/bash/k8s_toolkit/node/drain-node.sh) - Now with --wait and --wait-timeout flags for pod eviction monitoring
- [Decode Secret](../scripts/bash/k8s_toolkit/secret/decode-secret.sh)
- [Cleanup Jobs](../scripts/bash/k8s_toolkit/job/cleanup-jobs.sh)
- [Context Manager](../scripts/bash/k8s_toolkit/context/context-manager.sh)
- [Rollout Status](../scripts/bash/k8s_toolkit/rollout-status.sh)
- [Rollout Restart](../scripts/bash/k8s_toolkit/rollout-restart.sh) - Restart deployments with --watch and --timeout flags
- [Restart Pod](../scripts/bash/k8s_toolkit/pod/restart-pod.sh)
- [Pod Logs](../scripts/bash/k8s_toolkit/pod/pod-logs.sh)
- [Exec Pod](../scripts/bash/k8s_toolkit/pod/exec-pod.sh)
- [RBAC Guide](docs/how-to/k8s_rbac.md) - Role, ClusterRole, RoleBinding, ClusterRoleBinding with examples
- [CVE-2026-3288 Hardening](../scripts/bash/k8s_toolkit/security/cve-2026-3288-nginx.sh) - ingress-nginx rewrite-target RCE vulnerability scanner with --remediate and --dry-run flags

## Jenkins
- [jenkins_toolkit Usage](how-to/jenkins_toolkit.md)
- [Jenkins Cheatsheet](../snippets/jenkins-cheatsheet.md)
- [Install Jenkins](../scripts/bash/jenkins_toolkit/install-jenkins.sh) - Automated install on Ubuntu 22.04 with --dry-run and --port options
- [GitHub Webhook Setup](how-to/github-webhook-jenkins.md) - Configure GitHub webhooks to trigger Jenkins builds
- [CVE-2026-27099 Hardening](../scripts/bash/jenkins_toolkit/security/cve-2026-27099.sh) - Jenkins XSS and DoS vulnerability scanner

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
- [Disk Usage Analysis](../scripts/bash/linux_toolkit/system/disk-usage.sh) - With --dry-run, --threshold, and --help flags
- [Service Management](../scripts/bash/linux_toolkit/service/manage-services.sh)
- [Network Diagnostics](../scripts/bash/linux_toolkit/network/net-diag.sh)
- [Process Manager](../scripts/bash/linux_toolkit/process/process-manager.sh)
- [Security Check](../scripts/bash/linux_toolkit/security/security-check.sh)

## Terraform
- [terraform_toolkit Usage](how-to/terraform_toolkit.md)
- [Terraform Workflow Script](../scripts/bash/terraform_toolkit/terraform-workflow.sh) - init/plan/apply with sensitive value handling and --dry-run support

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
