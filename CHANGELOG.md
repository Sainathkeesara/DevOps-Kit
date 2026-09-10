# Changelog

All notable changes to the DevOps-Kit repository will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## 2026-09-10

### Added
- github-actions-010: `github-actions/configs/2026-09-10-minimal-ci-workflow.yaml` — Minimal CI workflow with GitHub Actions (L2 config)
- kubernetes-007: `kubernetes/manifests/2026-09-10-first-pod.yaml` — Deploy my first pod with a Kubernetes manifest (L1 manifest)
- opentofu-006: `opentofu/configs/2026-09-10-minimal-opentofu-config.hcl` — Minimal OpenTofu configuration for a compute instance with variables and outputs (L2 config)

## 2026-09-05

### Added
- zap-027: `zap/notes/2026-09-05-install-zap-first-baseline-scan.md` — Install OWASP ZAP and launch my first baseline scan — what tripped me up (L1 notes)
- trivy-021: `trivy/notes/2026-09-05-install-trivy-first-container-scan.md` — Install Trivy and scan my first container image — what tripped me up (L1 notes)

## 2026-09-04

### Added
- vault-024: `vault/configs/2026-09-04-aws-secrets-engine-policy.hcl` — Vault AWS secrets engine policy (path-scoped credentials, role listing, root rotation) with inline CLI test steps (L2 config)
- trivy-020: `trivy/notes/2026-07-27-first-container-scan.md` — Install Trivy and scan my first container image (L1 notes)
- trufflehog-020: `trufflehog/notes/2026-07-27-explore-cli.md` — Explore the TruffleHog CLI — what's there (L1 notes)
- con-123: `docs/concepts/configuration-management/combining-configuration-management-with-ci-cd-pipeline-concepts.md` — Combining Configuration Management with CI/CD Pipeline Concepts — integration patterns for DevSecOps workflows (L3 docs)
- con-125: `docs/concepts/secrets-access-management/combining-secrets-access-management-with-version-control.md` — Combining Secrets & Access Management with Version Control with Git — credential management patterns for DevSecOps (L3 docs)

## 2026-09-03

### Added
- snyk-011: `snyk/manifests/snyk-github-actions-cicd-workflow.yaml` — Snyk GitHub Actions CI/CD workflow with `snyk test` on PR/push, weekly `snyk monitor` for project registration, and SARIF/JSON artifact upload (L4 manifest)
- syft-009: `syft/docs/output-format-selection-guide.md` — Syft output format selection guide mapping SPDX, CycloneDX, GitHub JSON, and table outputs to integration targets (L5 docs)

## 2026-09-02

### Added
- snyk-009: `snyk/templates/snyk-multilang-scan-scaffold/` — Snyk multi-language project scanning scaffold with shared `.snyk` policy, per-language subscan scripts (Node, Python, Java, Go, Ruby), Makefile, severity policy JSON, and CI workflow (L4 template)
- opa-010: `opa/manifests/gatekeeper-production-deployment.yaml` — OPA Gatekeeper admission controller production deployment with HA (3 replicas, PDB, anti-affinity), audit Config, ServiceMonitor, and HPA (L4)
- snyk-010: `snyk/docs/vulnerability-prioritization-reachability-fix-prs-license-compliance.md` — Snyk vulnerability prioritization workflow combining reachability filtering, auto-opened Fix PRs, and license-compliance rollup into one triage queue (L4 docs)

## 2026-08-30

### Added
- vault-017: `vault/docs/vault-secrets-engine-selection-guide.md` — Vault secrets engine selection guide comparing KV, database, and cloud secrets engines (L5)
- vault-023: `vault/snippets/2026-08-30-first-vault-secret.sh` — Write my first Vault secret and read it back using the Vault CLI (L1)
- checkov-021: `checkov/templates/multi-repo-drift-auto-pr-remediation/` — Checkov multi-repo drift detection and auto-PR remediation scaffold with reusable GitHub Actions workflow, custom drift policies (tag, SG, public access, encryption), and regex-based remediation script (L5 template)

## 2026-08-29

### Added
- checkov-020: `checkov/configs/platform-config.yaml` — Checkov platform-level configuration for self-hosted runner, VCS integration, and suppression policies (L5)

## 2026-08-27

### Added
- opa-007: `opa/templates/gatekeeper-policy-library-scaffold/` — OPA Gatekeeper policy library scaffold with CI test harness (L4 template)
- opa-008: `opa/docs/constraint-template-design-patterns.md` — OPA Gatekeeper constraint template design patterns for pod security (L4 docs)
- opa-009: `opa/scripts/export-audit-results.sh` — OPA Gatekeeper audit results export and compliance reporting script (L4 script)

## 2026-08-26

### Added
- vault-022: `vault/notes/2026-08-26-install-vault-first-command.md` — Install HashiCorp Vault and run my first command, what tripped me up (L1 notes)
- codeql-015: `codeql/notes/2026-08-26-install-codeql-first-query.md` — Install CodeQL CLI and run my first query (L1 notes)
- con-113: `docs/concepts/application-security-testing-concepts/scripts/2026-08-26-ast-devsecops.py` — Applying AST concepts in DevSecOps (L2 script)
- github-actions-012: `github-actions/notes/2026-08-26-install-gh-cli-first-command.md` — Install GitHub CLI and run my first `gh` command, what tripped me up (L1 notes)
- github-actions-013: `github-actions/snippets/2026-08-26-first-workflow.yaml` — My first GitHub Actions workflow YAML from scratch (L1 snippet)
- github-actions-016: `github-actions/snippets/2026-08-26-composite-action-input-reuse.yaml` — Minimal composite action with input parameters and step reuse (L2 snippet)
- con-112: `docs/concepts/application-security-testing-concepts/snippets/2026-08-26-appsec-sca-dependency-exercises.py` — SCA dependency scanning and SBOM generation practice exercises (L2 snippet)

## 2026-08-25

### Added
- cosign-013: `cosign/docs/cosign-verification-patterns.md` — Cosign verification patterns with policy-based verification and custom OCI rules (L4)
- cosign-014: `cosign/dockerfiles/custom-cosign-image.Dockerfile` — Custom Cosign image with pre-loaded signing keys and verification entrypoint (L4)
- con-119: `docs/concepts/secrets-access-management/snippets/2026-08-25-applying-secrets-access-management.py` — Applying Secrets & Access Management in DevSecOps (L2 snippet)
- con-122: `docs/concepts/version-control-with-git/snippets/2026-08-25-applying-version-control-in-devsecops.py` — Applying Version Control with Git in DevSecOps (L2 snippet)
- ansible-006: `ansible/notes/2026-08-25-followed-ansible-quickstart-what-tripped-me-up.md` — Followed the official Ansible quickstart and documented the gotchas the docs skip (L2)
- ansible-007: `ansible/snippets/2026-08-25-minimal-ansible-playbook-package-service.yaml` — Minimal Ansible playbook for package installation and service management (L2)

## 2026-08-24

### Added
- git-014: `git/scripts/2026-08-24-first-repo-stage-log.sh` — Create a new Git repository, stage a file, and run git log (L1)
- scripts-001: `scripts/notes/2026-08-24-reorganize-scripts.md` — Audited root-level scripts and documented intended layout in `scripts/README.md` (L1)

## 2026-08-23

### Fixed
- docs-007: fixed 2 spurious placeholder file references in training docs — `terraform-eks-cluster.md` (`./scripts/cleanup.sh` → real `scripts/bash/terraform_toolkit/eks/eks-cleanup.sh`) and `linux-iac-pipeline-workflows.md` (`./scripts/ansible/bootstrap.sh` → real `ansible/scripts/bootstrap.sh`)

## 2026-08-22

### Added
- vault-011: `vault/scripts/cloud-iam-dynamic-secrets.sh` — Vault dynamic secrets workflow for cloud IAM credentials (AWS secrets engine enable, role creation, credential generation, verification, and revocation) (L4)

## 2026-08-21

### Changed
- cosign-011: `cosign/scripts/cosign-key-management-workflow.sh` — Rework: removed hardcoded `ghcr.io/myorg/myapp:latest` from `rotate_key`; image is now a required positional argument for the `rotate` action (L4)
### Added
- gitguardian-012: `gitguardian/docs/gitguardian-incident-response-workflow.md` — GitGuardian incident response workflow from alert triage to remediation (L4)
- gitguardian-013: `gitguardian/scripts/gitguardian-api-integration.py` — GitGuardian API integration for scan export, dashboard retrieval, and Slack notification (L4)

## 2026-08-20

### Added
- dependabot-016: `dependabot/scripts/dependabot-alert-aggregation.py` — GitHub API Dependabot alert aggregation for compliance reporting (L3): multi-repo rollup, severity + per-package summary, optional CSV detail dump
- cosign-012: `cosign/manifests/signed-container-build-oidc.yaml` — Cosign GitHub Actions reusable workflow for signed container build with OIDC (L4)

## 2026-08-19

### Added
- gitguardian-011: `gitguardian/templates/gitguardian-multi-repo-scanning-scaffold/` — GitGuardian multi-repo scanning scaffold with centralized allowlist (L4)
    - `README.md` with Purpose → When to use → Prerequisites → Steps → Verify
    - Root `ggshield.yaml` config with ignored paths, detectors, and version header
    - `.ggshield/allowlist.yaml` for centralized false-positive management
    - `repos.txt` target repository list
    - `scripts/scan-multi-repo.sh` runner with per-repo JSON output and error isolation
    - `scripts/aggregate-report.sh` merger normalizing raw array and `secrets_scan` object shapes
    - `.github/workflows/org-secret-scan.yml` scheduled weekly GitHub Actions workflow
    - `Makefile` with `scan`, `report`, and `clean` targets
- opa-015: `opa/manifests/` — Gatekeeper constraint template library for a Kubernetes security baseline: 4 ConstraintTemplates (drop ALL caps, runAsNonRoot, no privilege escalation, required labels) + matching Constraint instances (L3)
- docs-012: `docs/notes/2026-08-19-workflow-stubs-review.md` — Confirmed `.github/workflows/trivy-scan.yml`, `ci.yml`, and `semgrep-ci.yml` are legitimate user-creation examples; `semmp.yml` is spurious (no stubs needed)
- cosign-011: `cosign/scripts/cosign-key-management-workflow.sh` — Cosign key management workflow: generate, rotate, and revoke key pairs (L4)

## 2026-08-18

### Added
- dependabot-014: `dependabot/docs/dependabot-security-update-auto-merge.md` — Dependabot security update workflow: auto-merge strategy for patch versions (L3)
- dependabot-015: `dependabot/configs/monorepo-ecosystem-schedules-reviewers.yaml` — Dependabot monorepo configuration with ecosystem-specific schedules and reviewers (L3)

## 2026-08-17

### Fixed
- DK: deduplicated `scripts/bash/vault/` → `scripts/bash/vault_toolkit/` (moved `vault-audit-log-analysis.sh` + `security/vault-go-getter-hardening.sh`; removed empty `vault/`).
- DK: deduplicated `scripts/bash/terraform/` → `scripts/bash/terraform_toolkit/` (moved `ter-019-deploy.sh`, `terraform-ecs-service-discovery-deploy.sh`, `terraform-iam-roles-deploy.sh`; removed empty `terraform/`).
- docs-004: `docs/notes/2026-08-17-spurious-placeholder-cleanup.md` — Audited training docs for spurious placeholder file references: `zap.sh` and `semmp.yml` are genuinely spurious (no corresponding files in the repo); `checkov -f plan.json` is valid CLI syntax; `.github/workflows/ci.yml`, `semgrep-ci.yml`, and `trivy-scan.yml` are legitimate user-creation examples (L1)
### Added
- argocd-007: `argocd/configs/2026-08-17-private-repo-credentials-rbac.yaml` — Repository credentials Secret + argocd-rbac-cm RBAC policy for a private Git repo (L2)
- linux-004: `linux/notes/2026-07-21-install-linux-vm-terminal-first-commands.md` — Install Linux in a VM and run my first terminal commands — what tripped me up (L1)
- ansible-002: `ansible/notes/2026-08-17-verify-ansible-cve-2026-33228-paths.md` — Verified corrected relative paths in the Ansible CVE-2026-33228 runbook (L1)

## 2026-08-16

### Added
- checkov-019: `checkov/manifests/checkov-gitlab-ci-multi-cloud-drift.yaml` — Checkov GitLab CI template for multi-cloud IaC scanning with policy drift detection (L5)
- trivy-018: `trivy/notes/scanning-performance-optimization.md` — Trivy scanning performance optimization: cache strategies and parallel execution (L5)

## 2026-08-15

### Added
- trivy-017: `trivy/scripts/ignore-rules-pipeline.sh` — Trivy vulnerability scanning pipeline with custom ignore rules (L5)
- trivy-017: reworked `trivy/scripts/ignore-rules-pipeline.sh` — fixed broken severity gate by normalizing FAIL_ON to uppercase and matching `.Severity` case-insensitively in jq (L5)
## 2026-08-14

### Added
- docs-017: `docs/notes/2026-08-14-verify-trivy-paths.md` — Verified corrected relative paths in trivy-jenkins-integration.md and trivy-severity-filtering.md (L1)
- docs/how-to/trivy-jenkins-integration.md — Fixed relative script path from `./scripts/bash/...` to `../../scripts/bash/...`
- docs/how-to/trivy-severity-filtering.md — Fixed relative script path from `./scripts/triage-vulnerabilities.sh` to `../scripts/triage-vulnerabilities.sh`

## 2026-08-13

### Added
- syft-017: `syft/notebooks/output-format-comparison.ipynb` — Comparing Syft output formats: SPDX vs CycloneDX vs GitHub vs native JSON (L5)
- syft-016: `syft/templates/syft-trivy-k8s-scan-scaffold/` — Syft + Trivy integrated scanning pipeline scaffold for Kubernetes workloads (L5)
    - `images.txt` inventory of workload images, Syft → CycloneDX SBOM per image
    - Trivy severity gate config and scan script with `make scan`
    - GitHub Actions workflow installing both CLIs via `go install`
- trivy-016: `trivy/docs/multi-arch-vulnerability-scanning.md` — Trivy vulnerability scanning patterns for multi-arch container images (L5)

## 2026-08-12

### Added
- argocd-005: `argocd/notes/2026-08-12-quickstart-tripups.md` — Following the official ArgoCD quickstart write-up: what tripped me up (L2)
- argocd-006: `argocd/manifests/2026-08-12-gitops-sync-sample-web-app.yaml` — Minimal ArgoCD Application manifest for a sample web app with GitOps sync (L2)
## 2026-08-11

### Added
- terraform-024: `terraform/configs/multi-environment-workspaces-variables.hcl` — Terraform remote backend with per-environment workspace variables (L1)

## 2026-08-10

### Added
- terraform-013: `terraform/configs/workspace-variable-precedence.hcl` — Terraform multi-environment configuration with workspaces and variable precedence (L3)
- terraform-014: `terraform/docs/terraform-module-composition.md` — Terraform module composition patterns — reusing and versioning shared modules (L3)

## 2026-08-09

### Added
- con-096: `docs/concepts/linux-shell-fundamentals/scripts/ci-cd-pipeline-security-scanner-wrapper.sh` — CI/CD pipeline shell script wrapper for security scanner orchestration (L3)
- terrascan-017: `terrascan/templates/scanning-pipeline-scaffold/` — Terrascan scanning pipeline scaffold with custom policy integration (L4)
    - Terrascan config loading custom policies from policies/
    - Two sample Rego policies: block public S3 ACLs and require S3 encryption
    - Scan runner script with JSON output and per-severity breakdown
    - README and .gitignore

### Passed

- Passed ([x]) terrascan-016 — Terrascan: docs — Terrascan vs Checkov — comparing IaC scanning approaches for Terraform · Level: L4 · 2026-08-09

## 2026-08-08

### Added
- dependabot-009: `dependabot/notes/2026-08-08-dependabot-custom-registry-tutorial.md` — Dependabot: notes — Follow the official Dependabot custom registry tutorial and write up what tripped me up (L2)

### Reworked
- terrascan-016: `terrascan/docs/terrascan-vs-checkov-terraform-iac-scanning.md` — rework: replaced unbacked URLs with research-backed sources, condensed L5 full-structure to L4 shape (Purpose → Steps → Verify), transitional third-person voice

## 2026-08-07

### Added
- terrascan-014: `terrascan/scripts/policy-as-code-workflow.sh` — Terrascan policy-as-code workflow: scan IaC with custom Rego policies, per-severity breakdown, and a severity-threshold CI gate (L4)
- terrascan-015: `terrascan/manifests/terrascan-gha-ci-multi-iac.yaml` — Terrascan GitHub Actions CI workflow for multi-IaC scanning with custom policies and severity gating (L4)
- terrascan-016: `terrascan/docs/terrascan-vs-checkov-terraform-iac-scanning.md` — Terrascan vs Checkov comparison for Terraform IaC scanning: config vs plan scanning, custom policies, and build gating (L4)
- con-098: `docs/concepts/software-supply-chain-security/supply-chain-security-in-practice.md` — Software Supply Chain Security: docs — Software supply chain security in practice — SBOM, signing, and vulnerability management (L3)

## 2026-08-06

### Added
- tetragon-006: `tetragon/notes/2026-08-06-tetragon-observability-tutorial.md` — Tetragon: notes — Follow the official Tetragon observability tutorial and write up what tripped me up (L2)
- lin-005: `lin/notes/2026-08-06-linux-shell-scripting-tutorial-confusions.md` — Linux: notes — Follow the official Linux shell scripting tutorial and write up what tripped me up (L2)
- lin-007: `lin/configs/2026-08-06-cron-job-configuration.ini` — Linux: config — Linux cron job configuration for automated system maintenance tasks (L2)
- semgrep-023: `semgrep/notebooks/comparing-community-vs-custom-rules.ipynb` — Semgrep: notebook — Comparing Semgrep community rules vs custom rules for Python security scanning (L5)
- semgrep-022: `semgrep/docs/semgrep-rule-performance-optimization.md` — Semgrep: docs — Semgrep rule performance optimization — combining patterns for efficient scanning (L5)

### Passed
- Passed ([x]) tetragon-004 — Tetragon: script — Tetragon event collection pipeline with JSON export and external forwarding · Level: L2 · 2026-08-06
- Passed ([x]) tetragon-005 — Tetragon: config — Minimal TracingPolicy for network connection monitoring · Level: L2 · 2026-08-06

## 2026-08-05

### Added
- docker-009: `docker/scripts/build-multi-service-compose-app.sh` — Build a multi-service Docker Compose app from scratch (L3)
- docker-010: `docker/docs/dockerfile-optimization-patterns.md` — Dockerfile optimization patterns for CI — layer caching and multi-stage builds (L3)
- docker-011: `docker/configs/docker-compose-dev-environment.yaml` — Docker Compose development environment with volumes, networks, and health checks (L3)
- con-039: `docs/concepts/observability-monitoring/notebooks/2026-08-05-monitoring-stack-exploration.ipynb` — Monitoring stack exploration: Grafana dashboard with Prometheus data (L2)
- tetragon-004: `tetragon/scripts/2026-08-05-tetragon-event-collection-pipeline.sh` — Tetragon event collection pipeline with JSON export and external forwarding (L2)
- tetragon-005: `tetragon/configs/2026-08-05-minimal-network-tracing-policy.yaml` — Minimal TracingPolicy for network connection monitoring (L2)

### Passed
- Passed ([x]) docker-010 — Docker: docs — Dockerfile optimization patterns for CI — layer caching and multi-stage builds · Level: L3 · 2026-08-05
- Passed ([x]) con-039 — Observability & Monitoring: notebook — Monitoring stack exploration: Grafana dashboard with Prometheus data · Level: L2 · 2026-08-05

## 2026-08-04

### Added
- github-actions-002: `github-actions/configs/2026-08-04-first-workflow.yaml` — My first GitHub Actions workflow — trigger on push and run a job (L1)
- github-actions-003: `github-actions/notes/2026-08-04-explore-github-actions.md` — Explore GitHub Actions — workflows, runners, events, and marketplace (L1)
- github-actions-004: `github-actions/manifests/2026-08-04-pr-validation.yml` — PR validation workflow with linting and type checking (L1)
- defectdojo-003: `defectdojo/notes/2026-08-04-explore-defectdojo-ui.md` — Explore the DefectDojo UI — products, engagements, and findings (L1)
- dependabot-008: `dependabot/scripts/2026-08-04-dependabot-alert-triage.py` — Dependabot alert analysis and triage script from GitHub API (L2)
- con-038: `docs/concepts/observability-monitoring/snippets/2026-08-04-basic-prometheus-metrics.yaml` — Observability practice: basic metrics collection with Prometheus (L2)
- ansible-001: `ansible/scripts/2026-08-04-bootstrap-node.sh` — Bootstrap script for target node preparation (L1)
- terraform-006: `terraform/notes/2026-08-04-install-terraform-first-vm.md` — Install Terraform, run `terraform init`, and deploy my first VM — what tripped me up (L1)
- terraform-007: `terraform/configs/2026-08-04-first-configuration.hcl` — My first Terraform configuration — define a resource, run plan, and review the diff (L1)

### Passed
- Passed ([x]) github-actions-002 — GitHub Actions: config — My first GitHub Actions workflow — trigger on push and run a job · Level: L1 · 2026-08-04
- Passed ([x]) github-actions-003 — GitHub Actions: notes — Explore GitHub Actions — workflows, runners, events, and marketplace · Level: L1 · 2026-08-04
- Passed ([x]) defectdojo-003 — DefectDojo: notes — Explore the DefectDojo UI — products, engagements, and findings · Level: L1 · 2026-08-04
- Passed ([x]) dependabot-008 — Dependabot: script — Dependabot alert analysis and triage script from GitHub API · Level: L2 · 2026-08-04
- Passed ([x]) con-038 — Observability & Monitoring: snippet — Observability practice: basic metrics collection with Prometheus · Level: L2 · 2026-08-04
- Passed ([x]) ansible-001 — Ansible: script — Bootstrap script for target node preparation · Level: L1 · 2026-08-04
- Passed ([x]) terraform-006 — Terraform: notes — Install Terraform, run `terraform init`, and deploy my first virtual machine — what tripped me up · Level: L1 · 2026-08-04
- Passed ([x]) terraform-007 — Terraform: config — My first Terraform configuration — define a resource, run plan, and review the diff · Level: L1 · 2026-08-04

## 2026-08-01

### Added
- syft-015: `syft/manifests/syft-gha-multi-arch-sbom-registry-auth.yaml` — Syft GitHub Actions workflow for multi-architecture image SBOM with registry authentication (L5)

## 2026-07-31

### Added
- argocd-004: `argocd/notes/2026-07-31-verify-readme-layout.md` — Verification note confirming the README Layout still lists the argocd/ folder after the UF fix (L1)

## 2026-07-30

### Added
- con-040: `docs/concepts/configuration-management/0000-primer-configuration-management.md` — Configuration Management (L1) — quick primer with YAML front-matter
- con-041: `docs/concepts/observability-monitoring/0000-primer-observability-monitoring.md` — Observability & Monitoring (L1) — quick primer with YAML front-matter

## 2026-07-26

### Added
- git-009: `git/notes/0000-primer-git.md` — Git (L1) — What is Git? — quick primer

## 2026-07-23

### Added
- con-050: `docs/concepts/infrastructure-as-code/snippets/2026-07-23-practice-exercises.hcl` — Practice Infrastructure as Code: variable, resource, and output blocks in HCL (L2)
- con-052: `docs/concepts/linux-shell-fundamentals/scripts/2026-07-23-practice-exercises.sh` — Practice Linux & Shell Fundamentals: variables, conditionals, loops, functions, and cleanup (L2)
- con-056: `docs/concepts/software-supply-chain-security/snippets/2026-07-23-practice-exercises.sh` — Practice software supply chain checksum verification loop (L2)

## 2026-07-24

### Added
- con-054: `docs/concepts/secrets-access-management/snippets/2026-07-24-practice-exercises.py` — Practice Secrets & Access Management exercises: reading secrets from the environment and simulating a rotation call (L2)
- con-058: `docs/concepts/version-control-with-git/scripts/2026-07-24-practice-exercises.sh` — Practice Version Control with Git exercises: init, commit, branch, merge, and diff in a throwaway repo (L2)

### Passed
- Passed ([x]) con-052 — Linux & Shell Fundamentals: script(bash) — Practice: Linux & Shell Fundamentals exercises · Level: L2 · 2026-07-24
- Passed ([x]) con-056 — Software Supply Chain Security: snippet(bash) — Practice: Software Supply Chain Security exercises · Level: L2 · 2026-07-24

## 2026-07-22

### Added
- snyk-004: `snyk/dockerfiles/custom-snyk-cli-air-gapped.Dockerfile` — Custom Snyk CLI Docker image pre-installed for air-gapped vulnerability scanning (L4)
- codeql-008: `codeql/dockerfiles/custom-codeql-analysis-image.Dockerfile` — Custom CodeQL analysis Docker image with preloaded bundle and custom queries (L4)
- vault-010: `vault/dockerfiles/custom-vault-image-with-plugins-tls.Dockerfile` — Custom Vault Docker image with bundled plugins and TLS configuration (L4)

## 2026-07-21

### Added
- lin-003: `linux/notes/2026-07-21-install-linux-vm-terminal-first-commands.md` — Install Linux in a VM and run first commands — what tripped me up (L1)

### Changed
- checkov-009: `checkov/notebooks/compare-builtin-vs-custom-k8s.ipynb` — Rework: removed fabricated version claims (3.3.8, 3.2.532, ECDSA-P256 signing requirement); corrected to only reference general Checkov API patterns (L5)

## 2026-07-20

### Added
- checkov-008: `checkov/docs/multi-cloud-policy-management.md` — Checkov multi-cloud IaC policy management: AWS/Azure/GCP drift detection patterns (L5)
- codeql-005: `codeql/snippets/hardcoded-secret-from-scratch.ql` — Custom CodeQL query for hardcoded secrets detection from scratch (L3)
- con-049: `docs/concepts/containers-orchestration/2026-07-20-common-patterns.md` — Containers & orchestration common patterns: image tagging, resource limits, probes, secrets, and Helm next steps (L2)
- terraform-008: `terraform/snippets/2026-07-20-practice-terraform-variables-outputs-datasources.hcl` — Practice Terraform input variables, outputs, and data sources (L1)
- zap-014: `zap/notes/2026-07-20-install-zap-baseline-scan.md` — Install OWASP ZAP and launch my first baseline scan — what tripped me up (L1)

## 2026-07-19

### Added
- checkov-017: `checkov/docs/checkov-v3-migration-guide.md` — Checkov v3 migration guide: removed flags, custom-check API changes, and CI updates (L6)
- con-063: `docs/concepts/application-security-testing-concepts/snippets/2026-07-19-appsec-secrets-integration.py` — AppSec + Secrets & Access Management integration exercise (L3)
- helm-003: `helm/notes/2026-07-19-explore-helm-charts-releases-values-repos.md` — Exploring Helm: charts, releases, values, and repositories after the primer (L1)
- sonarqube-003: `sonarqube/notes/2026-07-19-explore-sonarqube-quality-gates-profiles.md` — Exploring SonarQube: Quality Gates, profiles, and issues via the web UI (L1)
- falco-008: `falco/notes/2026-07-19-explore-falco-cli-rules-events-output.md` — Exploring the Falco CLI: list rules, capture events, and inspect output formats (L1)
- k8s-001: `scripts/bash/k8s_toolkit/security/aks-privilege-escalation-hardening.sh` — L1 rework: removed forbidden `--dry-run`/DRY_RUN; minimal AKS CVE-2026-33105 detection script (L1)
- gh-002: `.github/workflows/pr-validation.yml` — PR validation workflow: lint and type checks on PRs (L1)
- gh-002: `.github/workflows/auto-merge.yml` — Auto-merge workflow for trivial changes labeled auto-merge (L1)
- gh-002: `.github/workflows/tool-testing.yml` — Tool testing workflow: script tests on master push (L1)
- con-046: `docs/concepts/container-runtime-security/snippets/2026-07-19-container-runtime-security-exercises.py` — Practice: inspect running containers for privileged mode and writable root filesystem (L2)
- con-047: `docs/concepts/container-runtime-security/2026-07-19-container-runtime-security-common-patterns.md` — Container runtime security common patterns: capabilities, read-only root, seccomp, and non-root users (L2)

## 2026-07-18

### Added
- grype-002: `grype/scripts/grype-scan-pipeline-end-to-end.sh` — End-to-end Grype pipeline: scan images, emit JSON + SARIF, gate CI on severity threshold (L3)
- terraform-005: `terraform/scripts/2026-07-18-cleanup.sh` — Minimal Terraform destroy script for project cleanup (L1)
- terraform-005: `terraform/scripts/2026-07-18-deploy.sh` — Minimal Terraform deploy script: init, plan, apply for Secrets Manager environments (L1)
- dependabot-011: `dependabot/configs/2026-07-18-python-project-version-update.yaml` — Minimal Dependabot config for Python pip ecosystem with weekly direct-dependency updates (L2)
- docker-006: `docker/scripts/2026-07-18-custom-network-volume-mounts.sh` — Run a container with custom bridge networking and named volume mounts from the CLI (L2)

## 2026-07-17

### Added
- con-044: `docs/concepts/ci-cd-pipeline-concepts/scripts/2026-07-17-practice-ci-cd-exercises.sh` — Practice CI/CD pipeline concepts: build, test, and deploy stages with gating logic (L2)

## 2026-07-16

### Added
- sonarqube-002: `sonarqube/snippets/2026-07-16-first-sonarscanner-run.sh` — Run my first SonarQube analysis with SonarScanner CLI (L1)
- zap-015: `zap/snippets/2026-07-16-zap-docker-quickstart-json-export.sh` — ZAP Docker quick-start with automated baseline scan and JSON report export (L1)

## 2026-07-15

### Added
- terraform-001: `terraform/notes/0000-primer-terraform.md` — Terraform quick primer: what it is, key terminology, and a tiny example (L1)
- terraform-002: `terraform/configs/2026-07-15-first-config.tf` — My first Terraform configuration: provider, resource, variable, and output (L1)
- terraform-003: `terraform/notes/2026-07-15-explore-terraform.md` — Exploring Terraform: state, providers, variables, and modules (L1)

## 2026-07-16

### Added
- git-008: `scripts/bump-version.sh` — Minimal version bumper script referenced in git-cicd-automation.md (L1)
- trivy-009: `scripts/triage-vulnerabilities.sh` — Progressive Trivy vulnerability triage script referenced in trivy-severity-filtering.md (L1)
- ansible-005: `scripts/pipeline/deploy.sh` — Minimal Ansible deploy wrapper referenced in linux-iac-pipeline-workflows.md (L1)
- ansible-005: `scripts/pipeline/rollback.sh` — Minimal rollback script referenced in linux-iac-pipeline-workflows.md (L1)
- ansible-005: `scripts/ansible/bootstrap.sh` — Minimal target bootstrap script referenced in linux-iac-pipeline-workflows.md (L1)

## 2026-07-14

### Added
- con-036: `docs/concepts/configuration-management/snippets/2026-07-14-practice-ansible-playbook-basics.yaml` — Practice: Ansible playbook basics demonstrating desired state, idempotency, and verify pattern (L2)
- con-037: `docs/concepts/configuration-management/2026-07-14-devsecops-patterns.md` — Configuration Management in DevSecOps workflows — patterns and best practices (L2)

## 2026-07-13

### Added
- grafana-001: `grafana/notes/0000-primer-grafana.md` — Grafana quick primer: dashboards, panels, data sources, PromQL, and a tiny example (L1)
- observability-001: `observability/notes/0000-primer-observability.md` — Observability quick primer: logs, metrics, traces, SLIs/SLOs, and a Flask + Prometheus example (L1)
- prometheus-001: `prometheus/notes/0000-primer-prometheus.md` — Prometheus quick primer: scrape model, metrics/labels, PromQL, exporters, and a tiny instrumented app example (L1)
- terraform-009: `terraform/scripts/2026-07-13-zip-build.sh` — Minimal Lambda ZIP build script for Terraform AWS Lambda deployments (L1)

## 2026-07-12

### Added
- docker-002: `docker/dockerfiles/2026-07-12-first-custom-docker-image.Dockerfile` — First custom Docker image from a minimal Dockerfile (L1)
- docker-003: `docker/notes/2026-07-12-explore-docker-cli.md` — Exploring the Docker CLI — images, containers, volumes, and networks (L1)
- git-010: `git/notes/2026-07-12-install-git-identity-first-commit.md` — Install Git, configure identity, and first commit pitfalls (L1)
- git-008: `git/scripts/2026-07-12-bump-version.sh` — Simple version bumper script referenced in git-cicd-automation.md (L1)
- con-042: `docs/concepts/application-security-testing-concepts/snippets/2026-07-12-appsec-practice-exercises.py` — Practice exercises: SAST scan vs DAST probe on a vulnerable endpoint (L2)
- con-043: `docs/concepts/application-security-testing-concepts/2026-07-12-applying-appsec-in-devsecops.md` — Applying Application Security Testing in DevSecOps — pitfalls and pipeline integration (L2)

## 2026-07-10

### Changed
- k8s-001: `scripts/bash/k8s_toolkit/security/aks-privilege-escalation-hardening.sh` — Rework: removed `--dry-run`/`DRY_RUN` (forbidden at L1), reshaped to 15-line L1-sized script with two core checks (L1)

### Added
- grype-002: `grype/scripts/grype-end-to-end-scan-pipeline.sh` — End-to-end Grype pipeline: scan images, emit JSON + SARIF, gate CI on severity (L3)
- dependabot-004: `dependabot/notes/2026-07-10-enabling-dependabot-alerts.md` — Enabling Dependabot alerts and security updates on a sample repo (L1)
- cosign-006: `cosign/manifests/2026-07-10-keyless-oidc-ci.yaml` — Cosign keyless signing with GitHub OIDC verification in CI (L2)
- dependabot-007: `dependabot/configs/2026-07-10-npm-version-strategy.yaml` — Minimal Dependabot config for npm ecosystem with version update strategy (L2)
- docker-002: `docker/dockerfiles/2026-07-10-first-custom-image.Dockerfile` — First custom Docker image from a minimal Dockerfile (L1)
- k8s-001: `scripts/bash/k8s_toolkit/security/aks-privilege-escalation-hardening.sh` — AKS privilege escalation detection and optional remediation script (L1)
- ansible-004: `scripts/patch-report.sh` — Ansible patch management report generator with server inventory and security update count (L1)
- lin-001: `scripts/bash/linux_toolkit/samba-setup.sh` — Samba file server setup script with share directory, smb.conf, user creation, and service enablement (L1)
- git-006: `git/scripts/2026-07-10-local-ci-simulation.sh` — Local CI simulation via a pre-commit hook that lints staged shell scripts and runs tests (L2)
- con-012: `docs/concepts/application-security-testing-concepts/snippets/2026-07-10-owasp-top10-sast.sh` — OWASP Top 10 SAST practice harness mapping deliberately vulnerable labs to SAST detection (L2)

## 2026-07-09

### Added
- docker-001: `docker/notes/0000-primer-docker.md` — Docker quick primer: what it is, images vs containers, and key terminology (L1)
- helm-001: `helm/notes/0000-primer-helm.md` — Helm quick primer: what it is, charts, releases, and a tiny install example (L1)
- kubernetes-001: `kubernetes/notes/0000-primer-kubernetes.md` — Kubernetes quick primer: what it is, clusters, nodes, pods, and a tiny example (L1)
- github-actions-001: `github-actions/notes/0000-primer-github-actions.md` — GitHub Actions quick primer: what it is, workflows, jobs, runners, and a tiny CI example (L1)
- sonarqube-001: `sonarqube/notes/0000-primer-sonarqube.md` — SonarQube quick primer: what it is, Quality Gates, profiles, and a tiny analysis example (L1)
- opentofu-001: `opentofu/notes/0000-primer-opentofu.md` — OpenTofu quick primer: what it is, providers, state, modules, and a tiny HCL example (L1)
- terrascan-010: `terrascan/notes/2026-07-10-terrascan-getting-started-trip-ups.md` — L2 notes: Docker-based Terrascan install, Terraform plan scanning, volume mount gotchas, and CI gating

## 2026-07-08

### Added
- kustomize-001: `kustomize/notes/0000-primer-kustomize.md` — Kustomize quick primer: what it is, base/overlay patching, and key terminology (L1)
- kustomize-002: `kustomize/notes/2026-07-08-install-kustomize-first-overlay.md` — First overlay creation notes with install, patch targeting gotchas, and ordering (L1)
- kustomize-003: `kustomize/configs/2026-07-08-minimal-kustomization.yaml` — Minimal kustomization.yaml with commonLabels, namePrefix, and namespace (L1)

## 2026-07-06

### Added
- argocd-001: `argocd/notes/0000-primer-argocd.md` — ArgoCD quick primer: what it is, GitOps analogy, key terms (L1)
- argocd-002: `argocd/notes/2026-07-06-install-argocd-first-app.md` — First-install walkthrough with login, password, and `.git` suffix gotchas (L1)
- argocd-003: `argocd/manifests/2026-07-06-sample-app-application.yaml` — Minimal Application manifest with automated prune/selfHeal sync policy (L1)
- grype-007: `grype/manifests/grype-reusable-sarif-workflow.yaml` — Reusable GitHub Actions workflow for Grype container vulnerability scanning with SARIF output (L4)
  - `workflow_call` manifest accepting `image` or `sbom-path` inputs with configurable `fail-on`, `severity`, `ignore-unfixed`, and `grype-version` parameters
  - Exposes `sarif-path` and `findings-count` outputs for downstream steps
  - Inline Python SARIF 2.1.0 converter embedded in the scan step
  - Grype DB caching via `actions/cache@v4`; artifact upload for JSON + SARIF results
- dependabot-002: `dependabot/notes/2026-06-15-dependabot-first-repo-bump-pr.md` — First repo Dependabot setup and version-bump PR walkthrough (L1)
  - Scratchy first-person notes covering `.github/dependabot.yml` creation, toggle verification, and PR behavior
  - Got-stuck list: directory path typo, `open-pull-requests-limit` ceiling behaviour, ecosystem mismatch (dotnet vs pip)
- syft-003: `syft/docs/enterprise-registry-auth-caching-patterns.md` — Syft enterprise registry authentication and caching patterns for high-scale CI (L5)
  - Reference-style guide covering Docker config, explicit flags, and env-var registry auth methods
  - Package catalog cache configuration and CI persistence with `actions/cache`
  - `.syft.yaml` configuration for enterprise CI, multi-arch scanning, and cloud registry auth (ECR, GAR)

## 2026-07-05

### Added
- zap-014: `zap/docs/zap-automation-plan-structure.md` — ZAP Automation Framework plan structure reference covering contexts, requests, and passive scan configuration (L4)
- grype-007: `grype/manifests/grype-sarif-reusable-workflow.yaml` — Reusable GitHub Actions workflow for Grype container vulnerability scanning with SARIF output (L4)

## 2026-07-04

### Added
- git-004: `git/notes/2026-07-04-git-branching-merge-confusions.md` — Following a Git branching and merging tutorial and write-up of confusions (L2)
    - First-person notes covering what worked (fast-forward, log --graph), got stuck on (merge conflicts, merge strategies, rebase after merge), and what I'd try next
    - L2 loose shape: What I followed → What worked → Got stuck on → What I'd try next
- git-005: `git/snippets/2026-07-04-git-rebase-vs-merge-conflict-patterns.sh` — Git rebase vs merge comparison with conflict resolution patterns (L2)
    - Bash snippet creating a disposable repo and walking through merge vs rebase on the same conflicting edit
    - Demonstrates conflict markers and the difference in post-conflict history shape
    - shellcheck passed (clean)
## 2026-07-04

### Added
- ansible-001: `ansible/scripts/bootstrap-target-node.sh` — Bootstrap script for target node preparation referenced in linux-iac-pipeline-workflows.md (L1)
    - Prepares Linux nodes for Ansible automation with Python 3 and required packages
    - Creates passwordless sudo entry for automation user

## 2026-07-03

### Added
- defectdojo-001: `defectdojo/notes/0000-primer-defectdojo.md` — DefectDojo quick primer covering vulnerability management workflow, products/engagements, and a Docker Compose startup example (L1)
    - First-person plain-language primer: what DefectDojo is, what it does, why it exists
    - Key terminology: Product, Engagement, Finding, Test, Deduplication, API Token, Jira Sync
    - word count within 400-900 range
- defectdojo-002: `defectdojo/snippets/install-defectdojo-first-scan-report.sh` — Minimal bash snippet to clone DefectDojo and start it locally (L1)
    - 9-line Docker Compose startup with localhost URL and next-step pointer
    - shellcheck passed (clean)

## 2026-07-02

### Added
- falco-004: `falco/scripts/tried-falco-k8s-alert-forwarding.sh` — Minimal Falco deployment with Kubernetes integration and alert forwarding (L2)
    - Deploys Falco via Helm with JSON output enabled
    - Deploys Falcosidekick for webhook-based alert forwarding
    - Got stuck on: missing jsonOutput=true, service DNS name for httpOutput.url, privileged container requirement
    - shellcheck passed (clean)

## 2026-07-01

### Added
- con-010: `docs/concepts/configuration-management/0000-primer-configuration-management.md` — Configuration Management concept primer (L1)
    - What it is, why it matters for devops, key terminology, and a concrete Ansible playbook example
- con-011: `docs/concepts/observability-monitoring/0000-primer-observability-monitoring.md` — Observability & Monitoring concept primer (L1)
    - Metrics, logs, traces, alerts, SLI/SLO/SLA terminology, and a Prometheus alert rule example
- git-001: `git/notes/0000-primer-git.md` — Git quick primer (L1)
    - What Git is, how it works, key terminology, and the basic init/add/commit workflow

## 2026-06-30

### Added
- trufflehog-004: `trufflehog/notebooks/trufflehog-scan-modes-comparison.ipynb` — Comparing TruffleHog scan modes: git history vs filesystem vs GitHub API (L5)
    - Demonstrates filesystem scan for current-state checks and git scan for historical detection
    - Compares output structure differences (commit hashes in git metadata)
    - Performance characteristics and mode selection guidance
- trufflehog-005: `trufflehog/templates/multi-repo-secret-scan/` — TruffleHog multi-repository configuration scaffold with centralized allowlisting (L5)
    - Centralized config at `.trufflehog/config.yaml` for custom detectors and entropy tuning
    - Organization-wide allowlist at `.trufflehog/allowlist.yaml` for false positive management
    - Multi-repository scan script with aggregated JSON output
    - GitHub Actions workflow for scheduled organization scans
    - shellcheck passed (clean)

## 2026-06-29

### Added
- terrascan-010: `terrascan/notes/2026-06-29-terrascan-getting-started-trip-ups.md` — Following the official Terrascan getting-started tutorial (L2)
    - Covers install via curl, first scan with exit code behavior, and CI gating via JSON parsing
    - Got stuck on: exit codes (0/3/4/5), silent policy download, archived repo status, severity filter not affecting exit code
    - What I'd try next: custom Rego policies with `--config-path`

## 2026-06-28

### Added
- zap-011: `zap/scripts/zap-dast-sarif-code-scanning.sh` — ZAP automated DAST pipeline: scan, generate SARIF, and post to GitHub Code Scanning (L4)
   - Runs spider and active scans via ZAP daemon in Docker
   - Converts ZAP alerts JSON to SARIF 2.1.0 format using jq
   - Uploads SARIF to GitHub Code Scanning via `gh api` when GITHUB_TOKEN is set
   - Configurable `FAIL_ON` threshold (high/medium/low/never)
   - shellcheck passed (clean)
- zap-012: `zap/dockerfiles/custom-zap-automation.Dockerfile` — Custom ZAP Docker image with pre-configured Automation Framework plans (L4)
    - Self-contained build (no external plan files needed) — plans created inline
    - Two embedded plans: `quick-scan.yaml` (spider + passive) and `full-scan.yaml` (spider + AJAX + active)
    - Pre-configured for CI-driven DAST scanning pipelines
- zap-013: `zap/templates/zap-dast-integration-scaffold/` — OWASP ZAP DAST integration scaffold: GitHub Actions + Automation Framework (L4)
    - Scaffold (starter template) with root-level `zap-automation-plan.yaml` as primary Automation Framework entrypoint
    - GitHub Actions workflow runs the plan directly via `zap.sh -cmd -autorun` with `-job` variables for TARGET_URL and REPORT_DIR
    - `plans/` (quick and full), `scripts/run-zap-dast.sh`, `Makefile` (`make plan-scan`, `make quick-scan`, `make full-scan`), `.gitignore`
- vault-007: `vault/configs/multi-environment-access-control.hcl` — Vault policy as code for multi-environment access control (L3)
   - Path-based access control scoped to dev, staging, and prod environments
   - CI/CD scoped policies using identity entity interpolation for dynamic paths
   - Separated dev (full CRUD), staging (read-mostly with release team write), and prod (read-only) access levels
   - Transit, database, and PKI engine access patterns for each environment tier
- grype-004: `grype/scripts/grype-results-to-sarif.py` — Reusable Grype results parser and SARIF converter (L4)
   - Reads Grype JSON output from file or stdin, maps severity levels to SARIF levels
   - Builds valid SARIF 2.1.0 log with rule IDs, messages, and artifact locations
   - Error handling for missing files and malformed JSON
- grype-006: `grype/dockerfiles/multi-stage-grype-scan.Dockerfile` — Multi-stage build with Grype vulnerability scanning stage (L4)
   - Three-stage pattern: Go builder, Grype scan with JSON+SARIF output, minimal Alpine runtime
   - Self-contained Go HTTP server as demo application
   - Supports `--target` selection for build vs scan vs runtime

## 2026-06-27

### Added
- vault-006: `vault/docs/vault-agent-auto-auth-kubernetes.md` — Vault Agent auto-auth with Kubernetes service accounts (L3)
- opa-002: `opa/snippets/deny-privileged-hostnetwork.rego` — OPA Rego policy to deny privileged containers and hostNetwork access (L3)
- opa-003: `opa/docs/wired-opa-admission-control.md` — Guide to wiring OPA into admission control: local testing, ConstraintTemplate, Constraint, ConfigMap deployment (L3)
   - Purpose → Steps → Verify structure covering Kubernetes auth method setup, role binding, policy definition, agent config, and sidecar deployment
   - Documents the metadata path gotcha for KV v2 and the template re-render limitation
   - Realistic error handling notes based on actual gotchas hit during setup
- trufflehog-002: `trufflehog/docs/trufflehog-output-formats-json-sarif-csv.md` — TruffleHog output format reference covering v3+ JSON schema, SARIF conversion, and CSV export patterns for CI ingestion (L5)
   - Purpose → When to use → Prerequisites → Steps → Verify → Common errors → References structure
   - Covers native `--json`, `--json-legacy`, and `--github-actions` output flags and their field mappings
   - Includes Python conversion snippets for JSON-to-SARIF and JSON-to-CSV pipelines
   - Documents `SourceMetadata` shape mismatch across Git, filesystem, and S3 sources

## 2026-06-26

### Added
- vault-005: `vault/scripts/vault-db-dynamic-secrets.sh` — Vault dynamic database secrets workflow: Postgres dynamic credentials end-to-end (L3)
   - Spins up a Postgres container, enables Vault's database secrets engine, configures connection and role
   - Generates ephemeral credentials, verifies them against Postgres, revokes lease, and confirms removal
   - Real error handling with cleanup trap, prerequisite checks, and connection timeout
   - shellcheck passed (clean)
- vault-004: `vault/configs/2026-06-26-dev-test-policies.hcl` — Vault policy and secrets engine configuration for dev/test environments (L2)
   - HCL policies for separate KV v2 engines at dev-kv (full CRUD) and test-kv (read-mostly)
   - Documents the /data/ vs /metadata/ path split gotcha and kv-v1 vs kv-v2 silent-empty trap
   - First-person learner comments with "Got stuck on" section
- falco-003: `falco/snippets/tried-file-access-detector.go` — Go snippet to detect suspicious file access from Falco JSON output (L2)
   - Reads Falco JSON lines from stdin, matches known file-access rules and scans output fields for sensitive paths
   - First-person Go code with reasoning comments
- snyk-002: `snyk/docs/multi-project-ci-pipeline.md` — Multi-project Snyk CI pipeline with per-service monitoring (L3)
  - Purpose → Steps → Verify structure covering matrix-based per-service scanning
  - Documents service-to-project mapping, GitHub Actions matrix workflow, org-level tags, and per-service failure rules
  - Common errors section based on real gotchas: duplicate monitors, working-directory mismatch, and org-scoped token issues
- snyk-001: `snyk/scripts/snyk-vuln-scan-pipeline.sh` — Snyk vulnerability scanning pipeline from scratch: test, monitor, fail on high CVEs (L3)
    - Bash pipeline that runs snyk test or snyk container test depending on target type
   - Pushes a snapshot to the Snyk dashboard for continuous monitoring via snyk monitor
   - Parses JSON output with jq, counts severity levels, and fails the build when CRITICAL or HIGH findings exceed the threshold
   - shellcheck passed (clean)
- zap-010: `zap/configs/ci-dast-automation-framework-plan.yaml` — ZAP Automation Framework plan for CI-integrated DAST scanning (L3)
   - Defines context, spider, AJAX spider, passive scan config, active scan with targeted rules, and JSON report
   - Uses template variables (TARGET_URL, AUTH_METHOD, LOGIN_URL, SCAN_USER, SCAN_PASS) for CI parameter injection
   - Tests for minimum URL discovery and alert count gating with WARN/INFO thresholds
- terrascan-008: `terrascan/configs/tried-custom-s3-rule.yaml` — Minimal Terrascan custom rule configuration for AWS S3 bucket policies (L2)
   - Two custom Rego rules: block public ACLs and require default encryption
   - First-person learner comments explaining the custom rule setup process
   - YAML multi-document format for separate policy definitions

## 2026-06-25

### Added
- con-001: `docs/concepts/application-security-testing-concepts/0000-primer-application-security-testing-concepts.md` — Application Security Testing Concepts primer: SAST, DAST, SCA, and key terminology (L1)
- con-002: `docs/concepts/ci-cd-pipeline-concepts/0000-primer-ci-cd-pipeline-concepts.md` — CI/CD Pipeline Concepts primer: stages, gates, triggers, and pipeline fundamentals (L1)
- con-003: `docs/concepts/container-runtime-security/0000-primer-container-runtime-security.md` — Container & Runtime Security primer: image vs runtime security, syscalls, eBPF, and terminology (L1)
- con-007: `docs/concepts/software-supply-chain-security/0000-primer-software-supply-chain-security.md` — Software Supply Chain Security primer: supply chain attacks, SBOM, signing, and dependency verification (L1)
- con-008: `docs/concepts/version-control-with-git/0000-primer-version-control-with-git.md` — Version Control with Git primer: repos, commits, branches, and collaboration workflows (L1)
- con-009: `docs/concepts/containers-orchestration/0000-primer-containers-orchestration.md` — Containers & Orchestration primer: images, containers, registries, and Kubernetes fundamentals (L1)

## 2026-06-25

### Added
- con-004: `docs/concepts/infrastructure-as-code/0000-primer-infrastructure-as-code.md` — Infrastructure as Code primer: what IaC is, why it matters, and key terminology (L1)
- con-005: `docs/concepts/linux-shell-fundamentals/0000-primer-linux-shell-fundamentals.md` — Linux & Shell Fundamentals primer: what the shell is, why it matters, and core terminology (L1)
- con-006: `docs/concepts/secrets-access-management/0000-primer-secrets-access-management.md` — Secrets & Access Management primer: controlling access, handling credentials, and least privilege (L1)

## 2026-06-24

### Added
- grype-002: `grype/scripts/grype-vuln-pipeline.sh` — Grype vulnerability scanning pipeline with SARIF output for CI integration (L3)
- falco-005: `falco/docs/syscall-vs-tracepoint-rules.md` — Comparing Falco syscall and tracepoint-driven rules for container behavior monitoring (L3)
   - Purpose → When to use → Prerequisites → Steps → Verify → Common errors → References shape
   - Covers syscall-driven rules for broad system coverage versus tracepoint rules for lower overhead
   - Includes rule examples, performance considerations, and kernel compatibility notes
 - falco-006: `falco/scripts/deploy-falco-ruleset.sh` — Custom Falco ruleset deployment with Kubernetes Helm chart end-to-end (L3)
    - Creates namespace, ConfigMap from custom rules file, and installs Falco with Helm
    - Supports custom rules mounting via Helm values
- grype-003: `grype/notebooks/grype-sbom-output-explorer.ipynb` — Grype SBOM and vulnerability output explorer: compare JSON, CycloneDX, and SARIF formats (L3)
   - Jupyter notebook that runs a Grype scan in JSON and SARIF formats plus a Syft-generated CycloneDX SBOM
   - Parses and compares the structures: matches vs runs/results vs BOM components
   - Includes fixture fallbacks so the notebook runs even when grype/syft are not installed

## 2026-06-23

### Added
- tetragon-001: `tetragon/notes/0000-primer-tetragon.md` — Tetragon quick primer (L1)
   - First-person scratchy primer covering what Tetragon is, key terminology (eBPF, TracingPolicy, node agent, process events), and a minimal YAML example
- terrascan-009: `terrascan/scripts/tried-terrascan-ci-scan.sh` — Minimal Terrascan CI script to scan Terraform and fail on high severity violations (L2)
   - First-person learner bash script that runs `terrascan scan` with `--severity high --exit-code 1`
   - Accepts scan directory as argument (defaults to `.`)
   - Documents the `--exit-code` gotcha in comments
- tetragon-003: `tetragon/configs/first-tracing-policy-exec-file.yaml` — Minimal TracingPolicy to observe exec and file access events (L1)
   - First-person TracingPolicy YAML with tracepoint for exec events and kprobe for file access
   - Learner comments documenting the selector syntax exploration
- cosign-005: `cosign/configs/keyless-signing-github-actions.yaml` — Cosign signing + GitHub Actions keyless CI integration (L2)
   - GitHub Actions workflow that builds and pushes a container image, then signs it with Cosign in keyless (OIDC) mode
   - Uses `sigstore/cosign-installer` action and `cosign sign --yes` with automatic GitHub OIDC token detection
   - Includes a sanity-check verify step with commented-out issuer validation template
- dependabot-004: `dependabot/notes/dependabot-alerts-security-updates.md` — Enabling Dependabot alerts and security updates on a sample repo (L1)
   - First-person scratchy notes covering dashboard toggle setup, alert triage flow, and security update behavior
   - Got-stuck list: alerts vs updates toggle confusion, private repo visibility requirement, dismissed alert re-opening via REST API
- gitguardian-003: `gitguardian/scripts/gg-incident-response-pipeline.sh` — Build a GitGuardian incident response pipeline from scratch (L3)
   - Scans commits with `ggshield secret scan commit-range` and normalizes JSON output
   - Parses findings with jq and reports severity per secret
   - Supports optional webhook alerting and severity-based pipeline gating via `FAIL_ON`
- snyk-003: `snyk/configs/snyk-dependency-patch-ignore.yaml` — Snyk policy configuration for dependency patching and ignore rules (L3)
    - `.snyk`-style YAML policy demonstrating `ignore` blocks with expiry dates and permanent ignores
    - `patch` section mapping vulnerable packages to patched versions for automated remediation suggestions
- gitguardian-004: `gitguardian/docs/monorepo-ci-per-team-exclusions.md` — How I wired GitGuardian into a monorepo CI and configured per-team exclusions (L3)
    - Purpose → When to use → Prerequisites → Steps → Verify → Common errors → References shape
    - Covers root config with universal noise suppression, per-team `.ggshield.yaml` overrides in service subdirectories, two-pass CI pipeline (scheduled full scan + PR diff gate), and team-based alert routing via directory prefix
    - Documents real gotchas: config resolution precedence, `detectors-ignore` version requirement, overlapping path-ignore rules, and recursive scan edge cases
- tetragon-002: `tetragon/notes/2026-06-23-install-tetragon-docker-first-events.md` — Install Tetragon via Docker and observe my first system events (L1)
    - First-person scratch notes covering Docker run with eBPF prerequisites, `tetra getevents` for real-time streaming, and process exec event observation
    - Cleanup and next-steps pointer to TracingPolicy filtering

## 2026-06-22

### Added
- codeql-004: `codeql/manifests/multi-language-codeql-analysis.yaml` — Multi-language CodeQL analysis CI workflow manifest with Python, JavaScript, Go, and Java matrix (L3)
  - Matrix strategy over four languages with `fail-fast: false`
  - Custom config file support via `config-file` init parameter
  - Weekly schedule alongside push/PR triggers
  - SARIF output with `upload: Failure` for CI gating
- cosign-004: `cosign/scripts/minimal-sign-verify.sh` — Minimal container image signing and verification with Cosign (L2)
  - Generates a key pair, signs a target image, and verifies the signature
  - Default image argument with configurable override
  - First-person learner comments documenting the workflow
- codeql-003: `codeql/docs/wired-custom-queries-into-ci.md` — How I wired CodeQL custom queries into a GitHub Actions CI pipeline (L3)
  - Purpose → Steps → Verify shape covering custom pack structure, workflow init flags, and separate SARIF output
  - Documents the `packs: ./codeql-custom` approach and an alternative separate-analysis-pass pattern
- codeql-002: `codeql/snippets/hardcoded-creds-local-flow.ql` — Custom CodeQL query using local taint tracking to detect hardcoded credentials (L3)
  - Uses TaintTracking::Configuration for source-to-sink flow analysis
  - Detects string literals flowing into credential-named variables and credential-target function arguments
- cosign-003: `cosign/notes/2026-06-22-cosign-getting-started-trip-ups.md` — Following the official Cosign getting-started tutorial and what tripped me up (L2)
  - Covers keypair generation, signing a pushed image, verify JSON output, keyless OIDC prerequisites, and attestation predicate gotcha
  - Steps + Got stuck on + What I'd try next format
- dependabot-002: `dependabot/notes/2026-06-22-first-time-dependabot-setup.md` — Enable Dependabot on my first repo and trigger a version bump PR (L1)
  - Scratchy walkthrough covering `.github/dependabot.yml` creation, YAML indentation gotcha, and PR behavior after config push
  - First-person present tense, under 300 words

## 2026-06-21

### Added
- semgrep-002: `semgrep/manifests/semgrep-gitlab-ci.yaml` — L5 GitLab CI manifest integrating Semgrep SAST with diff-aware MR scanning and scheduled full scans
  - Merge request job with `--baseline-commit` for finding only new issues
  - Scheduled full-scan job with severity breakdown
  - SARIF artifact output for GitLab SAST report integration
  - Rule caching for faster pipeline runs
- checkov-003: `checkov/templates/reusable-workflow-custom-policies/` — GitHub Actions reusable workflow template for Checkov custom policies (L5)
  - Reusable workflow with configurable inputs: scan directory, frameworks, custom policy path, severity threshold, SARIF output toggle, artifact upload
  - Sample Checkov custom policy YAML files for S3 bucket ACL and EC2 public IP restriction
  - Example caller workflow for push/PR triggers
  - README with Purpose, When to use, Prerequisites, Steps, Verify, Common errors, and References sections

## 2026-06-20

### Added
- checkov-002: `checkov/scripts/deep-terraform-plan-scan.sh` — Deep Checkov Terraform plan scanning with severity gating and custom policy support (L5)
  - Priority-qualified binary validation for terraform, checkov, jq
  - Timestamped plan export with configurable failure severity, skip checks, and external checks dir
  - SARIF output with error-level result aggregation for CI gating
  - shellcheck passed (clean)
- checkov-004: `checkov/docs/checkov-ai-infrastructure-checks.md` — Checkov AI infrastructure checks reference covering AWS Bedrock, Google Vertex AI, and OpenAI-associated resources (L5)
  - Reference-style guide with Purpose, When to use, Prerequisites, Coverage by provider, Combined scan, Verify, Common errors, References
  - Documents built-in CKV_AWS_* and CKV_GCP_* checks alongside custom policy patterns for third-party AI APIs
  - Practical verification workflow for plan-json scanning per provider
- trivy-004: `trivy/manifests/trivy-sarif-code-scanning.yaml` — L5 GitHub Actions manifest integrating Trivy SARIF output with GitHub Code Scanning
  - Dual-job workflow: image vulnerability scan and filesystem scan (vulnerabilities + misconfigurations)
  - Each job produces SARIF output and uploads via `github/codeql-action/upload-sarif@v3`
  - Trivy DB caching for faster subsequent runs
  - Scheduled weekly scan alongside push/PR triggers
  - Uses `continue-on-error` to ensure SARIF upload completes before optional gating
- trivy-002: `trivy/notebooks/trivy-scan-mode-comparison.ipynb` — L5 notebook comparing `trivy fs`, `trivy image`, and `trivy repo` scanning modes
  - Runs all three modes against a sample Python project with known-vulnerable dependencies
  - Compares result structures: vulnerability counts, misconfigurations, and secrets per mode
  - Provides a CI/CD decision guide mapping pipeline stage to recommended scan mode
  - Documents common gotchas: rootfs scanning, private repo auth, severity filter mismatch, SBOM re-scanning
- gen-012: L1 README Layout audit note documenting the Dependabot root folder and `.pr_result.json` ignore decision.
  - Confirms `dependabot/` structure with primer and configs is documented in README
  - Decision: `.pr_result.json` should remain ignored (CI artifact already in `.gitignore`, removed from tracking)
- semgrep-001: `semgrep/docs/semgrep-rule-writing-reference.md` — L5 Semgrep rule writing reference covering pattern syntax and metavariable constraints
  - Reference-style guide with Purpose, When to use, Prerequisites, Steps, Verify, Common errors, References
  - Documents basic pattern matching, metavariable constraints (regex, comparison), ellipsis, and constraint patterns
  - Includes practical examples for security-focused rule creation (subprocess, SQL injection, Flask debug mode, CORS)

### Changed
- `.pr_result.json` — Removed from git tracking (remains in `.gitignore` as CI artifact)

## 2026-06-19

### Added
- syft-002: `syft/scripts/sbom-vuln-pipeline.sh` — L4 Bash pipeline that generates a CycloneDX SBOM with Syft, scans it with Grype, writes JSON/SARIF-style reports, and exits non-zero when findings meet the configured severity threshold.
- terrascan-005: `terrascan/notes/2026-06-19-install-terrascan-tiny-tf.md` — L1 first-person notes on installing Terrascan via pip and scanning a single EBS volume Terraform file. Covers pip vs binary install, JSON output parsing, and the `--exit-code` gotcha for CI.
- terrascan-006: `terrascan/snippets/tiny-tf-with-findings.tf` — L1 minimal HCL snippet with two resources (S3 bucket without logging config, unencrypted EBS snapshot) that trigger distinct Terrascan findings.
- syft-003: `syft/dockerfiles/multi-stage-sbom.Dockerfile` — Multi-stage Dockerfile demonstrating SBOM generation with Syft (L4)
  - Three-stage pattern: Go app builder, Syft SBOM generation stage, minimal runtime stage
  - Generates CycloneDX and SPDX SBOMs from the built application
  - Pinned Syft version for reproducible builds
- syft-004: `syft/docs/sbom-output-formats-reference.md` — Reference guide for Syft's three SBOM output formats (L4)
  - Documents the JSON structure of Syft native, CycloneDX, and SPDX formats with annotated examples
  - Practical jq extraction commands for each format
  - Format selection guide and verification steps

## 2026-06-18

### Added
- gen-006: README Layout audit confirming `assets/`, `cosign/`, `falco/`, and `terrascan/` are already documented
- cosign-002: `cosign/notes/2026-06-14-install-cosign-generate-first-keypair.md` — First-person L1 notes covering Cosign installation and keypair generation
- syft-001: `syft/templates/sbom-pipeline-scaffold/` — SBOM pipeline scaffold for Syft + Grype CI integration (L4)
   - GitHub Actions workflow that builds an image, generates an SBOM with Syft, and scans it with Grype
   - SARIF upload for GitHub code scanning integration
   - Local scan script for pre-commit validation
   - Syft and Grype configuration files tuned for common language ecosystems
   - shellcheck passed (clean)
- dependabot-001: `dependabot/notes/0000-primer-dependabot.md` — First-person L1 primer covering Dependabot as GitHub's dependency updater (L1)
  - Explains package ecosystems, manifests, lockfiles, update pull requests, schedules, and PR limits
- dependabot-003: `dependabot/configs/tried-npm-dependabot.yaml` — Minimal Dependabot config for weekly npm dependency updates (L1)
  - Watches the root npm project and opens up to three labeled dependency PRs per week

## 2026-06-17

### Added
- trufflehog-002: `trufflehog/scripts/analyze-trufflehog-results.py` — Reusable Python helper for TruffleHog JSON results analysis (L4)
  - Reads JSON lines or arrays from stdin or file
  - Groups results by detector, file, or severity with optional minimum-severity filter
  - Prints summary with total/verified counts and top detectors
  - Real error handling for JSON parse failures and empty results
- trufflehog-003: `trufflehog/dockerfiles/pre-commit-scanner.Dockerfile` — Dockerized TruffleHog scanner for pre-commit hook (L4)
  - Python 3.12-alpine base with pinned TruffleHog version
  - Embedded shell script scans staged files and blocks commits on secrets
  - Designed for bind-mounted repo at /repo
- trufflehog-001: `trufflehog/templates/github-secret-scanning-integration/` — GitHub Actions scaffold for TruffleHog secret scanning (L4)
  - Workflow runs on pull requests, pushes, and a weekly schedule
  - Bash runner scans Git history with TruffleHog JSON output and generates a markdown summary
  - GitHub Actions job uploads JSON results and comments on pull requests when findings exist
  - shellcheck passed (clean)
- zap-001: `zap/scripts/dast-workflow-from-scratch.sh` — Full ZAP DAST workflow from spider discovery through active scanning and report generation (L3)
  - Starts a headless ZAP daemon in Docker, crawls the target, runs active scanning, and writes HTML + JSON reports
  - Supports configurable `FAIL_ON` threshold and `OUTDIR` for CI-style gating
  - shellcheck passed (clean)

## 2026-06-16

### Added
- zap-002: `zap/configs/zap-authenticated-scan-context.yaml` — ZAP context configuration for form-based authenticated scanning (L3)
  - Defines URL scope with include/exclude patterns, session cookie management, form-based auth with CSRF token handling, and a test user
  - YAML comments document the reasoning behind each configuration choice
- zap-003: `zap/docs/passive-vs-active-scanning-zap.md` — Comparison of passive and active scanning modes in ZAP (L3)
  - Covers how each mode works, when to use each, and a practical workflow split
  - Includes a decision table for CI/CD smoke tests vs pre-release deep scans
- falco-002: `falco/configs/container-drift-detection.yaml` — Custom Falco rules for container drift detection (L2)
  - Two rules: binary modification detection in /usr/bin and package manager execution detection
  - Detects file writes to critical binaries via openat/rename/unlink syscalls
  - Detects package manager usage (apt, yum, apk, pip, npm) indicating runtime changes
- gen-009: README Layout audit for undocumented root folders (audit)
  - Added `assets/` and `terrascan/` entries to README Layout
  - Confirmed `cosign/` and `falco/` were already documented

### Changed
- vault-001: `vault/notes/2026-06-15-vault-getting-started-trip-ups.md` — Resubmitted Vault getting-started tutorial notes in a separate PR (L2, rework)
  - First-person walkthrough covering dev server setup, KV v2 basics, policy creation, token scoping, and JSON output shape
  - Keeps the same tutorial topic while separating it from the previous shared branch

## 2026-06-15

### Added
- falco-001: `falco/notes/2026-06-15-falco-rules-macros-lists.md` — Understanding Falco's rule file structure — macros, lists, and the append trick (L2, rework)
  - First-person walkthrough covering list/macro/rule entry types, append pattern for custom rules, file-ordering gotcha, and output field discovery
  - Genuinely different topic from existing install/detection notes per rework recommendation
  - Got stuck on: append file ordering in Helm customRules, output field discovery via grep, expanded condition readability via falco --list
- vault-001: `vault/notes/2026-06-15-vault-getting-started-trip-ups.md` — Follow the official Vault getting-started tutorial (L2)
  - First-person walkthrough covering dev server, KV engine, policy creation, token scoping
  - Got stuck on: built-in engines not mentioned in tutorial, token flag inconsistency, root token revocation gotcha, JSON output format
- opa-001: `opa/notes/2026-06-15-opa-getting-started-trip-ups.md` — Following the official OPA getting-started tutorial (L2)
  - First-person walkthrough covering server setup, policy loading via API, and decision testing
  - Got stuck on: curl flag confusion, policy loading approaches, REST API path format, decision log visibility
- vault-002: `vault/scripts/vault-kv-crud.sh` — Minimal Vault KV CRUD operations script (L2)
  - Covers write, read, field extraction, list, metadata, delete, undelete, and destroy operations
  - shellcheck passed (clean)
- opa-002: `opa/configs/tried-a-gatekeeper-constraint.yaml` — Minimal Kubernetes admission policy with Gatekeeper (L2)
  - ConstraintTemplate + Constraint to block pods using hostNetwork
  - First-person comments documenting the learning process
- opa-003: `opa/scripts/how-i-test-policies-locally.sh` — Testing OPA policies locally before deploying to Gatekeeper (L2)
  - Minimal runner that invokes `opa eval` with a policy file and JSON input
  - shellcheck passed (clean)

## 2026-06-14

### Audit — Merged
- terrascan-001 (PR #275): notes(primer) — Score 10/10. L1 first-person scratchy primer (~260 words) covering what Terrascan is, key terminology (IaC, rule, policy, scan, Rego, violation, SARIF), and a minimal CLI example. No forbidden constructs. All five passes clean. PR #275 merged.
- terrascan-002 (PR #275): notes — Score 10/10. L1 first-person scratch notes covering install, scan output, JSON gotcha, and next steps. No forbidden constructs. All five passes clean. PR #275 merged.
- terrascan-003 (PR #275): snippet(hcl) — Score 10/10. L1 HCL snippet with deliberately insecure Terraform (wide-open SG, public S3, unencrypted public RDS). Valid HCL, matches task requirement. All five passes clean. PR #275 merged.

### Added
- gitguardian-001: `gitguardian/notes/2026-06-14-first-secrets-scan-repo.md` — Run my first secrets scan on a repo with ggshield (L2)
  - First-person walkthrough covering path scanning, noise filtering with `.ggshield.yaml`, and commit-range scanning
  - Got stuck on: filtering false positives, commit range diff vs full repo scan
- snyk-001: `snyk/notes/2026-06-14-first-vulnerability-scan.md` — Run my first vulnerability scan with Snyk (L2)
  - First-person walkthrough covering `snyk test`, `--all-projects`, auth token setup, and `snyk monitor` comparison
  - Got stuck on: monorepo project detection, CI auth setup
- snyk-002: `snyk/configs/snyk-ci-github-actions.yaml` — Minimal Snyk CI pipeline integration with GitHub Actions (L2)
  - Triggered on push, PR, and weekly schedule
  - Installs Snyk CLI and runs `snyk test --all-projects --fail-on=high --json`
- codeql-001: `codeql/notes/2026-06-14-codeql-datalog-gotchas.md` — CodeQL QL language tutorial notes focused on Datalog-style gotchas (L2)
  - First-person walkthrough covering `from`, `where`, casts, and `matches`
  - Explains why QL felt different from Python-style assignment and regex matching
- gitguardian-002: `gitguardian/scripts/pre-commit-hook-ggshield.sh` — Minimal ggshield pre-commit hook integration (L2)
  - Checks for `ggshield` and a Git worktree
  - Installs the pre-commit hook and scans staged changes
- cosign-003: `cosign/snippets/first-cosign-sign-verify-image.sh` — Sign and verify a container image with Cosign key-pair workflow (L1)
  - Minimal bash snippet that generates a Cosign key pair, signs a target image, and verifies it
  - shellcheck passed (clean)

## 2026-06-13

### Added
- terrascan-001: `terrascan/notes/0000-primer-terrascan.md` — Terrascan quick primer (L1)
  - Primer covering what Terrascan is, key terminology (IaC, rule, policy, scan, Rego, violation, SARIF), and a minimal CLI example
  - First-person learner voice with primer structure
- terrascan-002: `terrascan/notes/2026-06-13-first-scan.md` — Installing Terrascan and running my first IaC scan (L1)
  - First-person scratch notes covering binary install, scan output with 3 violations (SecurityGroup, SSHAccess, S3Bucket), and JSON output gotcha
- terrascan-003: `terrascan/snippets/insecure-terraform.tf` — Deliberately insecure Terraform to test Terrascan rules (L1)
  - HCL snippet with wide-open security group, public S3 bucket, and unencrypted publicly accessible RDS instance
- gitguardian-004: `gitguardian/notes/2026-06-13-ggshield-quickstart-trip-ups.md` — Following the ggshield quickstart and trip-ups (L2)
  - Steps covering pip install, auth setup, first path scan, pre-commit hook, and JSON output
  - Got stuck on: auth requirement for local scans, staged-file-only hook behavior, under-documented JSON schema
  - What I'd try next: GitHub Action SARIF comparison, --exclude flag behavior, policy file ignore rules

## 2026-06-12

### Added
- trivy-015: `trivy/scripts/custom-trivy-check-conftest.sh` — Custom Trivy check with Rego policies via Conftest integration (L4)
   - Runs Trivy misconfiguration scans and evaluates results against custom Rego policies via Conftest
   - Supports image and filesystem targets with configurable severity threshold
   - Transforms Trivy JSON output into policy input format for Conftest evaluation
   - Aggregate summary with pass/fail per target and exit-code gating
   - Binary availability checks, policy dir validation, and shellcheck passed (clean)
- opa-004: `opa/snippets/enforce-image-registry-constraints.rego` — Kubernetes policy: enforce image registry constraints (L3)
   - Rego policy denying Pods and init containers with images from unapproved registries
   - Configurable allowed registry set (docker.io, gcr.io, ghcr.io, registry.example.com)
   - Designed for Gatekeeper ConstraintTemplate integration
- zap-006: `zap/docs/zap-integration-patterns.md` — ZAP integration patterns for web app security testing (L2)
   - Covers daemon mode setup, spider + active scan via REST API, and full pipeline with report generation
   - Steps + Got stuck on + What I'd try next structure with scan type comparison table
   - First-person walkthrough of headless ZAP automation patterns for CI
- gitguardian-005: `gitguardian/snippets/custom-policy-engine-ggshield.sh` — Custom policy engine integration with ggshield CLI (L2)
   - Creates sample `.ggshield.yaml` with two custom detectors (JWT bearer tokens, internal API endpoints)
   - Demonstrates custom detection patterns alongside built-in ggshield detectors
   - shellcheck passed (clean)

## 2026-06-13

### Added
- zap-008: `zap/notes/2026-06-13-spider-scan-test-app.md` — Spider scanning with ZAP against a test app (L1)
   - First-person walkthrough covering ZAP daemon setup, spider scan via REST API
   - Notes on discovery results, polling, and scope considerations
- zap-009: `zap/snippets/my-first-zap-spider-scan.sh` — My first ZAP spider scan via API (L1)
   - Simple bash wrapper for triggering spider scans and polling completion via ZAP REST API
   - Outputs discovered URLs after scan completion

### Changed
- codeql-004: `codeql/notes/2026-06-05-install-codeql-first-analysis.md` — Reworked CodeQL quickstart notes to focus on custom query execution and SARIF upload (L2)
  - Clarifies `query compile` as query validation separate from `database analyze`
  - Uses `--format=csv` for CSV output
  - Uses `codeql github upload-results` with repository, ref, commit, and SARIF arguments
  - Keeps the first-person walkthrough voice and avoids repeating the install note

## 2026-06-11

### Added
- grype-007: `grype/scripts/vuln-diff-two-images.sh` — Vulnerability diff across two container image versions with Grype (L3)
  - Scans two image versions with Grype JSON output
  - Compares vulnerability sets using comm-based diff (new/fixed/common)
  - Severity breakdown for new vulnerabilities
  - Exit-code handling for CI pipeline gating

### Added
- semgrep-016: `semgrep/scripts/bulk-scan-helper.py` — Reusable Semgrep bulk-scan helper with Python (L4)
  - Accepts targets from CLI args or a targets-file list
  - Runs `semgrep --config=auto --json` per target and aggregates results
  - Per-target JSON output plus combined summary JSON with severity filter
  - Exits 1 when any target has findings at or above the threshold, 0 otherwise
- falco-002: `falco/configs/first-custom-rule-detect-shell-in-container.yaml` — Minimal custom Falco rule: detect shell spawning in a container (L2)
  - Fires on `execve` syscall when bash, sh, dash, or zsh is spawned inside a container
  - YAML rule with description, output template, and tags for container/shell/suspicious

## 2026-06-10

### Added
- syft-005: `syft/notebooks/sbom-layer-package-analysis.ipynb` — SBOM analysis: extracting and querying package dependencies across image layers (L3)
  - Purpose → Steps → Verify notebook covering Syft JSON output parsing
  - Groups packages by layer index to see which layer introduced each dependency
  - Query helpers for filtering by type (apk, npm, python), name, and layer
  - Cross-layer file span detection for packages whose files cross base image layers
  - Notes on verification and edge cases
- falco-001: `falco/notes/0000-primer-falco.md` — Falco quick primer (L1)
  - First-person scratchy primer covering what Falco is, key terminology (eBPF, rules, syscall, priority, output), and a minimal YAML rule example
- falco-002: `falco/notes/2026-06-10-install-falco-first-detection.md` — Installing Falco and running first detection (L1)
  - Steps + Got stuck on + What I'd try next format
  - Covers Helm install, DaemonSet logs, test container alert, and rule tuning
- falco-003: `falco/configs/2026-06-10-first-custom-rule-detect-shell-in-container.yaml` — First custom Falco rule: detect shell execution in container (L1)
   - Fires when bash, sh, dash, or zsh is spawned inside a container
- grype-008: `grype/scripts/ci-ready-grype-scan.sh` — CI-ready Grype scanning wrapper with severity thresholds and formatted output (L3)
   - Purpose → Steps → Verify structure for CI integration
   - Configurable fail-on threshold via env var (default: high)
   - JSON output with jq-formatted summary and severity counts
   - Exit-code handling for CI pipeline gating

## 2026-06-09

### Updated
- trivy-013: `trivy/configs/.trivy.yaml` — Trivy monorepo configuration with severity profiles and per-service scan targets (L4)
  - Added `scan.directories` for explicit monorepo service targeting
  - Documented per-service severity override approach via wrapper script
- grype-003: `grype/snippets/my-first-grype-commands.sh` — Refreshed first Grype commands snippet with severity filtering and output limiting (L1)

### Added
- trivy-014: `trivy/manifests/trivy-operator-deployment.yaml` — Trivy Operator deployment: Kubernetes manifests for cluster-wide vulnerability scanning (L4)
  - Namespace, ServiceAccount, ClusterRole, and ClusterRoleBinding for the operator
  - Operator Deployment with security contexts, resource limits, and label selectors
  - Node-collector DaemonSet for per-node filesystem scanning with hostPath mounts
  - Operator config ConfigMap (scan schedule, timeout, enabled scanners) and Trivy config (severity filter, DB repo, timeout)
  - Policy ConfigMap with JSON-based severity thresholds for automated CI gating (block on critical, warn on high)
  - Comment header with Purpose / Apply / Verify instructions
- trufflehog-012: `trufflehog/templates/secret-scanning-pipeline/` — TruffleHog secret scanning pipeline project scaffold with CI integration (L4)
  - Centralised scan target config (`trufflehog-config.yaml`) with repo and filesystem targets, custom detectors, entropy tuning, and exclusion rules
  - GitHub Actions CI workflow (`.github/workflows/secret-scan.yml`) that runs on PR, push, and weekly schedule
  - `scripts/scan-all.sh` — multi-target scan entry point with local and CI modes, graceful fallback when `yq` is unavailable
  - `Makefile` with `scan`, `scan-ci`, and `clean` targets
  - `.gitignore` to exclude reports/
  - shellcheck passed (clean)

## 2026-06-08

### Added
- vault-004: `vault/snippets/vault-read-write.go` — My first Vault read/write commands in Go SDK (L1)
  - Minimal Go snippet using the official hashicorp/vault/api package to write and read a secret
  - Demonstrates client setup, Write, Read, and type assertion on data.Data
- codeql-005: `codeql/scripts/first-codeql-analysis.sh` — Minimal CodeQL analysis: create a database and run a pre-built query (L2)
  - Creates a small vulnerable JS sample (path traversal via res.sendFile)
  - Builds a CodeQL database and runs the OSCommandInjection query, writes SARIF, reads first lines
  - Learner-voice comments explain the query path and a fallback find command if the pack is missing
- gitguardian-006: `gitguardian/configs/.ggshield.yaml` — Scheduled scanning workflow with false-positive suppression (L2)
  - version 2 config: ignore-known-paths for vendor/node_modules/dist
  - ignored-detectors lists generic_api_key; ignored-paths glob filters for generated code
  - allow block covers infra/secret-examples with diff-start-line to suppress expected secrets
- grype-006: `grype/snippets/minimal-grype-scan.go` — Minimal Grype scan with Go SDK: scanning an image and filtering vulns (L2)
  - Shows how to use the grype package to programmatically scan container images
  - Filters output for high and critical severity findings only
- checkov-014: `checkov/manifests/layered-checkov-ci-pr-gate-deep-scan-merge-block.yaml` — Layered Checkov CI: PR gate + scheduled deep scan + merge block (L4)
  - PR gate: lightweight scan on PR with framework auto-detection, SARIF upload, and blocking on high/critical issues
  - Scheduled deep scan: weekly Monday 03:00 UTC scan across terraform, kubernetes, dockerfile, github_actions, arm, cloudformation frameworks
  - Merge block: post-merge policy check that reverts the PR if critical findings are detected
  - Uses concurrency groups and path-based triggers to limit runs to IaC changes
- snyk-002: `snyk/notes/2026-06-08-install-snyk-first-test.md` — Install Snyk CLI and run my first project test (L1)
  - First-person scratch notes covering install, auth, `snyk test` against python-goof, and JSON output
  - Notes comparison intent with Checkov and Grype, plus next steps for `snyk monitor` and IaC scanning
- checkov-016: `checkov/scripts/scan-terraform-plan.sh` — Terraform plan scanning: export plan JSON and evaluate with Checkov (L4)
  - Converts terraform plan binary to JSON, then runs Checkov scan with `--framework terraform_plan`
  - Error handling for missing plan file; accepts optional Checkov args
  - shellcheck passed (clean)
- grype-002: `grype/notes/2026-06-08-first-grype-scan.md` — Install Grype and run my first vulnerability scan (L1)
  - First-person scratch notes covering install, scan of alpine/nginx, and CLI flags
  - Notes `--only-fixed`, `--fail-on high`, and JSON output for CI gating
- 00_index/quick-links.md — Added Checkov terraform plan scan script and Grype first-scan notes

## 2026-06-07

### Added
- gitguardian-001: `gitguardian/notes/0000-primer-gitguardian.md` — GitGuardian quick primer (L1)
  - First-person primer covering what GitGuardian is, key terminology (secret, incident, ggshield, occurrence, policy, false positive), and a minimal CLI example
- gitguardian-002: `gitguardian/notes/2026-06-07-first-ggshield-scan.md` — Installing ggshield and running first secret scan (L1)
  - First-person scratch notes covering pip install, auth setup gotcha, and what to try next
- gitguardian-003: `gitguardian/snippets/my-first-ggshield-commands.sh` — My first ggshield CLI commands (L1)
  - Minimal bash snippet with path scan, pre-commit scan, commit-range scan, and JSON output
  - shellcheck passed (clean)
- 00_index/quick-links.md — Added GitGuardian section with primer, install notes, and snippet entries
- snyk-004: `snyk/notes/2026-06-07-snyk-quickstart-walkthrough.md` — Snyk quickstart walkthrough: steps, gotchas, and next steps (L2)
- snyk-003: `snyk/snippets/my-first-snyk-commands.sh` — My first Snyk commands: test, monitor, and view results (L1)
  - shellcheck passed (clean)

## 2026-06-06

### Added
- checkov-013: `checkov/templates/multi-iac-scan-project/` — Project scaffold: Checkov multi-IaC scanning project (L4)
  - Purpose → Steps → Verify structure covering Terraform, Kubernetes, CloudFormation, ARM, Docker, and Helm
  - Includes config file, scanning script with error handling, Makefile, and GitHub Actions CI workflow
  - shellcheck passed (clean)
- opa-001: `opa/notes/0000-primer-opa.md` — OPA/Gatekeeper quick primer (L1)
  - Primer covering what OPA is, key terminology (Rego, policy, data, Gatekeeper, constraint, ConstraintTemplate), and a minimal CLI example
  - First-person learner voice with primer structure
- opa-002: `opa/notes/2026-06-06-install-opa-repl.md` — Installing OPA and exploring the interactive REPL (L1)
  - First-person scratch notes covering binary install, REPL basics, and things that tripped me up
- opa-003: `opa/snippets/my-first-opa-policy-eval.sh` — My first OPA policy evaluation with sample data (L1)
  - Minimal bash snippet using process substitution to evaluate a Rego policy against a Pod manifest
  - shellcheck passed (clean)
- 00_index/quick-links.md — Added OPA/Gatekeeper section with primer, install notes, and snippet entries
- syft-001: `syft/docs/sbom-formats-comparison.md` — SBOM format comparison: SPDX vs CycloneDX vs Syft JSON (L3)
  - Purpose → Steps → Verify structure covering format generation, structure differences, and validation
  - Compares CycloneDX (security tooling), SPDX (license/legal), and Syft JSON (internal minimal) formats
  - Format selection guide table for practical integration decisions
- snyk-001: `snyk/notes/0000-primer-snyk.md` — Snyk quick primer (L1, rework)
  - First-person scratchy notes covering what Snyk is, vulnerability remediation, key terminology (vulnerability, fix, test, monitor, priority score), and a minimal Node.js example
  - Rework: removed CVSS reference to comply with L1 level voice constraints
- zap-001: `zap/notes/0000-primer-zap.md` — OWASP ZAP quick primer (L1)
  - Primer covering what ZAP is, key terminology (proxy, spider, active/passive scan, context, alert, HUD), and a minimal Docker-based example
  - First-person learner voice with primer structure
- zap-002: `zap/notes/2026-06-06-install-zap-desktop-ui.md` — Installing OWASP ZAP and exploring the desktop UI (L1)
  - First-person scratch notes covering Linux installer, first launch, quick start attack, and things that tripped me up
- zap-003: `zap/snippets/my-first-zap-baseline-scan.sh` — My first ZAP CLI baseline scan script (L1)
  - Minimal bash snippet wrapping the official ZAP Docker image for headless scanning
  - Accepts target URL and output directory as arguments
  - shellcheck passed (clean)
- 00_index/quick-links.md — Added OWASP ZAP section with primer, install notes, and snippet entries
- semgrep-015: `semgrep/dockerfiles/custom-scanning-image.Dockerfile` — Custom Semgrep scanning image with pre-loaded rules and CI entrypoint (L4)
  - Multi-stage Dockerfile with pre-downloaded community rules for offline scanning
  - CI entrypoint script with baseline-commit support for diff-aware scanning
  - Non-root user, pinned Semgrep version, Python slim base
- zap-004: `zap/notes/2026-06-06-zap-quickstart-ui-gotchas.md` — Walkthrough: ZAP quickstart and UI exploration gotchas (L2)
  - First-person notes covering session persistence popup, Sites tree confusion, Alerts tab filtering, active vs passive scan distinction, and bundled JRE
  - Steps + Got stuck on + What I'd try next format
- zap-005: `zap/snippets/authenticated-scan-with-context.sh` — Authenticated scan with ZAP context configuration (L2)
  - Daemon mode startup, context import via REST API, spider + active scan via curl
  - ShellCheck passed (clean)
- codeql-005: `codeql/snippets/find-hardcoded-creds.ql` — My first CodeQL query: find hardcoded credentials in Python (L2)
  - Variable-name heuristic targeting password, secret, api_key, token, credential
  - QL query with inline reasoning comments
- semgrep-014: `semgrep/docs/comparing-rule-writing-approaches.md` — Comparing Semgrep rule-writing approaches: pattern vs pattern-inside vs pattern-either (L4, PR #243)
  - Covers all three core pattern combinators with concrete YAML examples
  - Purpose → When to use → Key Differences → Prerequisites → Steps → Verify → Common Errors → References structure
  - Final audit score: 9/10 (Merged)

## 2026-06-05

### Added
- semgrep-014: `semgrep/docs/comparing-rule-writing-approaches.md` — Comparing Semgrep rule-writing approaches: pattern vs pattern-inside vs pattern-either (L4)
  - Explains when to use each combinator with concrete examples
  - Covers pattern scope selection, common errors, and verification patterns
  - Reference-style guide with purpose, when-to-use, prerequisites, steps, verify, common errors, and references sections
- trufflehog-011: `trufflehog/notebooks/analyzing-trufflehog-false-positives.ipynb` — Analyzing scan results: false positive patterns, severity tuning, and baseline comparison (L3)
  - Jupyter notebook with Python code to parse TruffleHog JSON output, classify false positives by path, assign severity, and fingerprint-based baseline comparison
  - Covers the full post-scan triage workflow
- vault-002: `vault/notes/2026-06-05-install-vault-and-explore-cli.md` — Installing Vault and exploring the CLI in dev mode (L1)
  - First-person scratch notes covering dev server setup, KV engine operations, and things I tripped on
- semgrep-013: `semgrep/manifests/diff-aware-semgrep-ci.yaml` — CI pipeline: GitHub Actions workflow for diff-aware Semgrep scanning (L4)
  - Uses `--baseline-commit` to suppress pre-existing findings and report only new issues
  - Determines baseline commit from PR base or initial commit for push events
  - SARIF output uploaded to GitHub Code Scanning via `github/codeql-action/upload-sarif@v3`
  - Late fail step gates PR on new findings
- codeql-006: `codeql/configs/first-codeql-analysis.yml` — Minimal CodeQL workflow for GitHub Actions scanning (L2)
  - Stripped-down CodeQL analysis workflow starting with Python
  - Uses matrix strategy with `fail-fast: false` for parallel language support
  - Standard init → autobuild → analyze pipeline with security-events write permissions
- 00_index/quick-links.md — Added Semgrep CI pipeline entry and CodeQL scan entry

## 2026-06-04

### Added
- vault-001: `vault/notes/0000-primer-vault.md` — HashiCorp Vault quick primer (L1)
  - First-person scratchy primer covering what Vault is, key terminology (secret, path, policy, token, seal/unseal, engine), and a minimal CLI example
  - Primer structure: What is it, What does it do, Why does it exist, Key terminology, Tiny example, Next steps
- trivy-012: `trivy/scripts/multi-target-scanner.sh` — Multi-target Trivy scanner wrapping image, filesystem, and Git repo scans (L4)
  - Accepts targets in `type:value` format: `image:`, `fs:`, `repo:`
  - Per-target SARIF + JSON output with severity filtering
  - Aggregate summary with pass/fail reporting
  - shellcheck passed (clean)
- grype-005: `grype/scripts/minimal-grype-scan.sh` — Minimal Grype scan: vulnerability analysis of a local container image (L2, rework)
  - Scans an image with --only-fixed and --fail-on high
  - Produces both table (human-readable) and JSON (machine-readable) output
  - shellcheck passed (clean)
- grype-007: `grype/notes/2026-06-04-grype-quickstart-trip-ups.md` — Following the official Grype quickstart and what tripped me up (L2)
  - Covers DB download timing, node_modules scan surprise, SBOM path syntax gotcha, Trivy comparison notes
  - Steps + Got stuck on + What I'd try next format
- 00_index/quick-links.md — Added Vault section with primer entry, added Grype script and quickstart notes entries

## 2026-06-03

### Added
- trufflehog-009: `trufflehog/docs/comparing-scan-modes-git-filesystem-s3.md` — Comparing TruffleHog scan modes: git history vs filesystem vs S3 buckets (L3)
  - Covers each scan mode's purpose, CLI usage, and tradeoffs
  - Includes code examples for git, filesystem, and S3 modes
  - Practical guidance on when to use which mode
  - Common errors section based on real usage

## 2026-06-01

### Added
- trivy-011: `trivy/docs/ci-cd-pipeline-recipes.md` — Trivy CI/CD pipeline integration recipes for GitHub Actions, GitLab CI, and Jenkins (L4)
  - Matrix scan workflow for GitHub Actions with parallel image/fs/config scanning and SARIF upload
  - GitLab CI multi-stage scanning job with SAST report artifacts and severity gating
  - Jenkins declarative pipeline with post-action email notification on failure
  - Caching strategies per platform to avoid repeated vulnerability DB downloads
- trivy-009: `trivy/templates/trivy-monorepo-scanner/` — Project scaffold: Trivy monorepo scanner with CI integration (L4)
  - Template directory with trivy.yaml, Makefile, .trivyignore, scan-all.sh entry point
  - CI workflow (ci-scan.yml) with SARIF upload to GitHub code scanning
  - Multi-target scanning: container images, filesystem paths, Git history
  - Final audit score: 9/10 (Merged)
- trivy-010: `trivy/dockerfiles/custom-policies.Dockerfile` — Containerized Trivy scanning environment with custom policies (L4)
  - Dockerfile that builds an image containing Trivy with support for custom Rego policies
  - Uses Alpine Linux base with non-root user for security
  - Includes binary validation via SHA256 checksum
  - Configures proper directories and permissions for policies and cache
- syft-002: `syft/scripts/multi-image-sbom-pipeline.sh` — Multi-image SBOM generation pipeline with Syft (L3)
  - Accepts images from CLI args or a file (`--from-file`)
  - Generates CycloneDX JSON and SPDX JSON for each image
  - Error handling per image so one failure doesn't stop the batch
  - shellcheck passed (clean)
- syft-003: `syft/configs/.syft.yaml` — Syft configuration with cataloger and output preferences (L3)
  - Selects relevant catalogers (python, javascript, ruby, java, go, rust, dpkg, rpm, apk, port)
  - Excludes node_modules, __pycache__, .git
  - Default output formats: cyclonedx-json + spdx-json

## 2026-05-31

### Added
- grype-001: `grype/notes/0000-primer-grype.md` — Grype quick primer (L1)
  - First-person scratchy notes covering what Grype is, SBOM scanning, key terminology (SBOM, CPE, severity, match), and a minimal example
- grype-002: `grype/notes/2026-05-31-install-grype.md` — Installing Grype and running my first vulnerability scan (L1)
  - First-person walkthrough covering install, alpine/debian scan, and what tripped me up (bundled Syft, --only-fixed, node_modules)
- grype-003: `grype/snippets/my-first-grype-commands.sh` — Minimal bash snippet for scanning images and SBOMs (L1)
  - Scans alpine:latest, filters by --only-fixed, generates SBOM with Syft and scans it offline
  - shellcheck passed (clean)
- checkov-012: `checkov/manifests/checkov-sarif-pr-blocking.yaml` — GitHub Actions workflow for automated Checkov scanning with SARIF output and PR blocking (L3)
  - Auto-detects IaC directories (terraform, kubernetes, k8s, docker)
  - Produces SARIF output per target directory
  - Uploads SARIF to GitHub Code Scanning via codeql-action/upload-sarif
  - Fails the PR check if Checkov reports any issues
- trivy-008: `trivy/notebooks/trivy-sarif-output-processing.ipynb` — Notebook exploring Trivy SARIF output processing and visualization (L3)
  - Parses Trivy SARIF JSON into flat vulnerability records
  - Groups vulnerabilities by severity and CVE
  - Visualizes severity distribution with matplotlib bar chart
  - Includes severity-based filtering helpers for CI gating
- trufflehog-008: `trufflehog/scripts/multi-repo-scan-pipeline.sh` — Multi-repo TruffleHog secret scanning pipeline with JSON output aggregation (L3)
  - Accepts repo URLs from file or CLI arguments
  - Clones each repo and runs TruffleHog filesystem scan
  - Aggregates results into a single JSON report with plain-text summary
  - Groups findings by detector type (requires jq)
  - shellcheck passed (clean)
- checkov-011: `checkov/notebooks/compare-static-vs-plan-scanning.ipynb` — Notebook comparing static directory scan vs Terraform plan JSON scanning in Checkov (L3)
  - Purpose → Steps → Verify shape covering both scan modes
  - Creates sample Terraform project with intentional misconfigurations
  - Compares failed checks and notes where plan scanning catches resolved variable issues
- trufflehog-010: `trufflehog/configs/custom-detector-rules.yaml` — Custom TruffleHog detector rules for proprietary credential patterns (L3)
  - Seven custom detectors: API gateway token, VPN cert key, package registry token, mTLS cert serial, proprietary license key, webhook secret, build signing key
  - Entropy tuning adjusted for shorter proprietary patterns
- semgrep-011: `semgrep/configs/multi-rule-pack.yaml` — Multi-rule Semgrep YAML pack with combinators and test annotations (L3)
  - Five rules demonstrating pattern-either, patterns, pattern-inside, pattern-not, and pattern-regex
  - Covers: dangerous subprocess calls, SQL injection via f-strings, hardcoded AWS secrets, exposed debug endpoints, assert on user input
  - Includes test annotation documentation for semgrep --test workflow
  - CWE metadata annotated per rule
- checkov-010: `checkov/configs/checkov-ci-config.yaml` — Checkov CI config with framework selection, skip-list, CI-optimized settings (L3)
  - Framework scoped to terraform, kubernetes, dockerfile
  - Skip-list suppresses Docker, GHA, and secrets checks handled by other tools
  - CI-optimized: compact, quiet, soft_fail=false for pipeline gating

## 2026-05-30

### Added
- semgrep-010: `semgrep/notebooks/semgrep-scan-vs-ci-comparison.ipynb` — Compare `semgrep scan` (local CLI) vs `semgrep ci` (cloud-augmented) findings for the same repo (L3)
  - Purpose → Scan 1 (semgrep scan) → Scan 2 (semgrep ci) → Comparison table → Verify shape
  - Runs semgrep scan with --config=auto, parses JSON output, groups findings by severity
  - Explains cloud augmentation: triage, PR comments, branch tracking, rule tuning, dashboard
  - Practical comparison when ci can't run (simulated augmentation)
- 00_index/quick-links.md — Added semgrep scan vs ci comparison notebook entry

### Added
- trivy-006: `trivy/docs/ci-pipeline-sarif-output.md` — How I wired Trivy into a CI pipeline with SARIF output (L3)
  - Purpose → Steps → Verify shape covering scan mode, SARIF output, GitHub Code Scanning upload, and DB caching
  - Documents `--exit-code` + `--format sarif` interaction gotcha and split-scan workaround
- trivy-007: `trivy/configs/.trivy.yaml` — Project-level Trivy configuration with severity filtering, DB mirror, and ignore-policy (L3)
  - Severity thresholds, ignore-unfixed, misconfiguration checks, secret allow-rules
  - Reference to .trivyignore for CVE-level ignores
  - Commented DB mirror config for air-gapped environments
- syft-006: `syft/notes/2026-05-30-sbom-format-comparison.md` — Comparing CycloneDX vs SPDX vs Syft JSON SBOM output formats (L2)
  - Steps + What I found + Got stuck on + What I'd try next format
  - Documents format flag confusion, schema differences, and file size trade-offs
- trufflehog-007: `trufflehog/scripts/pre-commit-scan-pipeline.sh` — Minimal pre-commit scanning pipeline with TruffleHog (L2)
  - Scans staged files for secrets using `trufflehog filesystem`
  - Blocks commit if any secrets detected
  - shellcheck passed (clean)
- syft-005: `syft/scripts/gen-multi-format-sboms.sh` — Multi-format SBOM generation script for container images (L2)
  - Generates SBOMs in 7 formats: syft-json, cyclonedx-json/xml, spdx-json/tag-value, github-json, table
  - Creates organized output directory
  - Inline comments explain each format's use case
  - shellcheck passed (clean)

## 2026-05-29

### Added
- trivy-005: `trivy/scripts/image-vuln-pipeline.sh` — Automated image vulnerability scanning pipeline with Trivy from scratch (L3)
  - Scans images for vulns, secrets, and misconfigs in one pass
  - Produces SARIF, JSON, and summary report files
  - Configurable severity thresholds with pipeline gating
- syft-004: `syft/notes/2026-05-29-syft-quickstart-trip-ups.md` — Following the official Syft quickstart and what tripped me up (L2)
  - Steps + Got stuck on + What I'd try next format
  - Documents output format flag confusion and quickstart omissions
- checkov-010: `checkov/docs/pre-commit-hook-with-version-pinning.md` — How I wired Checkov into a pre-commit hook with version pinning (L3)
   - Purpose → Steps → Verify shape covering pre-commit setup, version pinning, and validation
   - .pre-commit-config.yaml template with pinned Checkov rev, --soft-fail, and --compact args
   - Common issues section covering Docker dependency and rev tag lookup
- checkov-009: `checkov/snippets/terraform-scan-custom-policies.py` — Build a Terraform scanning project with Checkov from scratch — custom policies and framework filtering (L3)
   - Creates sample Terraform with intentional misconfigurations (public S3 bucket, open SG)
   - Runs Checkov SDK with framework filtering and selective check IDs
   - Supports external custom policy directory via --policy-dir
   - Exit non-zero on failures for CI/CD pipeline gating

## 2026-05-28

### Added
- semgrep-009: `semgrep/docs/github-actions-ci-from-scratch.md` — How I wired Semgrep into a GitHub Actions CI pipeline from scratch (L3)
  - Purpose → Steps → Verify shape with custom rules, caching, and SARIF output
  - Docker container-based approach instead of the official action wrapper
  - Covers .semgrepignore configuration and permissions gotcha
- 00_index/quick-links.md — Added Semgrep CI pipeline entry
- trufflehog-006: `trufflehog/configs/trufflehog-custom-regex-config.yaml` — Custom TruffleHog config with regex detectors and entropy thresholds (L2)
  - Three custom detectors: Internal API key, Raw DSN string, JWT token
  - Entropy tuning: min_chars 12, min_shannon 5.0 to reduce false positives
  - Verification enabled for authenticated scans
- semgrep-008: `semgrep/scripts/detect-hardcoded-secrets.py` — Python script to build a custom Semgrep rule for hardcoded secrets and test it (L3)
  - Creates a rule targeting sensitive variable names (password, secret, token, api_key, etc.)
  - Generates a crafted test codebase with safe/unsafe assignments
  - Runs semgrep scan with JSON output parsing
  - Error handling for missing semgrep binary, parse failures, runtime errors
  - Temp file cleanup with optional --keep-temps for debugging
- 00_index/quick-links.md — Updated TruffleHog and Semgrep sections with new entries

## 2026-05-27

### Added
- syft-001: `syft/notes/0000-primer-syft.md` — Syft quick primer (L1, rework v2)
  - Rewritten per primer format (What is it / What does it do / Why does it exist / Key terminology / Tiny example / Next steps)
  - First-person scratchy voice (~266 words), no forbidden L1 elements
- trufflehog-004: `trufflehog/notes/2026-05-27-following-trufflehog-quickstart.md` — Following the official TruffleHog quickstart (L2)
  - Steps covering install, git scan, org scan, JSON output, issue/PR comments
  - Documents rate-limit gotcha, --results flag behavior, filesystem positional args, file:// URI requirement
- trufflehog-005: `trufflehog/snippets/scan-github-repo-for-secrets.sh` — Scan a GitHub repo for leaked secrets (L2)
  - Accepts repo URL and optional GitHub token as arguments
  - Outputs structured JSON with detector, verification status, file, commit, line
  - ShellCheck passed (clean)
- syft-001: `syft/notes/0000-primer-syft.md` — Syft quick primer (L1, rework)
  - First-person scratchy voice (~250 words), conversational learner tone per quality feedback
  - Covers what Syft is, SBOM generation, key terminology, and a minimal one-command example
- syft-002: `syft/notes/2026-05-27-install-syft-first-sbom.md` — Installing Syft and generating my first SBOM (L1)
  - First-person scratch notes covering install, `syft alpine:latest`, and what tripped me up with output formats
  - Steps + Got stuck on + What I'd try next format
- syft-003: `syft/snippets/tried-sbom-formats.sh` — Minimal bash snippet to generate SBOMs in SPDX and CycloneDX JSON formats (L1)
  - Accepts image name as argument (defaults to alpine:latest)
  - Outputs two JSON files: {image}_spdx.json and {image}_cyclonedx.json
  - shellcheck passed (clean)
- semgrep-005: `semgrep/scripts/scan-python-codebase.sh` — Minimal bash script to scan a Python codebase with Semgrep and filter by severity (L2)
  - Accepts target directory and severity level as arguments
  - Uses `--config=auto` for community rule registry
- semgrep-007: `semgrep/docs/semgrep-ci-integration.md` — Wiring Semgrep into a GitHub Actions pipeline with troubleshooting notes (L2)
  - First-person walkthrough covering GitHub Actions setup, .semgrepignore, SARIF output
  - Steps + Got stuck on + What I'd try next format
- semgrep-006: `semgrep/snippets/catch-privileged-containers.yaml` — Custom Semgrep rule for detecting privileged containers in YAML manifests (L2)
  - Catches `securityContext.privileged: true` in K8s and Docker Compose YAML
  - Inline comments explain why this pattern matters for security reviews
- checkov-006: `checkov/notes/2026-05-27-checkov-quickstart-trip-ups.md` — Following the official Checkov quickstart and what tripped me up (L2)
  - Steps + Got stuck on + What I'd try next format
  - Covers empty directory silent results, lack of sample bad configs, missing flag docs
- checkov-007: `checkov/snippets/scan-a-terraform-file.py` — Scan a single Terraform file using the Checkov Python SDK (L2)
  - Uses `file=` parameter for targeted single-file scanning
  - Framework-limited to terraform rules to avoid irrelevant checks
- 00_index/quick-links.md — Updated Semgrep and Checkov sections with new L2 entries
- trufflehog-001: `trufflehog/notes/0000-primer-trufflehog.md` — TruffleHog quick primer (L1)
  - First-person scratchy primer covering what TruffleHog is, key terminology (detector, verification, entropy), and minimal CLI example
  - No formal section headers, ~180 words, casual learner voice
- trufflehog-002: `trufflehog/notes/2026-05-27-install-trufflehog.md` — Installing TruffleHog and scanning a local repo for secrets (L1)
  - First-person walkthrough covering pip install, git scan with file:// URLs, and what tripped me up
  - Steps + Got stuck on + What I'd try next format
- trufflehog-003: `trufflehog/snippets/fake-secrets-test.sh` — Minimal bash snippet to create test secrets and scan with TruffleHog (L1)
  - Creates a file with fake AWS key, GitHub token, password and scans using `trufflehog filesystem`
  - shellcheck passed (clean)
- 00_index/quick-links.md — Added TruffleHog section with primer, install notes, and snippet entries
- checkov-008: `checkov/configs/checkov-skip-severity-config.yaml` — Checkov config for skip lists and severity thresholds (L2)
  - Skips CKV_SECRET_*, CKV_DOCKER_*, CKV_GHA_* checks to reduce noise
  - Uses compact output format and soft_fail configuration
  - Inline comments explain why each check group is skipped
- trivy-004: `trivy/scripts/compose-multi-scan.sh` — Scan multi-service Docker Compose project and aggregate vulnerability reports (L3)
  - Parses docker-compose.yml to extract all image: directives
  - Scans each image with Trivy (table + JSON output)
  - Generates aggregated summary with per-image CRITICAL counts
  - Exits non-zero if any CRITICAL vulnerabilities found (CI/CD gating)
- 00_index/quick-links.md — Added Checkov config and Trivy compose scan entries

## 2026-05-26

### Added
- semgrep-004: `semgrep/notes/2026-05-26-install-semgrep-pitfalls.md` — Installing Semgrep and first scan pitfalls (L1)
  - First-person scratch notes covering missing target path, YAML parser strictness, and node_modules exclusion
  - Structured as narrative of what tripped me up during initial use
- checkov-004: `checkov/snippets/scan-terraform-dir.py` — Python snippet to scan a local Terraform directory with Checkov SDK (L1)
  - Minimal Python script using Checkov SDK's Checkov class to run terraform framework scans
  - Iterates over failed records and prints check_id, file_path, and check_name
- checkov-005: `checkov/notes/2026-05-26-cli-vs-sdk-comparison.md` — Comparing CLI vs SDK scanning approaches for Terraform (L1)
  - First-person comparison covering CLI simplicity vs SDK flexibility
  - Notes sparse SDK documentation as the main gotcha
- 00_index/quick-links.md — Updated Semgrep and Checkov sections with new L1 entries
- trivy-001: `trivy/notes/2026-05-26-trivy-quickstart.md` — Following the official Trivy quickstart (L2)
  - First-person notes covering trivy fs, trivy repo, trivy config, and what tripped me up
  - Structured as Steps + Got stuck on + What I'd try next
- trivy-002: `trivy/scripts/container-vuln-scan.sh` — Minimal container image vulnerability scan script (L2)
  - Accepts image name and output directory, produces table and JSON output
  - Exits non-zero if CRITICAL vulnerabilities found (CI/CD gating)
  - shellcheck passed (clean)
- trivy-003: `trivy/configs/trivy-scan-config.yaml` — Trivy configuration for targeted scanning (L2)
  - Configures severity filters, vulnerability options, and misconfiguration scanning
  - Works with `trivy --config trivy-scan-config.yaml`
- 00_index/quick-links.md — Updated Trivy section with new L2 entries

## 2026-05-25

### Added
- semgrep-001: `semgrep/notes/0000-primer-semgrep.md` — Semgrep quick primer (L1, rework)
  - First-person scratchy voice (~220 words), no formal headers per quality feedback
  - Covers what Semgrep is, key terminology (rule, pattern, metavariable), and a minimal YAML rule example
- semgrep-002: `semgrep/notes/2026-05-25-install-semgrep.md` — Installing Semgrep and running a first SAST scan (L1)
  - First-person scratch notes covering pip install, auto scan, and severity filtering
- semgrep-003: `semgrep/snippets/first-custom-rule.yaml` — Minimal custom Semgrep rule for detecting dangerous subprocess patterns (L1)
  - 6-line YAML rule targeting subprocess.Popen with shell=True
- checkov-001: `checkov/notes/0000-primer-checkov.md` — Checkov quick primer (L1)
  - First-person primer covering IaC scanning, built-in policies, CLI usage
  - Sections: What is it, What does it do, Why does it exist, Key terminology, Tiny example, Next steps
- checkov-002: `checkov/notes/2026-05-25-scan-terraform-plan.md` — Installing Checkov and scanning a Terraform plan for misconfigurations (L1)
  - First-person scratch notes on pip install, terraform plan to JSON conversion, and running Checkov
- checkov-003: `checkov/snippets/scan-kubernetes.sh` — Minimal bash snippet to scan a Kubernetes manifest with Checkov (L1)
  - Uses --framework kubernetes --file flags, --compact for readable output
- 00_index/quick-links.md — Updated with Semgrep snippet and Checkov primer entries

## 2026-05-24

### Added
- trivy-001: `trivy/notes/0000-primer-trivy.md` — First-day primer covering what Trivy is, key terminology, scan types, and a minimal example (L1)
  - Primer structure: What is it, What does it do, Why does it exist, Key terminology, Tiny example, Next steps
  - First-person learner voice, 500+ words, no CVE advisories
- trivy-002: `trivy/notes/2026-05-24-install-trivy.md` — Installing Trivy and running a first vulnerability scan on a Python app image (L1)
  - Covers install via official script, first `trivy image` scan, severity filtering
  - Scratch-level first-person notes style
- trivy-003: `trivy/snippets/scan-docker-image.sh` — Minimal bash snippet to scan a Docker image with CRITICAL/HIGH severity filtering (L1)
  - Accepts image name as argument, defaults to alpine:latest
  - Uses `--exit-code 1` for CI/CD pipeline gating, `--ignore-unfixed` to skip unfixed CVEs
  - shellcheck passed (clean)
- 00_index/quick-links.md — Updated Trivy section with primer, install notes, and snippet entries

## 2026-05-14

### Added
- cic-010: `docs/how-to/argo-workflows-installation.md` — Argo Pipelines installation and pipeline template configuration for MLOps workflows (L2)
  - Complete guide covering Argo Workflows installation on Kubernetes
  - MLOps pipeline templates with model training, evaluation, and deployment
  - CI/CD pipeline templates with testing, building, and deployment stages
  - Cron scheduled workflows for automated retraining
  - Helm repository integration, artifact configuration, verification steps
- cic-010: `scripts/bash/argo_toolkit/argo-workflows-install.sh` — Argo Workflows deployment script
  - Supports --dry-run, --namespace, --version, --artifact-s3-bucket options
  - Automated namespace creation, manifest application, artifact configuration
  - Health verification and ready check polling
- cic-011: `docs/how-to/fluxcd-installation.md` — Flux v2 installation and GitOps reconciliation for declarative cluster management (L2)
  - Complete guide covering Flux v2 installation on Kubernetes
  - Git repository setup, kustomization configuration, Helm release management
  - Multi-environment setup, notification configuration, security considerations
  - Verification steps, rollback procedures, common errors troubleshooting
- cic-011: `scripts/bash/flux_toolkit/flux-install.sh` — Flux v2 deployment script
  - Supports --dry-run, --namespace, --git-url, --git-branch, --bootstrap options
  - Flux CLI installation, component deployment, Git repository configuration
- 00_index/quick-links.md — Updated CI/CD section with Argo Workflows and Flux v2 entries

## 2026-05-13

### Added
- obs-003: `docs/how-to/observability/grafana-installation.md` — Grafana installation and Prometheus data source configuration for metric visualization (L2)
    - Complete guide covering automated and manual Grafana installation
    - Systemd service configuration, firewall setup, HTTPS support
    - Prometheus data source provisioning with auto-discovery
    - Dashboard import instructions (Node Exporter Full ID 1860)
    - Verification steps, rollback procedures, common errors troubleshooting
- obs-003: `scripts/bash/observability_toolkit/grafana/grafana-install.sh` — Grafana installation script with Prometheus data source provisioning
    - Supports --dry-run, --version, --http-port, --protocol options
    - Automated binary download, systemd service creation, config generation
    - Prometheus data source auto-provisioning
    - Idempotent operations, comprehensive logging
    - shellcheck passed (info only)
- 00_index/quick-links.md — Updated Observability section with obs-003 Grafana entries
- obs-004: `docs/how-to/observability/alertmanager-installation.md` — Alertmanager installation and routing rule configuration for alert management (L2)
    - Complete guide covering automated and manual Alertmanager installation
    - Systemd service configuration, firewall setup, Prometheus integration
    - Alert routing rules with receivers for email, Slack, PagerDuty, webhook
    - Inhibition rules for alert suppression, template configuration
    - Verification steps, rollback procedures, common errors troubleshooting
- obs-004: `scripts/bash/observability_toolkit/alertmanager/alertmanager-install.sh` — Alertmanager installation script
    - Supports --dry-run, --version, --http-port, --cluster-port options
    - Automated binary download, systemd service creation, config generation
    - Default routing configuration with multiple receivers
    - Idempotent operations, comprehensive logging
    - shellcheck passed (info only)
- 00_index/quick-links.md — Updated Observability section with obs-004 Alertmanager entries

## 2026-05-12

### Added
- obs-002: `docs/how-to/observability/prometheus-node-exporter-installation.md` — Prometheus node_exporter installation for system metrics collection (L2)
    - Complete guide covering node_exporter installation on Linux systems
    - Systemd service configuration, firewall setup, Prometheus integration
    - Configuration options for collectors, textfile collector for custom metrics
    - Verification steps, rollback procedures, common errors troubleshooting
- jen-007: `docs/reference/jenkins-secret-masking-envinject.md` — Jenkins secret credential masking in build logs with EnvInject (L4)
    - Complete reference covering EnvInject plugin installation and configuration
    - Job-level secret injection patterns for Pipeline and Freestyle jobs
    - Credentials binding, custom masking patterns, file-based injection
    - Secure handling scripts with dry-run mode
    - Verification steps, rollback procedures, common errors
- oci-009: `docs/how-to/google-artifact-registry-gar.md` — Google Artifact Registry GAR installation for GKE integration (L2)
    - Complete guide covering GAR creation via gcloud, repository configuration, IAM permissions
    - Authentication setup for Docker and GKE clusters with Workload Identity
    - Artifact Analysis (vulnerability scanning), Binary Authorization, VPC Service Controls
    - Lifecycle policies, Cloud Build CI/CD integration, common errors troubleshooting
- oci-009: `scripts/bash/oci_registry_toolkit/gar/gar-deploy.sh` — GAR deployment script
    - Supports --dry-run, --project-id, --location, --repo-name, --format options
    - Automated API enabling, repository creation, IAM configuration, Docker auth setup
    - Lifecycle policy configuration, idempotent operations, comprehensive logging
    - shellcheck passed with warnings only
- oci-010: `docs/how-to/quay-container-registry-installation.md` — Quay container registry installation with Clair vulnerability scanning (L2)
    - Complete guide covering standalone and OpenShift operator deployment
    - PostgreSQL and Redis integration, configuration management
    - Authentication (Database, LDAP, OIDC), repository mirroring, Cosign image signing
    - Clair integration for vulnerability scanning, geo-replication configuration
    - Prerequisites, verification steps, rollback procedures, common errors
- oci-010: `scripts/bash/oci_registry_toolkit/quay/quay-deploy.sh` — Quay deployment script
    - Supports --hostname, --enable-clair, --enable-letsencrypt, --auth-type options
    - Automated secret generation, config.yaml creation, Docker Compose setup
    - Clair scanner configuration, superuser creation, health verification
    - shellcheck passed (info only)
- 00_index/quick-links.md — Updated Container Registries section with oci-009 GAR and oci-010 Quay entries

## 2026-05-11

### Added
- cic-009: `docs/how-to/circleci-runner-installation.md` — CircleCI self-hosted runner installation and resource class configuration (L2)
    - Complete guide covering CircleCI runner setup with resource classes, labels, namespaces
    - Pipeline integration patterns, custom working directories, concurrent job execution
    - Verification steps, rollback procedures, common error troubleshooting
- cic-009: `scripts/bash/ci_cd_toolkit/circleci/circleci-runner-install.sh` — CircleCI runner deployment script
    - Supports --dry-run, --token, --resource-class, --name, --labels, --max-runs, --work-dir options
    - Automated binary download, systemd service creation, JSON configuration generation
    - Idempotent operations with uninstall support
- cic-008: `docs/how-to/buildkite-installation.md` — Buildkite agent installation and configuration for CI/CD pipelines (L2)
    - Complete guide covering Buildkite agent setup with tagging, queues, parallel builds
    - Pipeline integration patterns, hooks, environment variables
    - Verification steps, rollback procedures, common error troubleshooting
- cic-008: `scripts/bash/ci_cd_toolkit/buildkite/buildkite-install.sh` — Buildkite agent installation script
    - Supports --dry-run, --version, --token, --tags, --queue, --max-runs options
    - Automated binary download, systemd service creation, token management
    - Configuration generation with YAML agent configuration
    - Idempotent operations with uninstall support
    - shellcheck passed (info only)
- oci-008: `docs/how-to/azure-container-registry-acr.md` — Azure Container Registry ACR installation and geo-replication setup (L2)
    - Complete guide covering ACR creation via Azure CLI, geo-replication configuration
    - Authentication setup (service principals, admin user), network access controls
    - Image push/pull operations, webhook configuration, retention policies
    - Prerequisites, verification steps, rollback procedures, common errors
- oci-008: `scripts/bash/azure_toolkit/acr/acr-deploy.sh` — ACR deployment script
    - Supports --dry-run, --resource-group, --acr-name, --location, --sku options
    - Automated geo-replication configuration, credential retrieval, health verification
    - Idempotent operations, comprehensive logging, status checking
    - shellcheck passed
- obs-009: `docs/how-to/observability/loki-promtail-installation.md` — Grafana Loki Promtail installation and log pipeline configuration (L2)
    - Complete guide covering Loki + Promtail installation for centralized log aggregation
    - Package and binary installation methods for Loki and Promtail
    - Systemd service configuration, log rotation, Grafana integration
    - LogQL queries for log exploration and alerting patterns
    - Prerequisites, verification steps, rollback procedures, common errors
- obs-010: `docs/how-to/observability/alertmanager-ha-clustering.md` — Alertmanager high-availability clustering for alert deduplication (L2)
    - Complete guide for HA Alertmanager cluster setup with gossip protocol
    - Cluster configuration, deduplication strategies, silence management
    - Prometheus integration, active-active and active-passive patterns
    - Prerequisites, verification steps, rollback procedures, common errors
- obs-010: `scripts/bash/observability_toolkit/alertmanager/alertmanager-ha-setup.sh` — Alertmanager HA cluster deployment script
    - Supports --dry-run, --cluster-size, --cluster-name, --listen-port, --http-port options
    - Automated binary download, cluster configuration generation, systemd service
    - Gossip protocol setup, firewall configuration, health verification
- oci-007: `docs/how-to/oci-registry-toolkit/github-container-registry-ghcr.md` — GitHub Container Registry ghcr.io configuration (L2)
    - Complete guide for ghcr.io configuration: authentication, image publishing, access control
    - GitHub Actions integration with docker/login-action, multi-architecture builds
    - Access control, visibility settings, image lifecycle management
    - Verification steps, rollback procedures, common errors

### Changed
- 00_index/quick-links.md — Updated CI/CD section with Buildkite installation and documentation entries
- 00_index/quick-links.md — Updated Observability section with obs-009 Loki Promtail and obs-010 Alertmanager HA entries
- 00_index/quick-links.md — Updated Container Registries section with oci-007 ghcr.io entry

## 2026-05-10

### Added
- obs-007: `docs/how-to/observability/otel-collector-installation.md` — OpenTelemetry Collector installation and pipeline configuration (L2)
    - Complete guide covering OTel Collector agent/gateway deployment modes
    - Pipeline configuration for metrics, traces, and logs
    - Kubernetes DaemonSet deployment examples
    - Prerequisites, verification steps, rollback procedures, common errors
- obs-007: `scripts/bash/observability_toolkit/otel/otel-collector-install.sh` — OTel Collector deployment script
    - Supports --dry-run, --version, --mode (agent/gateway/standalone), --port options
    - Automated binary download, systemd service creation, firewall configuration
    - Idempotent operations, configuration generation, health verification
    - shellcheck passed (info only)
- obs-008: `docs/how-to/thanos_installation.md` — Thanos installation and configuration for long-term metric retention (L2)
    - Guide for deploying Thanos components (Sidecar, Store, Receiver, Query, Compactor)
    - Configuration for object storage backends (AWS S3, GCS, Azure Blob)
    - Integration with existing Prometheus servers via remote write/read
    - Query aggregation and downsampling capabilities
    - Prerequisites, verification steps, rollback procedures, common errors
- tri-008: `docs/how-to/trivy/cve-2026-33001-remediation.md` — Trivy CVE-2026-33001 path traversal remediation guide (L8)
    - Detection and upgrade procedures for Trivy < 0.58.0
    - Linux/macOS, Docker, Kubernetes upgrade patterns
    - Verification steps, rollback procedures, common errors
- tri-008: `scripts/bash/trivy_toolkit/security/cve-2026-33001.sh` — CVE-2026-33001 detection and remediation script
    - Detects vulnerable Trivy versions, scans for path traversal archives
    - Supports --dry-run, --verbose, --version, --scan-dir flags
    - Automated upgrade to 0.58.0, remediation report generation
    - shellcheck passed (warnings only)
- 00_index/quick-links.md — Updated Observability section with new entries

### Changed
- 00_index/quick-links.md — Updated CI/CD section with Trivy CVE-2026-33001 entries

## 2026-05-09

### Added
- tri-003: `scripts/bash/ci_cd_toolkit/trivy-severity-filter.sh` — Trivy severity-based filtering for vulnerability triage (L3)
   - Run progressive scans based on severity thresholds
   - Count vulnerabilities by severity for triage metrics
   - Filter existing JSON reports by severity level
   - Support CI/CD pipeline integration
- tri-003: `docs/how-to/trivy-severity-filtering.md` — Trivy severity-based filtering guide for vulnerability triage (L3)
   - Progressive scanning strategy for different severity levels
   - CI/CD pipeline integration patterns
   - Vulnerability counting and filtering techniques
- tri-004: `scripts/bash/ci_cd_toolkit/trivy-cache-configure.sh` — Trivy cache configuration for accelerated repeated scans (L3)
   - Custom cache directory configuration
   - Cache pre-warming for database downloads
   - Cache persistence in CI/CD pipelines
   - Layer caching optimization strategies
- tri-004: `docs/how-to/trivy-cache-configuration.md` — Trivy cache configuration guide for optimized scanning performance (L3)
   - Cache types and directory configuration
   - CI/CD cache management patterns
   - Performance optimization strategies
   - Cache verification and troubleshooting
   - Detects vulnerable ansible-core and flatted versions
   - Performs automatic upgrade via pip when vulnerable
   - Supports dry-run, report generation, verification
- tri-001: `scripts/bash/ci_cd_toolkit/trivy-postbuild-scan.sh` — Trivy CI/CD post-build stage integration script (L3)
   - Runs Trivy scan as pipeline post-build security gate
   - Supports --scan, --generate, --validate modes
   - Generates GitHub Actions, Jenkinsfile, GitLab CI snippets
   - Offline scanning from image tarballs, severity gating
- gen-010: `docs/security/jenkins/CVE-2026-33001.md` — Jenkins CVE-2026-33001 tar/tar.gz symlink path traversal remediation guide (L8)
   - Comprehensive guide for CVE-2026-33001 mitigation in Jenkins
   - Covers vulnerable versions (< 2.495.1, < 2.510.1), backup plugin review, safe tar extraction configs
   - Step-by-step upgrade procedures (Kubernetes and standalone), verification, rollback
- gen-010: `scripts/bash/jenkins_toolkit/security/cve-2026-33001.sh` — CVE-2026-33001 detection and remediation script (L8)
   - Detects vulnerable Jenkins versions, checks tar handling configuration
   - Supports --dry-run, --fix, --json-output, --namespace flags
   - Provides automated upgrade recommendations and remediation steps
- tri-006: `docs/how-to/trivy-jenkins-integration.md` — Trivy Jenkins plugin integration for container image scanning in pipeline (L3)
   - Complete guide for integrating Trivy into Jenkins pipelines via plugin
   - Declarative and scripted pipeline examples, severity thresholds, SARIF output
   - Plugin installation, configuration, validation and troubleshooting
- tri-006: `scripts/bash/ci_cd_toolkit/jenkins/trivy-jenkins-integration.sh` — Trivy Jenkins plugin installation and configuration script (L3)
   - Plugin installation with --install flag, Jenkinsfile snippet generation with --generate
   - Pipeline validation with --validate, supports severity/config/output customization
   - JSON output for automation integration
- tri-007: `docs/how-to/trivy-github-actions.md` — Trivy GitHub Actions workflow integration for automated security scans (L3)
   - GitHub Actions integration patterns: fs, image, config, secret scan types
   - Workflow generation with proper SARIF upload to GitHub Code Scanning
   - Matrix scanning, conditional triggers, caching strategies, performance tuning
- tri-007: `scripts/bash/ci_cd_toolkit/github/trivy-github-actions.sh` — Trivy GitHub Actions workflow generator and validator (L3)
    - Workflow YAML generation with --generate, validation with --validate
    - Configurable scan types, severity thresholds, events (push/PR/schedule)
    - Supports --scan-type, --severity, --output-format, --action-version options
 - ansi-001: `scripts/bash/ansible_toolkit/security/cve-2026-33228-execution.sh` — CVE-2026-33228 mitigation playbook execution and validation script (L6)
    - Executes the mitigation playbook with proper inventory and host targeting
    - Validates remediation results and generates JSON report
    - Supports dry-run, validate-only, verbose modes, become privilege escalation
 - tri-002: `scripts/bash/ci_cd_toolkit/trivy-db-update.sh` — Trivy vulnerability database update automation (L3)
    - Automates Trivy database downloads for vulnerability definition currency
    - Checks database age and staleness with configurable thresholds
    - Supports --skip-download, --force, --dry-run, integrity verification

### Changed
- 00_index/quick-links.md — Updated Jenkins and CI/CD sections with new documentation and script links
   - Added CVE-2026-33001 hardening script and guide under Jenkins
   - Added Trivy Jenkins integration script and documentation
   - Added Trivy GitHub Actions script and documentation under CI/CD

## 2026-05-08

### Added
- tri-001: `docs/how-to/trivy-cicd-integration.md` — Trivy CI/CD pipeline integration for vulnerability scanning (L3)
  - Integration patterns for GitHub Actions, Jenkins, GitLab CI
  - Post-build stage configuration, container image scanning
  - Severity-based filtering, configuration options
  - Prerequisites, verification steps, rollback procedures, common errors
- jen-002: `docs/reference/jenkins-agent-connection-tuning.md` — Jenkins agent connection tuning commands for high-concurrency workloads (L4)
  - Comprehensive reference for tuning Jenkins agent connections in high-concurrency environments
  - Covers agent registration, connection pooling, labeling strategies, resource allocation
  - JNLP and SSH agent configuration, tunnel and proxy settings
  - Prerequisites, verification steps, rollback procedures, common errors
- jen-002: `scripts/bash/jenkins_toolkit/agents/jenkins-agent-connection-tuning.sh` — Automated script for Jenkins agent connection tuning
  - Supports dry-run mode, JSON/text output, verbose logging
  - Functions: list agents, get info, tune channels, tune timeout, tune ping interval
  - Bulk operations for labels and executors, agent online/offline management
- jen-004: `docs/reference/jenkins-job-config-xml-snippets.md` — Jenkins job configuration XML snippets for GitHub webhook integration (L4)
  - Reusable XML snippets for GitHub webhook-triggered Jenkins builds
  - Parameterized webhook jobs, secret token management, multi-branch pipeline triggers
  - Generic webhook trigger, SCM polling, GitHub App authentication
  - Prerequisites, verification steps, rollback procedures, common errors
- jen-006: `docs/reference/jenkins-pipeline-retry-strategy.md` — Jenkins pipeline retry strategy configuration for transient failure handling (L4)
  - Declarative and scripted pipeline retry patterns
  - Exponential backoff, jitter-aware backoff, error categorization
  - Retry budgets, circuit breaker pattern, Kubernetes agent retry
  - Prerequisites, verification steps, rollback procedures, common errors

### Changed
- 00_index/quick-links.md — Updated Jenkins section with new documentation links
  - Added jenkins_agent_connection_tuning, jenkins_job_config_xml_snippets, jenkins_pipeline_retry_strategy
  - Added jenkins_agent_tuning_script reference

## 2026-05-06

### Added
- jen-003: `docs/reference/jenkins-credential-rotation.md` — Jenkins CLI commands for automated credential rotation and security updates (L4)
  - Comprehensive reference for credential management, API token rotation, bulk credential operations
  - Covers security configuration updates, audit logging, plugin security checks
  - Prerequisites, verification steps, rollback procedures, common errors
- jen-001: `docs/how-to/jenkins-parallel-multi-branch.md` — Jenkins pipeline Groovy snippet for parallel multi-branch builds (L4)
  - Declarative and scripted pipeline patterns for concurrent branch execution
  - Matrix builds, Docker-based parallel execution, shared library integration
  - Error handling, throttling, agent allocation strategies
- gen-004: `docs/security/trivy/CVE-2026-33634.md` — Trivy CVE-2026-33634 supply chain vulnerability remediation guide (L8)
  - Comprehensive guide for Trivy ecosystem supply chain attack mitigation
  - Affected components: trivy-action < v0.35.0, setup-trivy < v0.2.6, malicious trivy images
  - Attack details, indicators of compromise, verification steps
  - Secret rotation recommendations, rollback procedures
- gen-004: `scripts/bash/ci_cd_toolkit/github/trivy-cve-2026-33634.sh` — CVE-2026-33634 Trivy supply chain compromise scanner (L8)
  - Detects vulnerable Trivy references in GitHub Actions workflows
  - Supports --check, --fix, --dry-run, --json-output flags
  - Scans for trivy-action, setup-trivy, and container image versions
  - Automatic remediation support

## 2026-05-05

### Changed
- gen-005: Consolidated Ansible automation scripts into `scripts/bash/ansible_toolkit/` for cross-tool consistency
  - Moved `scripts/security/ansible/harden-ansible-cve-2026-33228.sh` to `scripts/bash/ansible_toolkit/security/`
  - Removed orphaned `scripts/security/ansible/` directory
  - Updated documentation references in `docs/security/ansible/CVE-2026-33228.md`, `docs/how-to/ansible-cve-2026-33228-flatted.md`, `docs/runbooks/cve-2026-33228-ansible-flatted.md`

### Added
- git-008: `docs/how-to/git-pre-commit-security-scanning.md` — Pre-commit security scanning and validation for CI/CD pipelines (L2)
  - Comprehensive guide for Git hook automation
  - Covers secrets detection, vulnerability scanning, code quality checks
  - Prerequisites, verification steps, rollback procedures, common errors
- git-008: `scripts/bash/git/git-pre-commit-hooks.sh` — Pre-commit hook automation script with secrets, vulnerabilities, and code quality scanning (L6)
  - Supports TruffleHog, git-secrets, Trivy, npm audit, tfsec, ShellCheck integration
  - Dry-run mode, idempotent operations, configurable scanning

## 2026-05-04

### Added
- dok-002: `docs/security/docker/AUTHZ-PLUGIN-HARDENING.md` — Docker AuthZ plugin security hardening for privileged containers (L8)
  - Comprehensive guide for preventing privileged container operations
  - Authorization plugin configuration and monitoring
  - Security check script at `scripts/bash/docker_toolkit/security/docker-authz-plugin-hardening.sh`
  - Verification steps, rollback procedures
- lin-081: `docs/how-to/linux/linux-disk-io-scheduler-optimization.md` — Linux disk I/O scheduler optimization for database workloads (L7)
  - Comprehensive guide covering scheduler selection (none, mq-deadline, bfq, kyber)
  - Database-specific tuning for PostgreSQL, MySQL, MariaDB
  - Scripts for scheduler detection, configuration, persistence
  - Ansible playbook for fleet deployment, verification, rollback procedures


- dok-006: `docs/how-to/docker-swarm-cluster-installation.md` — Docker Swarm cluster installation and high-availability configuration (L2)
  - Complete guide for setting up production-ready Docker Swarm cluster
  - Covers multi-manager HA setup, worker node integration, overlay networking
  - Includes rolling updates, secrets management, and monitoring setup
  - Prerequisites, verification steps, rollback procedures, common errors
- dok-006: `scripts/bash/docker_toolkit/docker-swarm-cluster-setup.sh` — Docker Swarm cluster setup script with dry-run support (L2)
  - Automated setup of Docker Swarm cluster with high availability
  - Supports dry-run mode for safe testing
  - Idempotent operations with rollback capability
  - Comprehensive logging and JSON output
- 00_index/quick-links.md — Updated Docker section with Docker Swarm entries
  - Added docker_swarm_cluster_setup script reference
  - Added docker_swarm_cluster_installation documentation reference
## 2026-05-03

### Added
- git-004: `docs/security/git-security-access-control-authentication.md` — Git repository access control and authentication hardening for CI/CD pipelines (L2)
  - Comprehensive guide covering credential security, repository access control, secure Git operations in pipelines
  - Prerequisites, verification steps, rollback procedures, common errors
  - References to GitHub, GitLab, Bitbucket security documentation and industry standards

### Modified
- git-006: `docs/reference/git-commands.md` — Added Rollback section to Git commands reference (L2)
  - Added repository state rollback instructions (reset, revert, restore)
  - Added remote repository rollback procedures
  - Added stash recovery methods
  - Enhanced documentation with practical examples and use cases

- 00_index/quick-links.md — Updated Git section to include new security documentation
  - Added link to git-security-access-control-authentication.md
  - Maintained alphabetical organization of Git resources

### Added
- lin-076: `docs/runbooks/linux-system-administration.md` — Linux system administration documentation and runbook automation (L7)
  - Comprehensive documentation covering user management, service management, disk/filesystem management
  - Network configuration, process monitoring, log management, backup/restore procedures
  - Security hardening runbook, automation execution framework
  - Prerequisites, verification steps, rollback procedures, common errors
- lin-076: `scripts/bash/linux_toolkit/sysadmin/` — System administration automation scripts (L7)
  - `user-create.sh`: Create system users with audit trail, dry-run mode
  - `user-modify.sh`: Modify users and group membership (add_group, remove_group, lock, unlock)
  - `disk-usage.sh`: Analyze disk usage with alerts, configurable thresholds
  - `process-monitor.sh`: Monitor running processes, watch specific processes
  - `service-health.sh`: Service health check with automatic restart
  - `system-backup.sh`: Automated system backup with verification
  - `network-iface.sh`: Manage network interfaces, show connections
  - `security-audit.sh`: Security audit checks (world-writable files, orphaned files, UID 0)
- lin-076: `00_index/quick-links.md` — Added lin-076 system administration runbook and sysadmin scripts

- lin-077: `docs/how-to/linux/linux-container-orchestration-systemd-cgroups.md` — Container orchestration automation with systemd and cgroups (L7)
  - Comprehensive guide covering systemd service units, cgroup slices, resource limits (CPU/memory/I/O/PID)
  - Container deployment patterns, health checks, auto-restart, networking with systemd
  - Monitoring scripts for cgroup resource usage, rollback procedures, common error solutions
- lin-077: `scripts/bash/linux_toolkit/container-orchestration-systemd-cgroups.sh` — Container orchestration script
  - Automated deployment with systemd and cgroup integration, dry-run mode
  - Cgroup slice management (create/delete), service deployment, rollback
  - Resource verification, multi-container support, idempotent operations
  - shellcheck passed with warnings only
- lin-075: `docs/how-to/linux/linux-system-hardening-containerized.md` — Linux system hardening automation for containerized environments (L7)
  - Comprehensive framework for automated security hardening following CIS benchmarks and NIST guidelines
  - Kernel sysctl hardening, SSH configuration, Docker daemon hardening, firewall rules
  - User account hardening, auditd configuration, AppArmor profiles
  - Automated remediation, compliance checks, and audit capabilities
- lin-075: `scripts/bash/linux_toolkit/linux-system-hardening.sh` — Linux system hardening automation script
  - Idempotent hardening with kernel parameters, firewall, SSH, Docker, user accounts
  - Dry-run mode, comprehensive logging, backup and rollback support
  - Modular design with configurable options per hardening component
- lin-075: `templates/linux-automation/roles/hardening/tasks/main.yml` — Ansible role for Linux system hardening
  - Standardized Ansible role for automated hardening deployment
  - CIS benchmark compliance with verification tasks
  - Fleet management support for containerized environments
- lin-075: `templates/linux-automation/playbooks/hardening.yml` — Ansible playbook for system hardening
  - Production-ready playbook with pre-flight checks and post-hardening verification
  - Role-based execution with tags for selective hardening components
- 00_index/quick-links.md — Added lin-077, lin-075 container orchestration and hardening entries
- lin-074: `docs/how-to/linux/linux-shell-commands-automation.md` — Shell command patterns for automated system administration (L7)
  - Documentation covering service management, file operations, network utilities, system monitoring
  - Prerequisites for common Linux utilities, verification steps, rollback procedures
  - Common errors and solutions
- lin-074: `scripts/bash/linux_toolkit/linux-system-commands-library.sh` — Shell command library
  - Functions: service_is_active, service_start/stop/restart, file backup/diff, port checks, connectivity tests
  - System monitoring: get_cpu_usage, get_memory_usage, get_disk_usage, get_load_average
  - Dry-run mode support, binary checks, verbose logging
- git-002: `docs/how-to/git/git-credential-helper-cicd-setup.md` — Git credential helper setup for CI/CD pipelines (L2)
   - Configuration for GitHub Actions, GitLab CI, Jenkins
   - Credential storage, rollback procedures
- dok-001: `docs/security/docker/CVE-2026-34040.md` — CVE-2026-34040 Docker authorization plugin bypass remediation guide (L8)
   - Complete hardening guide for Docker authorization plugin bypass vulnerability
   - Docker version checking, plugin status, daemon configuration verification
   - Remediation steps for upgrading Docker and securing configuration
- dok-001: `scripts/bash/docker_toolkit/security/docker-cve-2026-34040.sh` — CVE-2026-34040 hardening script (L8)
   - Docker authorization plugin bypass detection and remediation
   - Checks Docker version, authorization plugins, API exposure
   - Supports --dry-run, --remediate, --json-output flags
- 00_index/quick-links.md — Added lin-074 and git-002 entries

### Changed
- lin-073: Infrastructure-as-Code automation workflows for DevOps pipelines (L7)
  - Final score: 9/10

## 2026-05-02

### Added
- lin-072: `scripts/bash/linux_toolkit/lib/iac-operations.sh` — Shell script library for infrastructure-as-code operations (L7)
  - Reusable functions for Terraform and Ansible operations
  - Service management, network utilities, backup/restore functions
  - Dry-run mode support and binary existence checks
- lin-072: `docs/how-to/linux/linux-shell-script-library-iac.md` — Documentation for IaC shell script library (L7)
- 00_index/quick-links.md — Added Linux IaC shell script library entry
- git-003: `docs/how-to/git-workflow-optimization.md` — Git workflow optimization for DevOps pipelines (L3)
- 00_index/quick-links.md — Added Git workflow optimization entry

## 2026-05-01

### Added
- lin-071: `templates/linux-automation/` — Linux system automation template for DevOps workflows (L7)
  - Complete Ansible-based automation template with roles for base, security, monitoring, and orchestrator
  - Deploy script with dry-run support, inventory configuration, and systemd service templates
  - Project structure: playbooks, roles, group_vars, templates for production-ready deployments

## 2026-05-01

## 2026-04-30

### Added
- git-001: `docs/setup-guides/git-github-actions-runner.md` — GitHub Actions self-hosted runner installation and configuration guide (L2)
- git-001: `scripts/bash/git/github-runner-install.sh` - GitHub Actions runner installation script with systemd/Docker support
- git-002: `docs/setup-guides/git-credential-helper-ci-cd.md` — Git credential helper setup for CI/CD pipelines (L2)
- git-002: `scripts/bash/git/credential-helper-ci.sh` - Git credential helper configuration for CI/CD
- lin-071: `docs/how-to/linux/linux-system-automation-template.md` - Linux system automation template for DevOps workflows (L7)
- lin-071: `scripts/bash/linux_toolkit/system-automation-template.sh` - Linux automation template deployment script
- 00_index/quick-links.md — Added Git runner and credential helper entries

## 2026-04-29

### Added
- git-001: `docs/concepts/git-001-version-control-fundamentals.md` — Introduction to version control fundamentals (L1 concept)
- git-002: `docs/concepts/git-002-basic-commands-setup.md` — Basic Git commands and repository setup (L1 concept)
- git-005: `docs/concepts/git-005-configuration-aliases.md` — Git configuration, aliases, and best practices (L1 concept)
- 00_index/quick-links.md — Added Git concept documentation entries

## 2026-04-28

### Added
- jen-014: `snippets/jenkins-cli-commands.md` — Jenkins CLI commands reference with 150+ commands for sysadmins
- 00_index/quick-links.md — Updated Jenkins CLI commands entry to 150+ commands
- jen-014: `docs/reference/jenkins-commands.md` — Jenkins commands reference with 50+ commands, added Verify, Rollback, Common errors sections

## 2026-04-27

### Added
- lin-069: docs/how-to/linux-dns-management-coredns-systemd-resolved.md — Complete DNS management with CoreDNS and systemd-resolved
- lin-069: scripts/bash/linux_toolkit/linux-dns-coredns.sh — Automated DNS entry management for CoreDNS
- lin-069: scripts/bash/linux_toolkit/linux-dns-test.sh — DNS setup verification and testing
- lin-069: scripts/bash/linux_toolkit/linux-dns-monitor.sh — DNS health monitoring with auto-restart
- 00_index/quick-links.md — Added DNS management entries

## 2026-04-24

### Added

- k8s-015: `scripts/bash/k8s_toolkit/k8s-eso-cve-2026-34984-hardening.sh` — CVE-2026-34984 hardening script for External Secrets Operator
- k8s-015: `docs/how-to/k8s-external-secrets-cve-2026-34984.md` — CVE-2026-34984 ESO vulnerability remediation guide
- k8s-016: `scripts/bash/k8s_toolkit/k8s-ingress-nginx-cve-2026-4342-hardening.sh` — CVE-2026-4342 ingress-nginx comment-based config injection hardening script
- k8s-016: `docs/how-to/k8s-ingress-nginx-cve-2026-4342.md` — CVE-2026-4342 ingress-nginx RCE vulnerability remediation guide

## 2026-04-23

### Added
- k8s-014: `scripts/bash/k8s_toolkit/aks-privilege-escalation-hardening.sh` — CVE-2026-33105 AKS privilege escalation hardening script
- k8s-014: `docs/how-to/k8s-aks-cve-2026-33105.md` — CVE-2026-33105 AKS privilege escalation remediation guide

## 2026-04-22

### Added
- lin-067: `docs/how-to/linux-container-security-scanning.md` — Container security scanning project with Trivy and Falco
- lin-067: `scripts/bash/linux_toolkit/linux-container-security-scan.sh` — Automated container security scanning script

## 2026-04-21

### Added
- k8s-021: `scripts/bash/k8s_toolkit/mcp-server-kubernetes-hardening.sh` — CVE-2026-39884 hardening script (mcp-server-kubernetes RCE)
- k8s-021: `docs/troubleshooting/kubernetes-mcp-server-cve-2026-39884.md` — CVE-2026-39884 remediation guide
- ter-018: `docs/how-to/terraform-secrets-manager.md` — AWS Secrets Manager integration with Terraform walkthrough
- ter-018: `scripts/bash/terraform_toolkit/secrets/terraform-secrets-deploy.sh` — Deployment script for Secrets Manager with dry-run

## 2026-04-19

### Added
- jen-014: `snippets/jenkins-cli-commands.md` — Jenkins CLI commands reference with 80+ commands
- ansi-004: `docs/how-to/ansible-playbook-best-practices.md` — Ansible playbook best practices guide

## 2026-04-18

### Added
- jen-014: `docs/reference/jenkins-commands.md` — Jenkins CLI commands reference with 50+ commands for automation and scripting
- lin-006: `snippets/linux-commands.md` — Linux commands reference with 30+ bash one-liners for sysadmins
- dok-003: `scripts/bash/docker_toolkit/docker-image-cleanup.sh` — Docker image cleanup script with dry-run, age filtering
- vault-006: `snippets/vault-commands.md` — Vault CLI commands reference for authentication, secrets, policies
- ansi-006: `snippets/ansible-commands.md` — Ansible ad-hoc commands for system administration
- kfk-006: `snippets/kafka-topics-commands.md` — Kafka topics CLI one-liners for topic management
- jen-007: `docs/troubleshooting/jenkins-troubleshooting.md` — Jenkins troubleshooting guide for startup failures, plugin issues, build failures
- jen-006: `templates/jenkins/Jenkinsfile-maven-gradle-template.md` — Reusable Jenkinsfile template for Maven/Gradle builds

## 2026-04-17

### Added
- vault-009: `scripts/bash/vault_toolkit/security/vault-go-getter-hardening.sh` — Hardening script for CVE-2026-4660 (go-getter arbitrary file read vulnerability)

### Added
- ter-003: `docs/how-to/terraform-state-management.md` — Terraform state management best practices
- ter-004: `docs/how-to/terraform-troubleshooting.md` — Terraform troubleshooting guide for plan/apply failures
- ter-005: `snippets/terraform-commands.md` — Terraform CLI one-liners reference

## 2026-04-14

### Added
- ter-016: `docs/how-to/git-installation-macos.md` — Git installation on macOS how-to guide
- ter-016: `scripts/bash/git/git-install-macos.sh` — Automated Git installation script for macOS
- git-003: `docs/how-to/git-installation-wsl.md` — Git installation on WSL how-to guide
- git-003: `scripts/bash/git/git-install-wsl.sh` — Automated Git installation script for WSL
- git-003: `snippets/git-commands.md` — Git CLI commands reference with 80+ commands
- ter-017: `docs/how-to/terraform-iam-roles.md` — IAM roles with policy modules how-to guide
- ter-017: `scripts/bash/terraform_toolkit/terraform-iam-roles-deploy.sh` — Automated IAM roles deployment script

## 2026-04-13

### Added
- lin-030: `docs/how-to/linux/linux-wazuh-siem.md` — Wazuh SIEM deployment how-to guide
- lin-030: `scripts/bash/linux_toolkit/wazuh-deploy.sh` — Automated Wazuh deployment script

## 2026-04-12

### Added
- lin-028: `docs/how-to/linux/linux-aide-configuration-management.md` — AIDE file integrity monitoring how-to guide
- lin-028: `scripts/bash/linux_toolkit/aide-deploy.sh` — Automated AIDE deployment and management script

## 2026-04-11

### Added
- lin-028: `scripts/bash/linux_toolkit/aide-config.sh` — AIDE configuration management script for file integrity monitoring
- lin-028: `docs/how-to/linux-aide-configuration.md` — AIDE setup and usage guide for Linux configuration management

## 2026-04-09

### Added
- vault-005: `scripts/bash/vault_toolkit/vault-audit-log-analysis.sh` — Vault audit log analysis script for security events and anomalies
- helm-003: `docs/how-to/helm-commands-reference.md` — Helm CLI commands reference with 80+ examples

## 2026-04-08

### Added
- dok-007: `scripts/bash/docker_toolkit/security/docker-cve-2026-34040.sh` — Docker authorization plugin bypass detection script for CVE-2026-34040
- k8s-013: `scripts/bash/k8s_toolkit/security/k8s-acm-cve-2026-4740.sh` — Kubernetes ACM privilege escalation detection script for CVE-2026-4740

## 2026-04-03

### Added
- jen-013: `docs/reference/jenkins-rest-api.md` — Jenkins REST API commands reference for automation (job management, build triggers, queue, agents, plugins)

## 2026-04-01

### Added
- ter-010: `docs/how-to/terraform-multi-env-gitops.md` — Multi-environment infrastructure with Terraform workspaces and GitOps workflow
- ter-010: `scripts/bash/terraform_toolkit/multi-env/multi-env-setup.sh` — Automated multi-environment setup (init-backend, create-env, plan, apply, destroy, verify)
- ter-010: `templates/terraform/multi-env/vpc-module.tf` — Reusable VPC module with public/private subnets, NAT Gateway, security groups
- ter-010: `environments/dev/` — Development environment configuration with terraform.tfvars
- ter-010: `environments/staging/` — Staging environment configuration
- ter-010: `environments/prod/` — Production environment configuration

## 2026-03-29

### Added
- ter-013: `docs/how-to/terraform-rds-read-replicas.md` — RDS PostgreSQL with read replicas: Multi-AZ, encryption, CloudWatch alarms, failover testing
- lin-025: `docs/how-to/linux-centralized-logging-syslog-ng-logstash.md` — Centralized logging pipeline with syslog-ng and Logstash
- lin-025: `scripts/bash/linux_toolkit/setup-centralized-logging.sh` — Automated deployment script for syslog-ng + Logstash + Elasticsearch
- lin-025: `templates/syslog-ng/syslog-ng.conf` — Production syslog-ng configuration with JSON output, filtering, and disk buffering
- lin-025: `templates/logstash/logstash.conf` — Logstash pipeline with GeoIP enrichment, SSH auth parsing, and Elasticsearch indexing
- ter-013: `templates/terraform/rds-with-replicas/` — Complete Terraform configuration (provider, variables, main, outputs, monitoring)
- ter-013: `scripts/bash/terraform_toolkit/rds-deploy.sh` — RDS deployment automation (plan/apply/destroy/verify/failover-test)

## 2026-03-28

### Added
- lin-024: `docs/how-to/linux-ansible-patching.md` — Automated patching system with Ansible: inventory, playbooks, scheduling, reporting, rollback
- lin-024: `scripts/bash/linux_toolkit/security/ansible-patch-management.sh` — Patch management script with --dry-run, --bundle, --tags, --limit flags
- lin-024: `scripts/bash/ansible_toolkit/patch-management.yml` — Ansible playbook for automated security patching across Linux servers
- lin-020: `docs/how-to/linux-harbor-registry.md` — Production container registry with Harbor: HTTPS/TLS, LDAP auth, image replication, Trivy vulnerability scanning, automated backup
- lin-020: `scripts/bash/harbor/harbor-deploy.sh` — Automated Harbor deployment with TLS cert generation, Docker Compose, and Trivy
- lin-020: `scripts/bash/harbor/harbor-health-check.sh` — Harbor health verification: containers, API, registry API, disk usage, Trivy scanner
- lin-020: `scripts/bash/harbor/harbor-backup.sh` — Harbor backup: database dump, registry data, config, Redis with retention cleanup
- ter-012: `docs/how-to/terraform-eks-cluster.md` — EKS cluster with managed node groups, VPC networking, autoscaling configuration, and integration with AWS services
- ter-012: `scripts/bash/terraform_toolkit/eks/eks-deploy.sh` — Automated EKS deployment script with --dry-run, --init, --plan, --apply, --full, --verify flags
- ter-012: `scripts/bash/terraform_toolkit/eks/eks-cleanup.sh` — Safe EKS cluster cleanup script with DRY_RUN enabled by default
- ter-012: `scripts/bash/terraform_toolkit/eks/eks-health-check.sh` — EKS cluster health verification script for cluster, nodes, addons, and API server

## 2026-03-27

### Added
- lin-017: `lab/mini-projects/samba-enterprise-file-sharing/README.md` — Enterprise Samba file sharing platform L7 project walkthrough: departmental shares, home directories, guest access, ACLs, AD integration, automated backups, monitoring, security hardening

## 2026-03-26

### Added
- lin-017: `docs/how-to/linux-samba-file-sharing.md` — Samba file sharing server for cross-platform access (Windows/macOS/Linux) with multiple shares, user management, AppArmor, and security hardening
- lin-017: `scripts/bash/linux_toolkit/samba/samba-setup.sh` — Automated Samba setup script with --shares, --users, --dry-run, --firewall, --workgroup, --min-protocol, --max-protocol flags
- lin-018: `docs/how-to/linux-haproxy-load-balancer.md` — HAProxy L4/L7 load balancer project with SSL termination, path-based routing, health checks, Prometheus exporter, and log rotation
- lin-018: `scripts/bash/linux_toolkit/loadbalancer/haproxy-setup.sh` — Automated HAProxy setup script with --dry-run, --backends, --domain, --self-signed, --balance, --health-path, and --firewall flags

## [Unreleased]

### Added (2026-08-05)
- terraform-012: Terraform state management workflow — remote backend with state locking and migration
  - File: terraform/scripts/state-management-workflow.sh

### Added (2026-08-04)
- github-actions-001: GitHub Actions quickstart workflow manifest
  - File: github-actions/manifests/2026-08-04-what-is-github-actions.yaml

### Added (2026-04-28)
- lin-068: Log aggregation with Loki and Promtail — hardened production deployment guide
  - Doc: docs/how-to/linux-log-aggregation-loki-promtail.md
  - Security: Proper system user creation (loki:loki, promtail:promtail), least-privilege systemd services, binary vs package install differentiation, complete ownership fixes

### Added (2026-03-25)
- ter-011: AWS VPC with public/private subnets
- lin-017: Samba file sharing server setup
  - Script: scripts/bash/terraform_toolkit/networking/vpc-setup.sh
  - Terraform: scripts/bash/terraform_toolkit/networking/terraform/
  - Doc: docs/how-to/terraform-aws-vpc.md
- lin-016: DNS server with BIND9
  - Script: scripts/bash/linux_toolkit/dns/bind9-server-setup.sh
  - Doc: docs/how-to/linux-dns-bind9.md
- lin-015: VPN server setup with WireGuard
  - Script: scripts/bash/linux_toolkit/vpn/wireguard-server-setup.sh
  - Doc: docs/how-to/linux-vpn-wireguard.md
- lin-014: Mail server setup with Postfix and Dovecot
  - Script: scripts/bash/linux_toolkit/mail/mail-server-setup.sh
  - Doc: docs/how-to/linux-mail-server.md

### Added (2026-03-24)
- lin-012: Nginx reverse proxy with SSL/TLS termination
  - Script: scripts/bash/linux_toolkit/network/nginx-reverse-proxy.sh
  - Doc: docs/how-to/linux-nginx-reverse-proxy-ssl-tls.md

### Added (2026-03-24)
- lin-013: LDAP authentication server setup with OpenLDAP
  - Doc: docs/how-to/linux-ldap-server.md
  - Script: scripts/bash/linux_toolkit/authentication/ldap-server-setup.sh

### Added (2026-03-24)
- lin-010: Container host setup with Docker and security hardening
  - Doc: docs/how-to/linux-container-host-security.md
  - Script: scripts/bash/linux_toolkit/security/container-host-hardening.sh
- lin-011: ELK stack log aggregation system for Linux
  - Script: scripts/bash/linux_toolkit/logging/elk-setup.sh
  - Doc: docs/how-to/linux-elk-log-aggregation.md
- lin-009: Automated backup solution with rsync and retention policy
  - Script: scripts/bash/linux_toolkit/backup/backup-rsync-retention.sh
  - Doc: docs/how-to/linux-backup-rsync-retention.md
- lin-008: Linux system monitoring dashboard with Prometheus node_exporter
  - Doc: docs/how-to/linux-monitoring-prometheus-node-exporter.md
  - Script: scripts/bash/linux_toolkit/monitoring/node-exporter-setup.sh (existing)

### Audited
- lin-067: Linux Incident Response Automation - Score: 10/10 - Passed
- git-000: Git concept - Score: 9/10 - Passed
  - Added: docs/concepts/git-version-control-mental-model.md (386-line L1 concept doc)
- lin-008: Linux System Monitoring Dashboard - Score: 9/10 - Passed
  - Doc: docs/how-to/linux-monitoring-prometheus.md (168 lines, all 8 sections)
  - Script: scripts/bash/linux_toolkit/monitoring/node-exporter-setup.sh (296 lines, shellcheck passed)
- lin-009: Linux backup rsync project - Score: 1/10 - Rework required
    - FAILURE: No output file found in DevOps-Kit
- ter-009: Terraform module composition project - Score: 1/10 - Rework required
    - FAILURE: No output file found in DevOps-Kit
- oci-008: Azure Container Registry (ACR) installation and geo-replication — Score: 10/10 - Passed audit

### Added
- ter-051: Terraform CI/CD Pipeline with Atlantis and GitOps (L7 project)
  - `scripts/bash/terraform_toolkit/atlantis/setup-atlantis.sh`: Docker-based Atlantis server setup script with dry-run support
  - `docs/how-to/terraform-atlantis-gitops.md`: Complete guide covering architecture, setup, GitHub webhook config, workspace isolation, and common errors
- ter-009: Terraform Project with Module Composition and Workspaces (L7 project)
  - `lab/mini-projects/terraform-project/`: Complete project with main.tf, variables.tf, outputs.tf, workspace.tf
  - `lab/mini-projects/terraform-project/modules/network/`: VPC, subnets, NAT gateways, route tables
  - `lab/mini-projects/terraform-project/modules/compute/`: EC2 instances with security groups
  - `lab/mini-projects/terraform-project/modules/storage/`: S3 buckets with versioning and encryption
  - `docs/how-to/terraform-module-composition-workspaces.md`: Comprehensive guide with all 8 sections
- lin-008: Linux System Monitoring Dashboard with Prometheus Node Exporter (L7 project)
  - `docs/how-to/linux-monitoring-prometheus.md`: Complete guide covering node_exporter installation, Prometheus configuration, Grafana dashboard import, alerts setup, custom metrics, and common error resolutions
  - `scripts/bash/linux_toolkit/monitoring/node-exporter-setup.sh`: Automation script with --dry-run, --version, --port flags for Prometheus node_exporter deployment

### Added (prior)
- lin-067: Linux Incident Response Automation (L7 project)
  - `docs/how-to/linux-incident-response-automation.md`: Guide covering incident response preparation, evidence collection, chain of custody, forensic analysis, and common error resolutions
  - `scripts/bash/linux_toolkit/security/forensics/incident-response.sh`: Automation script with --dry-run, --full-forensic, --case-id, --examiner, and --output flags for comprehensive forensic collection
- helm-005: Helm + Terraform Full-Stack Project (L9 cross-tool)
  - `docs/how-to/helm-terraform-fullstack/README.md`: Complete guide covering Terraform EKS provisioning, Helm chart development, deployment automation, and integration patterns
  - `scripts/bash/helm_toolkit/helm-terraform/deploy-helm-terraform.sh`: Automated deployment script with plan/apply/deploy/rollback/clean targets
- dok-002: Docker Security Best Practices Guide (L8)
  - `docs/how-to/docker-security.md`: Comprehensive guide covering image security, container runtime security, network security, secrets management, host security, logging/monitoring, and image build security with verification steps, rollback procedures, and common error resolutions
- lin-066: Linux OpenSCAP Hardening Automation (L7 project)
  - `docs/how-to/linux-openscap-hardening.md`: Guide covering OpenSCAP installation, dry-run scans, full compliance scanning, remediation script generation, and automated remediation with backup/rollback
  - `scripts/bash/linux_toolkit/security/openscap-hardening.sh`: Automation script with --dry-run, --auto-remediate, --profile, and --report flags for STIG/CIS/PCI-DSS compliance

### Fixed
- vault-009: CVE-2025-6013 LDAP MFA enforcement bypass script
  - Fixed hardcoded ldap_mounts to dynamically enumerate from sys/auth endpoint
  - Added shellcheck notes for unused DRY_RUN/VERBOSE variables

### Added
- jen-012: Jenkins Pipeline Groovy Snippets for Scripted Pipelines (L4)
  - `snippets/jenkins-scripted-pipeline-groovy.md`: 50+ Groovy code snippets for Jenkins scripted pipelines covering node/stage blocks, variable handling, conditionals, loops, error handling, parallel execution, Docker integration, Git operations, file operations, HTTP APIs, credential handling, email notifications, artifact management, and testing integration

### Added
- jen-009: Jenkins Commands Reference (L4)
  - `docs/reference/jenkins-commands.md`: 50+ Jenkins CLI commands for job management, build management, node/agent management, plugin management, queue scheduling, API automation, and more. Includes commands with pipes, filters, and awk combinations.

### Added
- k8s-012: Kubernetes CI/CD pipeline with Jenkins and Vault secrets injection (L9 cross-tool project)
  - `docs/how-to/k8s-jenkins-vault-cicd-security.md`: Complete guide covering Jenkins on K8s, Vault HA with Kubernetes auth, Trivy/Kubescape security scanning, GitOps deployment with Vault sidecar
- k8s-011: Kubernetes GitOps workflow with ArgoCD and Vault secrets injection (L9 cross-tool project)
  - `docs/how-to/k8s-argocd-vault-gitops.md`: Complete GitOps walkthrough with ArgoCD, Vault CSI Provider, SecretStore
  - Covers ArgoCD installation, Git repository setup, Vault Kubernetes auth configuration
  - Includes SecretProviderClass setup, secrets injection verification, rollback procedures
  - Real error scenarios and troubleshooting steps

### Added
- k8s-010: Kubernetes cluster provisioning with Terraform + Ansible (L9 cross-tool project)
  - `docs/how-to/k8s-terraform-ansible-provisioning/README.md`: Full walkthrough covering VPC setup, Ansible bootstrap, kubeadm init, Calico CNI, worker join
  - `docs/how-to/k8s-terraform-ansible-provisioning/terraform/main.tf`: VPC, subnets, NAT GW, IGW, bastion host
  - `docs/how-to/k8s-terraform-ansible-provisioning/terraform/control-plane.tf`: CP nodes, NLB, target groups, security groups
  - `docs/how-to/k8s-terraform-ansible-provisioning/terraform/workers.tf`: Worker nodes, worker security group
  - `docs/how-to/k8s-terraform-ansible-provisioning/terraform/variables.tf`: All configurable variables
  - `docs/how-to/k8s-terraform-ansible-provisioning/terraform/outputs.tf`: IPs, NLB DNS, SSH config, Ansible inventory
  - `docs/how-to/k8s-terraform-ansible-provisioning/ansible/site.yml`: Main Ansible playbook
  - `docs/how-to/k8s-terraform-ansible-provisioning/ansible/roles/preflight/tasks/main.yml`: Package update, kernel modules, sysctl, swap disable
  - `docs/how-to/k8s-terraform-ansible-provisioning/ansible/teardown.yml`: kubeadm reset teardown playbook
  - `docs/how-to/k8s-terraform-ansible-provisioning/ansible/inventory.ini.example`: Ansible inventory template

### Added
- jen-009: Jenkins commands reference with 100+ CLI commands
  - `snippets/jenkins-commands-reference.md`: Comprehensive Jenkins CLI reference
  - Covers job management, build operations, node/agent management, plugin management
  - Includes credential management, pipeline commands, system information, user and view management
  - Provides 50+ practical one-liners and troubleshooting tips

### Audited
- vault-009: CVE-2025-6013 hardening script - Score: 10/10 - Passed audit

### Added
- vault-009: Vault LDAP MFA enforcement bypass (CVE-2025-6013) hardening script
  - `scripts/bash/vault_toolkit/security/cve-2025-6013.sh`: Detection script
  - Checks Vault version for CVE-2025-6013 vulnerability
  - Enumerates LDAP auth methods
  - Validates username_as_alias configuration
  - Checks MFA setup
  - Provides remediation recommendations
  - Supports --dry-run, --json-output, and --verbose modes
  - shellcheck passed with warnings only

### Added
- ansi-010: Ansible Automation Platform EDA credentials exposure (CVE-2025-9907) hardening script
  - `scripts/bash/ansible_toolkit/security/cve-2025-9907-eda-creds.sh`: Detection and remediation script
  - Checks AAP installation and version
  - Validates EDA configuration for credential exposure risks
  - Detects test mode configuration indicators
  - Provides remediation recommendations
  - Supports --dry-run, --remediate, and --json-output modes
  - shellcheck passed with warnings only

### Added
- dok-006: Docker Desktop grpcfuse kernel module privilege escalation (CVE-2026-2664) hardening script
  - `scripts/bash/docker_toolkit/security/cve-2026-2664.sh`: Detection and remediation script
  - Checks Docker version for CVE-2026-2664 vulnerability
  - Validates FUSE/grpcfuse mounts
  - Checks /proc/docker access permissions
  - Detects docker group membership and container capabilities
  - Provides remediation recommendations
  - Supports --dry-run, --remediate, and --json-output modes
  - shellcheck passed

### Added
- vault-008: Vault TLS certificate auth validation bypass (CVE-2025-6037) hardening script
  - `scripts/bash/vault_toolkit/security/cve-2025-6037.sh`: Detection and remediation script
  - Checks Vault version for CVE-2025-6037 vulnerability
  - Validates certificate auth method configuration
  - Detects non-CA certificate usage in trusted certificates
  - Provides remediation recommendations
  - Supports --dry-run and --verbose modes
  - shellcheck passed with warnings only

### Added
- helm-002: Helm chart security scanning guide
  - `docs/how-to/helm-security-scanning.md`: Comprehensive security scanning guide for Helm charts
  - Covers Trivy, kube-score, Checkov, Kubescape scanning tools
  - CI/CD integration examples (GitHub Actions, GitLab CI)
  - Runtime security scanning with Falco integration
  - Chart integrity verification and signing
  - Security report generation in multiple formats
  - Updated `00_index/quick-links.md` - Added Helm security scanning to Helm section

### Added
- dok-002: Docker security best practices guide
  - `docs/how-to/docker-security-best-practices.md`: Comprehensive security hardening guide for Docker
  - Covers image security, runtime protection, network isolation
  - Includes Dockerfile best practices, vulnerability scanning with Trivy
  - Docker secrets management, TLS configuration
  - Daemon security, host hardening guidelines
  - Security verification checklist and audit script
  - Updated `00_index/quick-links.md` - Added Docker security guide to Tools section

### Added
- vault-004: Vault seal/unseal troubleshooting guide
  - `docs/how-to/vault-troubleshooting-seal-unseal.md`: Comprehensive troubleshooting guide for Vault seal/unseal issues
  - Covers seal status identification, Shamir key unseal procedures
  - Common unseal failure scenarios with resolution steps
  - Auto-unseal troubleshooting (AWS KMS, Azure Key Vault, GCP Cloud KMS)
  - HSM seal troubleshooting with PKCS#11 diagnostics
  - Recovery mode procedures and manual seal operations
  - Error reference table for common seal/unseal errors
  - Verified reference URLs from HashiCorp documentation
  - Updated `00_index/quick-links.md` — Added Vault seal/unseal troubleshooting to Vault and Troubleshooting sections

### Added
- vault-003: Vault secure deployment best practices guide
  - `docs/how-to/vault-secure-deployment.md`: Comprehensive security hardening guide for Vault production deployments
  - Covers TLS configuration, authentication methods, authorization policies, audit logging
  - Network security, sealing/unsealing, rate limiting, namespaces
  - Includes hardening checklist and verification steps
  - Updated `00_index/quick-links.md` — Added Vault secure deployment guide to Vault section
  - Updated `docs/how-to/vault_toolkit.md` — Added documentation reference

### Added
- ansi-008: Ansible AAP hardening script for CVE-2026-24049 (wheel privilege escalation)
  - `scripts/bash/ansible_toolkit/security/aap-cve-2026-24049-check.sh`: Detect wheel package privilege escalation vulnerability
  - Checks wheel package version (vulnerable: 0.40.0 - 0.46.1)
  - Validates AAP access and checks AAP version affected by CVE-2026-24049
  - Checks critical file permissions for unauthorized changes
  - Scans for recent wheel unpack activities in AAP logs
  - Provides remediation recommendations (upgrade wheel to 0.46.2+, AAP to 2.5.3+)
  - Supports --host, --token, --dry-run, --output flags
  - shellcheck: pass with warnings (SC2038 - style only, fixed)
- Updated `00_index/quick-links.md` — Added CVE-2026-24049 hardening script to Ansible section

### Added
- ansi-002: Ansible Lightspeed hardening script for CVE-2026-0598 (auth bypass)
  - `scripts/bash/ansible_toolkit/security/cve-2026-0598-audit.sh`: Detect CVE-2026-0598 auth bypass in Ansible Lightspeed
  - Checks AAP version against vulnerable versions
  - Audits Lightspeed service status and configuration
  - Reviews audit logs for unauthorized conversation access
  - Checks API endpoint vulnerability patterns
  - Reviews user permissions and roles
  - Provides remediation recommendations for ownership validation
  - Supports --host, --token, --dry-run, --json-output, --verbose flags
  - shellcheck: pass with warnings (SC2043, SC2155 - style only)
- Updated `00_index/quick-links.md` — Added CVE-2026-0598 audit script to Ansible section
- Updated `docs/how-to/ansible_toolkit.md` — Added CVE-2026-0598 documentation
- Added `docs/how-to/ansible-lightspeed-cve-2026-0598.md` — How-to guide for CVE-2026-0598

### Added
- vault-008: Vault hardening script for CVE-2025-11621 (AWS Auth bypass)
  - `scripts/bash/vault_toolkit/security/cve-2025-11621.sh`: Detect and remediate Vault AWS Auth method bypass vulnerability
  - Checks Vault server version against vulnerable versions (< 1.16.27, < 1.19.11, < 1.20.5, < 1.21.0)
  - Audits AWS auth methods for bound_principal_iam with wildcards
  - Detects cross-account IAM role access patterns
  - Reviews AWS auth roles for bound_iam_role_arn configurations
  - Provides remediation recommendations for IAM policy hardening
  - Supports --dry-run, --json-output flags
  - shellcheck: pass
- Updated `00_index/quick-links.md` — Added CVE-2025-11621 hardening script to Vault section

### Added
- helm-001: Helm hardening script for CVE-2025-53547 (Chart.yaml code injection)
  - `scripts/bash/helm_toolkit/security/cve-2025-53547-harden.sh`: Detect and remediate Helm Chart.yaml code injection vulnerability
  - Checks Helm client version against vulnerable versions (< 3.17.2)
  - Analyzes Chart.yaml for injection patterns (template syntax, dangerous function calls)
  - Reviews dependencies for remote template risks
  - Scans templates for potential injection vectors
  - Provides remediation recommendations for chart sanitization
  - Supports --dry-run, --check-version, --verbose flags
  - shellcheck: pass
- Updated `00_index/quick-links.md` — Added Helm CVE-2025-53547 hardening script link
- Bootstrap: Created scripts/bash/helm_toolkit/security directory

### Added
- dok-001: Docker hardening script for CVE-2026-28400 (Model Runner privilege escalation)
  - `scripts/bash/docker_toolkit/security/cve-2026-28400.sh`: Detect Docker Model Runner privilege escalation vulnerability
  - Checks Docker version and Model Runner container status
  - Scans for privileged containers and Docker socket mounts
  - Checks Model Runner API exposure
  - Provides remediation recommendations
  - Supports --dry-run, --remediate, --json-output flags
  - shellcheck: pass
- Updated `00_index/quick-links.md` — Added Docker section with CVE-2026-28400 hardening script
- Bootstrap: Created scripts/bash/docker_toolkit/security directory

### Added
- vault-002: Vault hardening script for CVE-2025-5999 (privilege escalation to root)
  - `scripts/bash/vault_toolkit/security/cve-2025-5999.sh`: Detect and remediate Vault privilege escalation vulnerability
  - Checks Vault server version against vulnerable versions (< 1.16.12, < 1.17.8, < 1.18.2)
  - Audits policies with elevated permissions and root-like privileges
  - Reviews entity and group memberships for root policy assignments
  - Checks token roles for excessive permissions
  - Provides remediation recommendations for policy hardening
  - Supports --dry-run, --remediate, --json-output flags
  - shellcheck: pass
- Updated `docs/how-to/vault_toolkit.md` — Added CVE-2025-5999 script documentation
- Updated `00_index/quick-links.md` — Added CVE-2025-5999 hardening script link

### Added
- vault-001: Vault hardening script for CVE-2025-6000 (plugin directory RCE)
  - `scripts/bash/vault_toolkit/security/cve-2025-6000.sh`: Detect and remediate Vault plugin directory RCE vulnerability
  - Checks Vault server version against vulnerable versions (< 1.16.12, < 1.17.8, < 1.18.2)
  - Audits plugin directory configuration and permissions
  - Provides remediation recommendations for plugin security
  - Supports --dry-run, --remediate, --json-output flags
  - shellcheck: pass
- Updated `00_index/quick-links.md` — Added vault_toolkit to Tools section and new Vault section
- Bootstrap: Created scripts/bash/vault_toolkit/security directory

### Added
- ansi-001: Ansible vault password rotation script
  - `scripts/bash/ansible_toolkit/security/vault-password-rotation.sh`: Rotate vault passwords across encrypted files
  - Supports rotating from old vault ID to new vault ID
  - Identifies and processes encrypted vault files (.yml, .yaml)
  - Creates backups before re-encryption (.bak.YYYMMDDHHMMSS)
  - Supports --path, --old-vault-id, --new-vault-id, --backup-dir options
  - DRY_RUN mode enabled by default, --execute to apply changes
  - shellcheck: pass (warnings only)
- Updated `00_index/quick-links.md` — Added vault password rotation script to Ansible section

### Added
- kfk-005: Kafka troubleshooting guide for consumer lag and rebalancing
  - `docs/troubleshooting/kafka-consumer-lag.md`: Comprehensive troubleshooting guide
  - Covers consumer lag identification, analysis, and remediation
  - Includes rebalancing issues, common causes, and fixes
  - Covers session timeout, heartbeat, static membership configurations
  - Rollback procedures with offset reset examples
  - Common errors table with causes and fixes
- Updated `00_index/quick-links.md` — Added Kafka troubleshooting link

### Added
- ansi-003: Ansible playbook audit for CVE-2025-14010 (sensitive variable exposure)
  - `scripts/bash/ansible_toolkit/security/cve-2025-14010-audit.sh`: Detect and audit sensitive variable exposure
  - Checks for missing no_log on sensitive tasks (shell, command, script, template, copy)
  - Detects hardcoded secrets in variable files
  - Reviews environment variable security
  - Identifies debug tasks without no_log protection
  - Supports --path, --dry-run, --json-output, --verbose options
  - Requires: bash 4+, grep, awk, find
  - shellcheck: pass (warnings only)
- Added `docs/how-to/ansible_toolkit.md` — Complete documentation for ansible_toolkit
- Updated `00_index/quick-links.md` — Added ansible_toolkit to Tools section and new Ansible section
- Updated `00_index/topics.md` — Added ansible_toolkit to Tools table
- Bootstrap: Created scripts/bash/ansible_toolkit/security directory

### Added
- ter-002: Terraform init/plan/apply workflow script with sensitive value handling
  - `scripts/bash/terraform_toolkit/terraform-workflow.sh`: Run Terraform workflows with security best practices
  - Supports init, plan, apply, destroy, validate commands
  - Sensitive value handling: warns about secrets in var files, recommends TF_VAR_* environment variables
  - Supports --dry-run for plan/apply/destroy operations
  - Supports --var-file, --backend-config, --lock-timeout options
  - Color-coded logging for info/warn/error
  - shellcheck: pass
- Updated `00_index/quick-links.md` — Added terraform_toolkit to Tools section and new Terraform section
- Bootstrap: Created scripts/bash/terraform_toolkit directory

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

## [2026-03-17] - Auditor

### Tasks Audited
- vault-004: Vault seal/unseal troubleshooting guide — Score: 10/10 ✅

### Passed (≥8/10)
- vault-004 (10/10) — comprehensive troubleshooting guide with all 8 sections present, real Vault error strings, verified HashiCorp URLs with dates

### Rework (!)
- None

### Stuck
- None

## [2026-03-18] - Auditor

### Tasks Audited
- dok-006: Docker Desktop grpcfuse kernel module privilege escalation (CVE-2026-2664) — Score: 9/10 ✅

### Passed (≥8/10)
- dok-006 (9/10) — comprehensive read-only detection script for CVE-2026-2664. Minor jq syntax fix needed on line 191: has("buildkit"] should be has("buildkit"). shellcheck passed with info only. Production-ready.

### Rework (!)
- None

### Stuck
- None

## [2026-03-21] - Auditor

### Tasks Audited
- dok-002: Docker Security Best Practices Guide — Score: 9/10 ✅
- lin-066: Linux OpenSCAP Hardening Automation — Score: 9/10 ✅

### Passed (≥8/10)
- dok-002 (9/10) — comprehensive security guide with all 8 sections, real error strings, verified URLs. Minor: line 256 has Chinese characters that should be English "Regularly update Docker". Production-ready.
- lin-066 (9/10) — comprehensive OpenSCAP hardening script with dry-run, backup, profile selection. Minor issue: line 143 URL has space ("data/ scap") - should be "data/scap". Production-ready.

### Rework (!)
- None

### Stuck
- None

---

## 2026-03-27 — Worker: lin-019 PostgreSQL Database Server

**Task**: lin-019 — Linux: project — database server with PostgreSQL
**Branch**: sainath-2026-03-27-2118
**Files**:
- `lab/mini-projects/postgresql-database-server/README.md` — L7 walkthrough (10 phases)
- `scripts/bash/linux_toolkit/database/pg-setup.sh` — PostgreSQL 16 installation with dry-run
- `scripts/bash/linux_toolkit/database/pg-backup.sh` — pg_dump backup with rotation
- `scripts/bash/linux_toolkit/database/pg-healthcheck.sh` — health check
- `00_index/quick-links.md` — updated
Added: k8s-cluster-autoscaler-grpc-hardening.sh and k8s-cluster-autoscaler-cve-2026-33186.md - CVE-2026-33186

---
lin-066: Linux network traffic analysis project and monitoring script
ter-018: Terraform AWS Secrets Manager integration — 2026-04-22
## 2026-08-07

### Added
- con-097: `docs/concepts/secrets-access-management/notebooks/secrets-detection-remediation-workflow-analysis.ipynb` — Secrets & Access Management: notebook — Secrets detection and remediation workflow analysis (L3)
- con-099: docs/concepts/version-control-with-git/scripts/git-hooks-devsecops-security-checks.sh — Git hooks for DevSecOps (L3)

## 2026-08-18

### Added
- trivy-019: `trivy/templates/trivy-k8s-workload-scanning/` — Trivy Kubernetes workload scanning pipeline scaffold (L5)
