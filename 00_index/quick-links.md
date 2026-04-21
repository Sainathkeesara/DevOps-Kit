# Quick Links

## Getting Started
- [README](../README.md) - Repository overview and purpose
- [CHANGELOG](../CHANGELOG.md) - Version history and updates

## Jenkins
- [jenkins_cli_commands_reference](snippets/jenkins-cli-commands.md) - Jenkins CLI commands reference with 80+ commands for sysadmins
- [jenkins_scripted_pipeline_groovy](snippets/jenkins-scripted-pipeline-groovy.md) - Jenkins Scripted Pipeline Groovy examples and patterns

## Ansible
- [ansible_playbook_best_practices](docs/how-to/ansible-playbook-best-practices.md) - Ansible playbook best practices guide for production
- [jenkins_cli_commands](docs/reference/jenkins-commands.md) - Jenkins CLI commands reference with 50+ commands for automation and scripting

## Git
- [git_installation](docs/how-to/git-installation.md) - Automated Git installation script for Linux (idempotent, supports Ubuntu/Debian, AlmaLinux/RHEL, Fedora)
- [git_install_script](scripts/bash/git/git-install.sh) - Automation script with version control, dry-run, source build support
- [git_installation_macos](docs/how-to/git-installation-macos.md) - Git installation on macOS via Homebrew with verification
- [git_install_macos_script](scripts/bash/git/git-install-macos.sh) - Automated Git installation script for macOS with dry-run support
- [git_installation_wsl](docs/how-to/git-installation-wsl.md) - Git installation on Windows Subsystem for Linux (WSL) with PPA and configuration
- [git_install_wsl_script](scripts/bash/git/git-install-wsl.sh) - Automated Git installation script for WSL with dry-run support
- [git_commands_reference](snippets/git-commands.md) - Git CLI commands reference with 80+ commands for developers

## Linux
- [linux_commands_reference](snippets/linux-commands.md) - Linux commands reference with 30+ bash one-liners for sysadmins
- [linux_freeipa_identity](docs/how-to/linux-freeipa-identity.md) - FreeIPA identity management: server deployment, client enrollment, user/group/sudo management
- [freeipa_setup_script](scripts/bash/linux/identity/freeipa-setup.sh) - Automated FreeIPA server deployment and client enrollment script
- [linux_aide_configuration](docs/how-to/linux-aide-configuration-management.md) - AIDE file integrity monitoring: installation, configuration, baseline management
- [aide_deploy_script](scripts/bash/linux/aide-deploy.sh) - Automated AIDE deployment and management script with dry-run support
- [linux_wazuh_siem](docs/how-to/linux/linux-wazuh-siem.md) - Wazuh SIEM deployment: server, agent, alerting, integration
- [wazuh_deploy_script](scripts/bash/linux/wazuh-deploy.sh) - Automated Wazuh SIEM deployment script with dry-run support

## Terraform
- [terraform_production_module_template](../templates/terraform/production-module-template.md) - Production Terraform module template with security guardrails
- [terraform_aws_vpc](docs/how-to/terraform-aws-vpc.md) - AWS VPC setup with public/private subnets, NAT Gateway, and routing
- [terraform_eks_cluster](docs/how-to/terraform-eks-cluster.md) - EKS cluster with managed node groups, autoscaling, and VPC networking
- [terraform_multi_env_gitops](docs/how-to/terraform-multi-env-gitops.md) - Multi-environment infrastructure with Terraform workspaces and GitOps workflow
- [terraform_s3_crr](docs/how-to/terraform-s3-cross-region-replication.md) - S3 bucket with cross-region replication for disaster recovery
- [terraform_lambda_api](docs/how-to/terraform-lambda-api-gateway.md) - Serverless API with Lambda and API Gateway integration
- [terraform_iam_roles](docs/how-to/terraform-iam-roles.md) - Reusable IAM roles with policy modules, least-privilege access, and cross-account support
- [terraform_state_management](docs/how-to/terraform-state-management.md) - Terraform state management best practices: backends, locking, encryption, workspaces
- [terraform_troubleshooting](docs/how-to/terraform-troubleshooting.md) - Terraform troubleshooting guide: plan/apply failures, state issues, provider errors
- [terraform_cli_one_liners](snippets/terraform-commands.md) - Terraform CLI one-liners for init, plan, apply, state management
- [lambda_deploy_script](scripts/bash/terraform_toolkit/terraform-lambda-deploy.sh) - Automated Lambda/API Gateway deployment script with dry-run
- [iam_roles_deploy_script](scripts/bash/terraform/terraform-iam-roles-deploy.sh) - Automated IAM roles and policy deployment script with dry-run
- [multi_env_setup_script](scripts/bash/terraform_toolkit/multi-env/multi-env-setup.sh) - Automated multi-environment Terraform setup with backend initialization
- [multi_env_vpc_module](templates/terraform/multi-env/vpc-module.tf) - Reusable VPC module for multi-environment deployments
- [eks_deploy_script](scripts/bash/terraform_toolkit/eks/eks-deploy.sh) - Automated EKS cluster deployment script
- [eks_health_check](scripts/bash/terraform_toolkit/eks/eks-health-check.sh) - EKS cluster health verification script
- [eks_cleanup_script](scripts/bash/terraform_toolkit/eks/eks-cleanup.sh) - Safe EKS cluster cleanup with dry-run support
- [vpc_setup_script](scripts/bash/terraform_toolkit/networking/vpc-setup.sh) - Automated Terraform VPC deployment script

## Tools
- [k8s_toolkit](docs/how-to/k8s_toolkit.md) - Safe kubectl helper scripts (drain, rollout, restart with dry-run, logs, exec, debug, report)
- [jenkins_toolkit](docs/how-to/jenkins_toolkit.md) - Jenkins automation scripts (install, plugins, configuration)
- [jenkins_commands](docs/reference/jenkins-commands.md) - Jenkins CLI commands reference (50+ commands for job/build/node management)
- [jenkins_rest_api](docs/reference/jenkins-rest-api.md) - Jenkins REST API calls for automation (job management, builds, queue, agents, plugins)
- [ansible_toolkit](docs/how-to/ansible_toolkit.md) - Ansible security audit scripts (sensitive variable exposure, CVE-2025-14010)
- [CVE-2025-9907](scripts/bash/ansible_toolkit/security/cve-2025-9907-eda-creds.sh) - Ansible Automation Platform EDA credentials exposure scanner
- [CVE-2026-0598](scripts/bash/ansible_toolkit/security/cve-2026-0598-audit.sh) - Ansible Lightspeed API auth bypass scanner
- [docker_toolkit](docs/how-to/docker-security-best-practices.md) - Docker security hardening guide (image scanning, runtime security, secrets management)
- [CVE-2026-2664](scripts/bash/docker_toolkit/security/cve-2026-2664.sh) - Docker Desktop grpcfuse kernel module privilege escalation scanner
- [CVE-2026-28400](scripts/bash/docker_toolkit/security/cve-2026-28400.sh) - Docker Model Runner privilege escalation scanner
- [CVE-2026-34040](scripts/bash/docker/security/docker-cve-2026-34040.sh) - Docker authorization plugin bypass scanner

## Vault
- [vault_audit_log_analysis](scripts/bash/vault/vault-audit-log-analysis.sh) - Vault audit log analysis for security events and anomalies
- [vault_commands_reference](../snippets/vault-commands.md) - Vault CLI commands for authentication, secrets, policies

## Helm
- [helm_commands_reference](docs/how-to/helm-commands-reference.md) - Helm CLI commands reference with 80+ examples
- [CVE-2026-4740](scripts/bash/k8s/security/k8s-acm-cve-2026-4740.sh) - Kubernetes ACM privilege escalation scanner
- [oci_registry_toolkit](docs/how-to/oci_registry_toolkit.md) - OCI registry helpers (list repos/tags, find old tags, keepalive plans, auth diagnostics)
- [ci_cd_toolkit](docs/how-to/ci_cd_toolkit.md) - CI/CD pipeline helpers (workflow linting, health checks, action updates, workflow generation)
- [observability_toolkit](docs/how-to/observability_toolkit.md) - Prometheus, Grafana, Loki, Jaeger, OTel query and health scripts
- [linux_toolkit](docs/how-to/linux_toolkit.md) - Linux system administration scripts (health check, disk usage, service management, network diagnostics)
- [linux_backup_solution](docs/how-to/linux-backup-rsync-retention.md) - Automated backup solution with rsync and retention policy
- [linux_aide_configuration](docs/how-to/linux-aide-configuration.md) - AIDE file integrity monitoring and configuration management
- [aide_config_script](scripts/bash/linux/aide-config.sh) - Automated AIDE installation and configuration script
- [linux_container_host](docs/how-to/linux-container-host-security.md) - Container host setup with Docker and security hardening
- [container_host_hardening](scripts/bash/linux_toolkit/security/container-host-hardening.sh) - Security hardening script for Docker container hosts
- [backup_script](scripts/bash/linux_toolkit/backup/backup-rsync-retention.sh) - Backup script with dry-run, encryption, and retention support
- [linux_elk_log_aggregation](docs/how-to/linux-elk-log-aggregation.md) - ELK stack log aggregation system setup guide
- [elk_setup_script](scripts/bash/linux_toolkit/logging/elk-setup.sh) - Automated ELK stack installation script (Elasticsearch, Logstash, Kibana, Filebeat)
- [linux_nginx_ssl_proxy](docs/how-to/linux-nginx-reverse-proxy-ssl-tls.md) - Nginx reverse proxy with SSL/TLS termination guide
- [nginx_reverse_proxy_script](scripts/bash/linux_toolkit/network/nginx-reverse-proxy.sh) - Automated Nginx reverse proxy setup with SSL/TLS
- [linux_mail_server](docs/how-to/linux-mail-server.md) - Mail server setup with Postfix and Dovecot guide
- [mail_server_script](scripts/bash/linux_toolkit/mail/mail-server-setup.sh) - Automated Postfix and Dovecot mail server installation script
- [linux_vpn_wireguard](docs/how-to/linux-vpn-wireguard.md) - VPN server setup with WireGuard guide
- [wireguard_script](scripts/bash/linux_toolkit/vpn/wireguard-server-setup.sh) - Automated WireGuard VPN server installation script
- [linux_dns_bind9](docs/how-to/linux-dns-bind9.md) - DNS server setup with BIND9 guide
- [bind9_script](scripts/bash/linux_toolkit/dns/bind9-server-setup.sh) - Automated BIND9 DNS server installation script
- [linux_haproxy_lb](docs/how-to/linux-haproxy-load-balancer.md) - HAProxy load balancer with SSL termination and Prometheus exporter
- [haproxy_setup_script](scripts/bash/linux_toolkit/loadbalancer/haproxy-setup.sh) - Automated HAProxy load balancer setup script
- [linux_samba_sharing](docs/how-to/linux-samba-file-sharing.md) - Samba file sharing server for cross-platform access
- [samba_setup_script](scripts/bash/linux_toolkit/samba/samba-setup.sh) - Automated Samba file server setup script
- [terraform_toolkit](scripts/bash/terraform_toolkit/terraform-workflow.sh) - Terraform workflow scripts (init/plan/apply/destroy with sensitive value handling)
- [vault_toolkit](docs/how-to/vault_toolkit.md) - Vault security hardening scripts (CVE detection and remediation)
- [CVE-2025-6037](scripts/bash/vault_toolkit/security/cve-2025-6037.sh) - TLS certificate auth validation bypass detection
- [CVE-2026-4660](scripts/bash/vault/security/vault-go-getter-hardening.sh) - go-getter arbitrary file read vulnerability detection
- [Helm + Terraform Full-Stack](docs/how-to/helm-terraform-fullstack/README.md) - Complete infrastructure-as-code workflow combining Terraform for EKS provisioning and Helm for application deployment
- [Helm + Terraform Deploy Script](scripts/bash/helm_toolkit/helm-terraform/deploy-helm-terraform.sh) - Automated deployment script for Helm + Terraform workflow

## Kafka
- [kafka_toolkit Usage](docs/how-to/kafka_toolkit.md) - Prerequisites include [Kafka Cluster Setup Guide](docs/setup-guides/kafka-cluster-setup.md)
- [Kafka Cluster Setup Guide](docs/setup-guides/kafka-cluster-setup.md) - Single broker setup for local development
- [Kafka Troubleshooting](docs/troubleshooting/kafka-consumer-lag.md) - Consumer lag and rebalancing issues
- [Kafka Commands Reference](../snippets/kafka-topics-commands.md) - Kafka topics CLI one-liners for topic management and consumer groups
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
- [Kafka Consumer Lag](docs/troubleshooting/kafka-consumer-lag.md)
- [Vault Seal/Unseal](docs/troubleshooting/vault-seal-unseal.md)

## Jenkins
- [jenkins_troubleshooting](docs/troubleshooting/jenkins-troubleshooting.md) - Jenkins troubleshooting guide for startup failures, plugin issues, build failures, and agent connectivity
- [jenkinsfile_maven_gradle_template](../templates/jenkins/Jenkinsfile-maven-gradle-template.md) - Reusable Jenkinsfile template for Maven/Gradle builds with CI/CD pipeline

## Kubernetes
- [k8s_toolkit Usage](docs/how-to/k8s_toolkit.md)
- [EKS Cluster Setup Guide](docs/setup-guides/eks-cluster-setup.md) - Complete guide for creating EKS cluster from scratch on AWS
- [Kubectl Cheatsheet](../snippets/kubectl-cheatsheet.md)
- [Kubernetes Provisioning with Terraform + Ansible](docs/how-to/k8s-terraform-ansible-provisioning.md) - End-to-end self-managed K8s cluster on AWS using Terraform for infrastructure and Ansible for configuration (L9 cross-tool project)
- [Kubernetes CI/CD with Jenkins and Vault](docs/how-to/k8s-jenkins-vault-cicd-security.md) - Secure CI/CD pipeline with Jenkins, Vault secrets injection, Trivy and Kubescape security scanning (L9 cross-tool project)
- [Kubernetes GitOps with ArgoCD + Vault](docs/how-to/k8s-argocd-vault-gitops.md) - GitOps workflow with ArgoCD and Vault secrets injection via CSI Provider (L9 cross-tool project)
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
- [jenkins_toolkit Usage](docs/how-to/jenkins_toolkit.md)
- [Jenkins Cheatsheet](../snippets/jenkins-cheatsheet.md)
- [Jenkins Commands Reference](../snippets/jenkins-commands-reference.md) - 100+ CLI commands for job management, builds, nodes, plugins, credentials, and pipelines
- [Jenkins Scripted Pipeline Groovy Snippets](../snippets/jenkins-scripted-pipeline-groovy.md) - 50+ Groovy code snippets for scripted pipelines
- [Install Jenkins](../scripts/bash/jenkins_toolkit/install-jenkins.sh) - Automated install on Ubuntu 22.04 with --dry-run and --port options
- [GitHub Webhook Setup](docs/how-to/github-webhook-jenkins.md) - Configure GitHub webhooks to trigger Jenkins builds
- [CVE-2026-27099 Hardening](../scripts/bash/jenkins_toolkit/security/cve-2026-27099.sh) - Jenkins XSS and DoS vulnerability scanner

## Container Registries
- [Harbor Registry Setup](docs/how-to/linux-harbor-registry.md) - Production private container registry with Harbor: HTTPS, LDAP auth, replication, Trivy scanning, backup
- [Harbor Deploy Script](scripts/bash/harbor/harbor-deploy.sh) - Automated Harbor installation with TLS, Docker Compose, and Trivy scanner
- [Harbor Health Check](scripts/bash/harbor/harbor-health-check.sh) - Verify Harbor containers, API, registry, disk usage, and Trivy scanner
- [Harbor Backup Script](scripts/bash/harbor/harbor-backup.sh) - Backup Harbor database, registry data, config, and Redis with retention
- [oci_registry_toolkit Usage](docs/how-to/oci_registry_toolkit.md)
- [OCI Registry Cheatsheet](../snippets/oci-registry-cheatsheet.md)
- [List Repositories](../scripts/bash/oci_registry_toolkit/registry/list-repos.sh)
- [List Tags](../scripts/bash/oci_registry_toolkit/registry/list-tags.sh)
- [Find Old Tags](../scripts/bash/oci_registry_toolkit/tags/find-old-tags.sh)
- [Keepalive Pull Plan](../scripts/bash/oci_registry_toolkit/tools/keepalive-pull-plan.sh)
- [Auth Diagnostics](../scripts/bash/oci_registry_toolkit/auth/check-auth.sh)

## CI/CD
- [ci_cd_toolkit Usage](docs/how-to/ci_cd_toolkit.md)
- [CI/CD Cheatsheet](../snippets/ci-cd-cheatsheet.md)
- [Lint Workflows](../scripts/bash/ci_cd_toolkit/github/lint-workflows.sh)
- [Validate Workflow](../scripts/bash/ci_cd_toolkit/github/validate-workflow.sh)
- [Pipeline Health](../scripts/bash/ci_cd_toolkit/github/pipeline-health.sh)
- [Check Action Updates](../scripts/bash/ci_cd_toolkit/github/check-action-updates.sh)
- [Generate Workflow](../scripts/bash/ci_cd_toolkit/github/generate-workflow.sh)

## Observability
- [observability_toolkit Usage](docs/how-to/observability_toolkit.md)
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
- [linux_toolkit Usage](docs/how-to/linux_toolkit.md)
- [AIDE File Integrity](docs/how-to/linux-aide-configuration.md) - AIDE file integrity monitoring deployment, configuration, and management
- [AIDE Deploy Script](../scripts/bash/linux_toolkit/security/aide-deploy.sh) - Automated AIDE deployment with --install, --init, --check, --update flags
- [Ansible Patch Management](docs/how-to/linux-ansible-patching.md) - Automated patching system with Ansible for Linux servers
- [Ansible Patch Script](scripts/bash/linux_toolkit/security/ansible-patch-management.sh) - Automated patch deployment with dry-run, scheduling, and reporting
- [Linux Cheatsheet](../snippets/linux-cheatsheet.md)
- [System Health Check](../scripts/bash/linux_toolkit/system/health-check.sh)
- [Disk Usage Analysis](../scripts/bash/linux_toolkit/system/disk-usage.sh) - With --dry-run, --threshold, and --help flags
- [Service Management](../scripts/bash/linux_toolkit/service/manage-services.sh)
- [Network Diagnostics](../scripts/bash/linux_toolkit/network/net-diag.sh)
- [Process Manager](../scripts/bash/linux_toolkit/process/process-manager.sh)
- [Security Check](../scripts/bash/linux_toolkit/security/security-check.sh)
- [OpenSCAP Hardening](docs/how-to/linux-openscap-hardening.md) - Automated compliance scanning and remediation with STIG/CIS profiles
- [OpenSCAP Hardening Script](../scripts/bash/linux_toolkit/security/openscap-hardening.sh) - Compliance automation with --dry-run, --auto-remediate, and --profile flags
- [Linux Incident Response](docs/how-to/linux-incident-response-automation.md) - Automated forensic evidence collection with chain of custody
- [Incident Response Script](../scripts/bash/linux_toolkit/security/forensics/incident-response.sh) - Forensics automation with --dry-run, --full-forensic, --case-id, and --examiner flags
- [Linux Monitoring with Prometheus](docs/how-to/linux-monitoring-prometheus.md) - Prometheus node_exporter setup with Grafana integration
- [Linux Monitoring Dashboard](docs/how-to/linux-monitoring-prometheus-node-exporter.md) - Comprehensive system monitoring with Prometheus node_exporter and Grafana dashboard
- [Node Exporter Setup Script](../scripts/bash/linux_toolkit/monitoring/node-exporter-setup.sh) - Automated installation with --dry-run, --version, and --port options
- [LDAP Server Setup](docs/how-to/linux-ldap-server.md) - LDAP authentication server setup with OpenLDAP
- [LDAP Setup Script](../scripts/bash/linux_toolkit/authentication/ldap-server-setup.sh) - Automated LDAP server installation with --dry-run, --domain, and user/group management options
- [linux_samba_file_server](docs/how-to/linux-samba.md) - Samba file server setup for Linux/Windows/macOS file sharing
- [samba_setup_script](scripts/bash/linux/samba-setup.sh) - Automated Samba file server deployment script
- [samba_enterprise_file_sharing](lab/mini-projects/samba-enterprise-file-sharing/README.md) - L7 production walkthrough: departmental shares, ACLs, AD integration, backups, monitoring, security hardening
- [linux_haproxy_load_balancer](docs/how-to/linux-haproxy-load-balancer.md) - HAProxy Layer 4/7 load balancer with SSL termination, health checks, and Prometheus metrics
- [haproxy_setup_script](../scripts/bash/linux_toolkit/loadbalancer/haproxy-setup.sh) - Automated HAProxy deployment with --dry-run, --backends, --domain, and --self-signed flags
- [linux_postgresql_database_server](lab/mini-projects/postgresql-database-server/README.md) - L7 production walkthrough: PostgreSQL 16 with replication, PgBouncer, backups, monitoring, security hardening
- [pg_setup_script](scripts/bash/linux_toolkit/database/pg-setup.sh) - Automated PostgreSQL 16 installation with config backup
- [pg_backup_script](scripts/bash/linux_toolkit/database/pg-backup.sh) - pg_dump backup with rotation and dry-run support
- [pg_healthcheck_script](scripts/bash/linux_toolkit/database/pg-healthcheck.sh) - PostgreSQL health check (replication lag, connections, disk, WAL archiver)
- [linux_centized_logging_syslog_ng_logstash](docs/how-to/linux-centralized-logging-syslog-ng-logstash.md) - Centralized logging pipeline with syslog-ng and Logstash
- [centralized_logging_setup_script](scripts/bash/linux_toolkit/setup-centralized-logging.sh) - Automated syslog-ng + Logstash + Elasticsearch deployment
- [syslog_ng_config_template](templates/syslog-ng/syslog-ng.conf) - Production syslog-ng configuration with JSON output and disk buffering
- [logstash_pipeline_template](templates/logstash/logstash.conf) - Logstash pipeline with GeoIP enrichment and Elasticsearch output

## Terraform
- [Terraform Workflow Script](../scripts/bash/terraform_toolkit/terraform-workflow.sh) - init/plan/apply with sensitive value handling and --dry-run support
- [K8s Provisioning with Terraform + Ansible](docs/how-to/k8s-terraform-ansible-provisioning/terraform/) - Terraform modules for VPC, control plane nodes, worker nodes, NLB, and IAM for self-managed Kubernetes on AWS
- [Terraform Module Composition and Workspaces](docs/how-to/terraform-module-composition-workspaces.md) - Production-ready project structure with reusable modules and workspace isolation
- [Terraform Project Starter](lab/mini-projects/terraform-project/) - Complete project with network, compute, and storage modules
- [Terraform CI/CD with Atlantis and GitOps](docs/how-to/terraform-atlantis-gitops.md) - Automated Terraform plan/apply from Git PRs with GitOps workflow
- [RDS PostgreSQL with Read Replicas](docs/how-to/terraform-rds-read-replicas.md) - Production RDS deployment with Multi-AZ, read replicas, encryption, and CloudWatch monitoring
- [RDS Deploy Script](scripts/bash/terraform_toolkit/rds-deploy.sh) - RDS deployment automation with plan/apply/destroy/verify/failover-test actions
- [Atlantis Setup Script](../scripts/bash/terraform_toolkit/atlantis/setup-atlantis.sh) - Docker-based Atlantis server setup with --dry-run support

## Ansible
- [ansible_toolkit Usage](docs/how-to/ansible_toolkit.md)
- [ansible_commands_reference](../snippets/ansible-commands.md) - Ansible ad-hoc commands for system administration, file operations, package management
- [CVE-2026-0598 Guide](docs/how-to/ansible-lightspeed-cve-2026-0598.md)
- [CVE-2025-14010 Audit](../scripts/bash/ansible_toolkit/security/cve-2025-14010-audit.sh) - Sensitive variable exposure audit with --path, --dry-run, --json-output flags
- [CVE-2026-0598 Audit](../scripts/bash/ansible_toolkit/security/cve-2026-0598-audit.sh) - Lightspeed auth bypass vulnerability scanner with --host, --token, --dry-run, --json-output flags
- [CVE-2026-24049 Hardening](../scripts/bash/ansible_toolkit/security/aap-cve-2026-24049-check.sh) - Wheel package privilege escalation vulnerability scanner with --host, --token, --dry-run, and --output flags
- [Vault Password Rotation](../scripts/bash/ansible_toolkit/security/vault-password-rotation.sh) - Rotate vault passwords across encrypted files with --dry-run and --execute flags
- [CVE-2026-0598 Hardening](../scripts/bash/ansible_toolkit/security/aap-cve-2026-0598-check.sh) - AAP Lightspeed auth bypass vulnerability scanner with --dry-run, --host, --token, and --output flags

## Vault
- [Vault Secure Deployment Guide](docs/how-to/vault-secure-deployment.md) - Comprehensive security hardening for Vault production deployments
- [Vault Seal/Unseal Troubleshooting](docs/how-to/vault-troubleshooting-seal-unseal.md) - Troubleshooting guide for seal/unseal failures and recovery
- [CVE-2025-6000 Hardening](../scripts/bash/vault_toolkit/security/cve-2025-6000.sh) - Vault plugin directory RCE vulnerability scanner with --remediate and --dry-run flags
- [CVE-2025-5999 Hardening](../scripts/bash/vault_toolkit/security/cve-2025-5999.sh) - Vault privilege escalation vulnerability scanner with --remediate and --dry-run flags
- [CVE-2025-11621 Hardening](../scripts/bash/vault_toolkit/security/cve-2025-11621.sh) - Vault AWS Auth bypass vulnerability scanner with --dry-run and --json-output flags
- [CVE-2025-6037 Hardening](../scripts/bash/vault_toolkit/security/cve-2025-6037.sh) - TLS certificate auth validation bypass scanner with --dry-run and --verbose flags
- [CVE-2025-6013 Hardening](../scripts/bash/vault_toolkit/security/cve-2025-6013.sh) - LDAP MFA enforcement bypass scanner with --dry-run and --json-output flags

## Docker
- [Docker Security Best Practices](docs/how-to/docker-security.md) - Comprehensive security hardening guide for Docker (image security, runtime security, network security, secrets management)
- [docker_cli_snippets](../snippets/docker-commands.md) - Docker CLI command snippets for container and image management
- [CVE-2026-28400 Hardening](../scripts/bash/docker_toolkit/security/cve-2026-28400.sh) - Docker Model Runner privilege escalation vulnerability scanner with --remediate and --dry-run flags
- [docker_image_cleanup_script](scripts/bash/docker_toolkit/docker-image-cleanup.sh) - Docker image cleanup with dry-run support, age filtering, and space savings calculation

## Helm
- [Helm Security Scanning Guide](docs/how-to/helm-security-scanning.md) - Comprehensive security hardening for Helm charts (Trivy, kube-score, Checkov, Kubescape)
- [Bash Scripts](../scripts/bash/)
- [Python Scripts](../scripts/python/)
- [PowerShell Scripts](../scripts/powershell/)
- [Script Guidelines](../scripts/README.md)
- [CVE-2025-53547 Hardening](../scripts/bash/helm_toolkit/security/cve-2025-53547-harden.sh) - Helm Chart.yaml code injection vulnerability scanner with --check-version, --dry-run, and --verbose flags

## Templates
- [Kubernetes Templates](../templates/k8s/)
- [Docker Templates](../templates/docker/)
- [Terraform Templates](../templates/terraform/)
- [Project Starters](../templates/project-starters/)

## Reference
- [Glossary](../00_index/glossary.md)
- [Runbooks](../docs/runbooks/)
- [Concepts](../docs/concepts/)
- [Git Version Control Mental Model](../docs/concepts/git-version-control-mental-model.md) - Architecture, repositories, branching, remote operations
