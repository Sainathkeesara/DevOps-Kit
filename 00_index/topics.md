# Topics

## Kubernetes
- [script] scripts/bash/k8s_toolkit/node/drain-node.sh — Safely drain a node before maintenance
- [script] scripts/bash/k8s_toolkit/node/rollout-status.sh — Monitor deployment rollout status
- [script] scripts/bash/k8s_toolkit/pod/restart-pod.sh — Restart pods with graceful termination
- [script] scripts/bash/k8s_toolkit/pod/pod-logs.sh — Stream and tail pod logs
- [script] scripts/bash/k8s_toolkit/pod/exec-pod.sh — Execute commands in running pods
- [script] scripts/bash/k8s_toolkit/debug/debug-pod.sh — Interactive pod debugging session
- [script] scripts/bash/k8s_toolkit/report/namespace-report.sh — Generate namespace resource reports
- [script] scripts/bash/k8s_toolkit/secret/decode-secret.sh — Decode base64 Kubernetes secrets
- [script] scripts/bash/k8s_toolkit/job/cleanup-jobs.sh — Clean up completed or failed jobs
- [script] scripts/bash/k8s_toolkit/context/context-manager.sh — Multi-cluster context switching
- [script] scripts/bash/k8s_toolkit/rollout-restart.sh — Restart deployments with watch
- [script] scripts/bash/k8s_toolkit/security/cve-2026-3288-nginx.sh — ingress-nginx RCE vulnerability scanner
- [script] scripts/bash/kubernetes/aks-privilege-escalation-hardening.sh — AKS privilege escalation hardening
- [script] scripts/bash/kubernetes/mcp-server-kubernetes-hardening.sh — mcp-server-kubernetes CVE-2026-39884 hardening
- [script] scripts/bash/k8s/security/k8s-acm-cve-2026-4740.sh — Kubernetes ACM privilege escalation scanner
- [doc] docs/how-to/k8s_toolkit.md — Complete usage guide for all k8s scripts
- [doc] docs/how-to/k8s_rbac.md — Role, ClusterRole, RoleBinding guide
- [doc] docs/how-to/k8s-aks-cve-2026-33105.md — AKS privilege escalation remediation
- [doc] docs/troubleshooting/k8s-crashloopbackoff.md — CrashLoopBackOff diagnosis and fix
- [doc] docs/troubleshooting/kubernetes-mcp-server-cve-2026-39884.md — MCP server Kubernetes CVE remediation
- [doc] docs/troubleshooting/k8s-cluster-autoscaler-cve-2026-33186.md — cluster-autoscaler CVE hardening
- [doc] docs/setup-guides/eks-cluster-setup.md — EKS cluster setup guide
- [snippet] snippets/kubectl-cheatsheet.md — Quick kubectl reference
- [template] templates/k8s/production-deployment.yaml — Deployment with HPA and PDB
- [template] templates/k8s/deploy-prod-app.sh — Production deployment generator
- [template] templates/k8s/deployment-monitor.sh — Deployment monitoring script

## Kafka
- [script] scripts/bash/kafka_toolkit/topics/topic-list.sh — List Kafka topics
- [script] scripts/bash/kafka_toolkit/topics/topic-create.sh — Create new topics
- [script] scripts/bash/kafka_toolkit/topics/topic-delete.sh — Delete topics
- [script] scripts/bash/kafka_toolkit/topics/topic-config.sh — View/modify topic config
- [script] scripts/bash/kafka_toolkit/consumers/consumer-groups.sh — List consumer groups
- [script] scripts/bash/kafka_toolkit/consumers/check-lag.sh — Check consumer lag with thresholds
- [script] scripts/bash/kafka_toolkit/messaging/produce-message.sh — Produce messages to topic
- [script] scripts/bash/kafka_toolkit/messaging/consume-message.sh — Consume messages from topic
- [script] scripts/bash/kafka_toolkit/admin/cluster-health.sh — Cluster health overview
- [script] scripts/bash/kafka_toolkit/admin/broker-health.sh — Individual broker health check
- [script] scripts/bash/kafka_toolkit/acl/manage-acls.sh — Manage Kafka ACLs
- [script] scripts/bash/kafka_toolkit/monitoring/consumer-lag.sh — Monitor consumer lag
- [script] scripts/bash/kafka_toolkit/monitoring/throughput-check.sh — Measure topic throughput
- [script] scripts/bash/kafka_toolkit/partitions/partition-reassign.sh — Partition reassignment
- [script] scripts/bash/kafka_toolkit/partitions/partition-mgmt.sh — Partition management
- [script] scripts/bash/kafka_toolkit/security/cve-2025-27818.sh — Kafka Connect SASL JAAS RCE scanner
- [script] scripts/bash/kafka_toolkit/security/cve-2025-27817.sh — Kafka Client SSRF scanner
- [doc] docs/how-to/kafka_toolkit.md — Complete usage guide
- [doc] docs/setup-guides/kafka-cluster-setup.md — Local Kafka cluster setup
- [doc] docs/troubleshooting/kafka-consumer-lag.md — Consumer lag troubleshooting
- [snippet] snippets/kafka-cheatsheet.md — Kafka commands reference

## Jenkins
- [script] scripts/bash/jenkins_toolkit/install-jenkins.sh — Automated Jenkins installation
- [script] scripts/bash/jenkins_toolkit/security/cve-2026-27099.sh — Jenkins XSS/DoS vulnerability scanner
- [doc] docs/how-to/jenkins_toolkit.md — Jenkins toolkit usage guide
- [doc] docs/how-to/github-webhook-jenkins.md — GitHub webhook configuration
- [snippet] snippets/jenkins-cheatsheet.md — Jenkinsfile examples

## Linux
- [script] scripts/bash/linux_toolkit/system/health-check.sh — System health monitoring
- [script] scripts/bash/linux_toolkit/system/disk-usage.sh — Disk usage analysis
- [script] scripts/bash/linux_toolkit/service/manage-services.sh — Systemd service management
- [script] scripts/bash/linux_toolkit/network/net-diag.sh — Network diagnostics
- [script] scripts/bash/linux_toolkit/process/process-manager.sh — Process management
- [script] scripts/bash/linux_toolkit/security/security-check.sh — Security audit
- [script] scripts/bash/linux/aide-config.sh — AIDE configuration management
- [script] scripts/bash/linux/linux-container-security-scan.sh — Container security scanning with Trivy
- [doc] docs/how-to/linux_toolkit.md — Linux toolkit usage guide
- [doc] docs/how-to/linux-aide-configuration.md — AIDE setup and usage guide
- [doc] docs/how-to/linux-aide-configuration-management.md — AIDE configuration management
- [doc] docs/how-to/linux-container-security-scanning.md — Container security scanning with Trivy and Falco
- [snippet] snippets/linux-cheatsheet.md — Linux commands reference

## Observability
- [script] scripts/bash/observability_toolkit/prometheus/targets-status.sh — Prometheus targets health
- [script] scripts/bash/observability_toolkit/prometheus/check-alert.sh — Check Prometheus alerts
- [script] scripts/bash/observability_toolkit/prometheus/query-metrics.sh — Execute PromQL queries
- [script] scripts/bash/observability_toolkit/loki/query-logs.sh — Query Loki logs with LogQL
- [script] scripts/bash/observability_toolkit/grafana/health-check.sh — Grafana health check
- [script] scripts/bash/observability_toolkit/jaeger/query-traces.sh — Query Jaeger traces
- [script] scripts/bash/observability_toolkit/otel/collector-health.sh — OTel collector health
- [script] scripts/bash/observability_toolkit/stack-health.sh — Full stack health check
- [doc] docs/how-to/observability_toolkit.md — Observability toolkit usage guide
- [snippet] snippets/observability-cheatsheet.md — PromQL, LogQL reference

## OCI/Container Registries
- [script] scripts/bash/oci_registry_toolkit/registry/list-repos.sh — List repositories
- [script] scripts/bash/oci_registry_toolkit/registry/list-tags.sh — List tags for repo
- [script] scripts/bash/oci_registry_toolkit/tags/find-old-tags.sh — Find old/unused tags
- [script] scripts/bash/oci_registry_toolkit/tools/keepalive-pull-plan.sh — Generate keepalive pull plan
- [script] scripts/bash/oci_registry_toolkit/auth/check-auth.sh — Auth diagnostics
- [doc] docs/how-to/oci_registry_toolkit.md — OCI registry toolkit usage guide
- [snippet] snippets/oci-registry-cheatsheet.md — Registry commands reference

## CI/CD
- [script] scripts/bash/ci_cd_toolkit/github/lint-workflows.sh — Lint GitHub Actions workflows
- [script] scripts/bash/ci_cd_toolkit/github/validate-workflow.sh — Validate workflow syntax
- [script] scripts/bash/ci_cd_toolkit/github/pipeline-health.sh — Check pipeline health
- [script] scripts/bash/ci_cd_toolkit/github/check-action-updates.sh — Check for outdated actions
- [script] scripts/bash/ci_cd_toolkit/github/generate-workflow.sh — Generate starter workflows
- [doc] docs/how-to/ci_cd_toolkit.md — CI/CD toolkit usage guide
- [snippet] snippets/ci-cd-cheatsheet.md — CI/CD commands reference

## Terraform
- [script] scripts/bash/terraform_toolkit/terraform-workflow.sh — Terraform workflow automation
- [script] scripts/bash/terraform_toolkit/eks/eks-deploy.sh — EKS cluster deployment
- [script] scripts/bash/terraform_toolkit/eks/eks-cleanup.sh — EKS cluster cleanup
- [script] scripts/bash/terraform_toolkit/eks/eks-health-check.sh — EKS health check
- [script] scripts/bash/terraform_toolkit/multi-env/multi-env-setup.sh — Multi-environment setup
- [script] scripts/bash/terraform_toolkit/rds-deploy.sh — RDS deployment
- [script] scripts/bash/terraform_toolkit/atlantis/setup-atlantis.sh — Atlantis setup
- [script] scripts/bash/terraform_toolkit/secrets/terraform-secrets-deploy.sh — AWS Secrets Manager deployment
- [doc] docs/how-to/terraform-eks-cluster.md — EKS cluster setup guide
- [doc] docs/how-to/terraform-multi-env-gitops.md — Multi-environment GitOps
- [doc] docs/how-to/terraform-rds-read-replicas.md — RDS with read replicas
- [doc] docs/how-to/terraform-secrets-manager.md — AWS Secrets Manager integration

## Ansible
- [script] scripts/bash/ansible_toolkit/security/cve-2025-14010-audit.sh — Sensitive variable exposure scanner
- [script] scripts/bash/ansible_toolkit/security/cve-2026-0598-audit.sh — Lightspeed auth bypass scanner
- [script] scripts/bash/ansible_toolkit/security/aap-cve-2026-24049-check.sh — Wheel privilege escalation scanner
- [script] scripts/bash/ansible_toolkit/security/aap-cve-2026-0598-check.sh — AAP Lightspeed auth bypass scanner
- [script] scripts/bash/ansible_toolkit/security/vault-password-rotation.sh — Rotate vault passwords
- [doc] docs/how-to/ansible_toolkit.md — Ansible toolkit usage guide
- [doc] docs/how-to/ansible-lightspeed-cve-2026-0598.md — CVE-2026-0598 how-to guide

## Vault
- [script] scripts/bash/vault_toolkit/security/cve-2025-11621.sh — AWS Auth bypass vulnerability scanner
- [script] scripts/bash/vault_toolkit/security/cve-2025-5999.sh — Privilege escalation vulnerability scanner
- [script] scripts/bash/vault_toolkit/security/cve-2025-6000.sh — Plugin directory RCE vulnerability scanner
- [script] scripts/bash/vault_toolkit/security/cve-2025-6037.sh — TLS certificate auth bypass scanner
- [doc] docs/how-to/vault_toolkit.md — Vault toolkit usage guide
- [doc] docs/how-to/vault-secure-deployment.md — Vault secure deployment guide
- [doc] docs/how-to/vault-troubleshooting-seal-unseal.md — Seal/unseal troubleshooting
- [doc] docs/troubleshooting/vault-seal-unseal.md — Vault seal/unseal issues

## Docker
- [script] scripts/bash/docker_toolkit/security/cve-2026-28400.sh — Model Runner privilege escalation scanner
- [doc] docs/how-to/docker-security-best-practices.md — Docker security hardening guide

## Helm
- [script] scripts/bash/helm_toolkit/security/cve-2025-53547.sh — Chart.yaml code injection scanner
- [script] scripts/bash/helm_toolkit/security/cve-2025-53547-harden.sh — Helm Chart security hardening
- [doc] docs/how-to/helm-security-scanning.md — Helm security scanning guide
