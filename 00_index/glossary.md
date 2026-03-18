# Glossary

## Terms

**dry-run**: A mode where operations are simulated without making actual changes. Used for validation and safety before executing potentially destructive actions.

**guardrails**: Safety checks and constraints built into scripts to prevent unintended modifications or destructive operations.

**kubectl**: Command-line interface for running commands against Kubernetes clusters.

**OCI registry**: Open Container Initiative compliant container registry (e.g., Docker Hub, GitHub Container Registry, private registries).

**SRE**: Site Reliability Engineering - discipline that applies software engineering practices to infrastructure and operations.

**toolkit**: A curated collection of scripts, documentation, and templates focused on a specific domain (e.g., k8s_toolkit).

**Consumer lag (Kafka)**: Difference between the latest offset and consumer's committed offset.

**Drain (Kubernetes)**: Mark a node unschedulable and evict all pods from it.

**KRaft**: Kafka's ZooKeeper-less mode using KRaft (Kafka Raft) consensus protocol.

**Static membership (Kafka)**: Kafka consumer feature that maintains consistent group membership across restarts using group.instance.id.

**JAAS**: Java Authentication and Authorization Service - used for Kafka Connect SASL authentication.

**bound_principal_iam (Vault)**: IAM principal associated with Vault AWS auth method for authentication.

**Chart.yaml**: Helm chart manifest file containing chart metadata and dependencies.

**Model Runner (Docker)**: Docker feature for running local AI models with the docker model command.

**no_log (Ansible)**: Ansible directive that prevents task output from being logged for security.

**Shamir key (Vault)**: Vault's default seal mechanism that splits the unseal key into multiple shares using Shamir's secret sharing algorithm.

**Auto-unseal (Vault)**: Vault feature that automatically unseals using a trusted cloud KMS (AWS KMS, Azure Key Vault, GCP Cloud KMS) or HSM.

**HSM (Hardware Security Module)**: Physical device that provides secure key storage and cryptographic operations.

**PKCS#11**: Standard interface for communicating with cryptographic devices like HSMs.

**Recovery mode (Vault)**: Vault operation mode used for recovery when standard unseal is not possible.

**Trivy**: Open-source vulnerability scanner for containers and Kubernetes.

**Kubescape**: Kubernetes security platform for scanning clusters and manifests.

**Checkov**: Infrastructure as Code security scanner that checks Terraform, CloudFormation, and Kubernetes manifests.

**Falco**: Cloud-native runtime security tool that detects anomalous activity in containers and Kubernetes.

## Acronyms

**CI/CD** - Continuous Integration/Continuous Deployment
**IaaS** - Infrastructure as a Service
**PaaS** - Platform as a Service
**SaaS** - Software as a Service
**VCS** - Version Control System
**RCE** - Remote Code Execution
**DoS** - Denial of Service
**SSRF** - Server-Side Request Forgery
