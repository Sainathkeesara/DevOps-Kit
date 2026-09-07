# Learning Path — DevSecOps

> A suggested progression from beginner to confident practitioner. Each stage builds on the previous one. Every topic listed below has content on disk; follow the links as you go.

## Stage 1: Foundations

These concepts have no prerequisites and are the starting point for any security engineer.

- **Linux & Shell Fundamentals** — Everything runs on Linux. Scripts, containers, pipelines all depend on shell fluency. [Linux toolkit guide](../docs/how-to/linux_toolkit.md) | [Cheatsheet](../snippets/linux-cheatsheet.md) | [Practice exercises](../docs/concepts/linux-shell-fundamentals/scripts/2026-07-23-practice-exercises.sh) | [Linux VM terminal first commands](../linux/notes/2026-07-21-install-linux-vm-terminal-first-commands.md) | [Shell scripting confusions](../linux/notes/2026-08-06-linux-shell-scripting-tutorial-confusions.md) | [Cron job config](../linux/configs/2026-08-06-cron-job-configuration.ini) | [Security scanner wrapper script](../docs/concepts/linux-shell-fundamentals/scripts/ci-cd-pipeline-security-scanner-wrapper.sh)
- **Version Control with Git** — Branching, commits, remotes, and CI/CD triggers. Primers cover mental models and everyday commands. [Git fundamentals](../docs/concepts/git-001-version-control-fundamentals.md) | [Commands reference](../docs/reference/git-commands.md) | [Practice exercises](../docs/concepts/version-control-with-git/scripts/2026-07-24-practice-exercises.sh) | [Git hooks for security checks](../docs/concepts/version-control-with-git/scripts/git-hooks-devsecops-security-checks.sh)
- **CI/CD Pipeline Concepts** — How code moves from commit to deployment; why gates and scans matter. [CI/CD toolkit guide](../docs/how-to/ci_cd_toolkit.md) | [Cheatsheet](../snippets/ci-cd-cheatsheet.md) | [Practice exercises](../docs/concepts/ci-cd-pipeline-concepts/scripts/2026-07-17-practice-ci-cd-exercises.sh)
- **Infrastructure as Code** — Terraform, OpenTofu, and the idea of declarative infrastructure. [OpenTofu primer](../opentofu/notes/0000-primer-opentofu.md) | [Explore OpenTofu](../opentofu/notes/2026-07-20-explore-open-tofu.md) | [Terraform state management](../docs/how-to/terraform-state-management.md) | [Practice exercises](../docs/concepts/infrastructure-as-code/snippets/2026-07-23-practice-exercises.hcl)
- **Application Security Testing Concepts** — SAST, DAST, SCA — what they catch and when to use each. Primers on Semgrep, CodeQL, ZAP, and Snyk cover this. [Applying AppSec in DevSecOps](../docs/concepts/application-security-testing-concepts/2026-07-12-applying-appsec-in-devsecops.md) | [AppSec + secrets integration exercise](../docs/concepts/application-security-testing-concepts/snippets/2026-07-19-appsec-secrets-integration.py) | [SCA and dependency exercises](../docs/concepts/application-security-testing-concepts/snippets/2026-08-26-appsec-sca-dependency-exercises.py) | [AST-based pattern checker](../docs/concepts/application-security-testing-concepts/scripts/2026-08-26-ast-devsecops.py)
- **Container & Runtime Security** — Images, registries, runtime behaviour. Trivy, Syft, Grype, Cosign, and Falco all depend on this. [Docker primer](../docker/notes/0000-primer-docker.md) | [Docker security best practices](../docs/how-to/docker-security-best-practices.md)
- **Secrets & Access Management** — How secrets leak and how to protect them. Vault, TruffleHog, and GitGuardian depend on this. [Vault primer](../vault/notes/0000-primer-vault.md) | [Practice exercises](../docs/concepts/secrets-access-management/snippets/2026-07-24-practice-exercises.py) | [Secrets detection workflow analysis notebook](../docs/concepts/secrets-access-management/notebooks/secrets-detection-remediation-workflow-analysis.ipynb)
- **Software Supply Chain Security** — Dependency risk, SBOMs, signing. Syft, Grype, Cosign, Dependabot all live here. [Practice exercises](../docs/concepts/software-supply-chain-security/snippets/2026-07-23-practice-exercises.sh)
- **Configuration Management** — Desired state, idempotency, drift, and managing systems as code. The foundation for Ansible. [Primer](../docs/concepts/configuration-management/0000-primer-configuration-management.md) | [DevSecOps patterns](../docs/concepts/configuration-management/2026-07-14-devsecops-patterns.md)
- **Observability & Monitoring** — Metrics, logs, traces, SLOs, and understanding system behaviour. The foundation for Prometheus and Grafana. [Observability primer](../docs/concepts/observability-monitoring/notes/0000-primer-observability.md) | [SLI/SLO/SLA definitions](../00_index/glossary.md)

## Stage 2: Core Tools

These tools are unlocked from the start and cover the most common DevSecOps workflows.

- **Git** — Version control foundation for every DevOps workflow. [Primer](../git/notes/0000-primer-git.md) | [Branching and merging](../git/notes/2026-07-04-git-branching-merge-confusions.md) | [First repo: stage and log](../git/scripts/2026-08-24-first-repo-stage-log.sh) | [Local CI simulation](../git/scripts/2026-07-10-local-ci-simulation.sh)
- **Docker** — Container runtime for packaging and running applications. [Primer](../docker/notes/0000-primer-docker.md) | [Explore the CLI](../docker/notes/2026-07-12-explore-docker-cli.md) | [Custom image](../docker/dockerfiles/2026-07-12-first-custom-docker-image.Dockerfile) | [Networking and volumes](../docker/scripts/2026-07-18-custom-network-volume-mounts.sh)
- **Kubernetes** — Container orchestration for deploying and scaling workloads. [Primer](../kubernetes/notes/0000-primer-kubernetes.md) | [Explore](../kubernetes/notes/2026-07-15-explore-kubernetes.md) | [First manifest](../kubernetes/manifests/2026-07-15-first-pod-service.yaml)
- **Terraform** — Declarative infrastructure provisioning with HCL and providers. [Primer](../terraform/notes/0000-primer-terraform.md) | [First config](../terraform/configs/2026-07-15-first-config.tf) | [Deploy script](../terraform/scripts/2026-07-18-deploy.sh) | [Cleanup script](../terraform/scripts/2026-07-18-cleanup.sh) | [Module composition guide](../terraform/docs/terraform-module-composition.md) | [Workspace variable precedence](../terraform/configs/workspace-variable-precedence.hcl) | [Provision a Kubernetes cluster](../docs/how-to/k8s-terraform-ansible-provisioning.md)
- **Trivy** — Universal vulnerability scanner for containers, filesystems, repos, and SBOMs. [Primer](../trivy/notes/0000-primer-trivy.md) | [Install and first container scan](../trivy/notes/2026-09-05-install-trivy-first-container-scan.md) | [Scan modes comparison](../trivy/notebooks/trivy-scan-mode-comparison.ipynb) | [Scanning performance optimization](../trivy/notes/scanning-performance-optimization.md)
- **Semgrep** — SAST tool with custom rule writing, multi-language support, and CI/CD integration. [Primer](../semgrep/notes/0000-primer-semgrep.md) | [Rule writing reference](../semgrep/docs/semgrep-rule-writing-reference.md)
- **Checkov** — IaC security scanner for Terraform, Kubernetes, CloudFormation. Supports custom policies and plan scanning. [Primer](../checkov/notes/0000-primer-checkov.md) | [Plan scanning](../checkov/scripts/deep-terraform-plan-scan.sh) | [v3 migration guide](../checkov/docs/checkov-v3-migration-guide.md) | [Multi-repo drift detection scaffold](../checkov/templates/multi-repo-drift-auto-pr-remediation/README.md)
- **TruffleHog** — Secret scanner with git, filesystem, and S3 scan modes. Custom regex and entropy-based detection. [Primer](../trufflehog/notes/0000-primer-trufflehog.md) | [Scan modes comparison](../trufflehog/docs/comparing-scan-modes-git-filesystem-s3.md)
- **OWASP ZAP** — DAST tool for web application security testing. Baseline, spider, and active scan modes. [Primer](../zap/notes/0000-primer-zap.md) | [Install and first baseline scan](../zap/notes/2026-09-05-install-zap-first-baseline-scan.md) | [DAST workflow](../zap/scripts/dast-workflow-from-scratch.sh)

## Stage 3: Building Skills

Intermediate tools that add SBOM management, software composition analysis, and deeper vulnerability workflows.

- **Helm** — Package manager for Kubernetes charts and releases. [Primer](../helm/notes/0000-primer-helm.md) | [Explore charts, releases, values, repos](../helm/notes/2026-07-19-explore-helm-charts-releases-values-repos.md)
- **Kustomize** — Kubernetes YAML customization without templating. [Primer](../kustomize/notes/0000-primer-kustomize.md) | [First overlay](../kustomize/notes/2026-07-08-install-kustomize-first-overlay.md)
- **GitHub Actions** — GitHub's built-in CI/CD system. [Primer](../github-actions/notes/0000-primer-github-actions.md) | [Explore](../github-actions/notes/2026-07-14-explore-github-actions.md) | [First workflow](../github-actions/configs/2026-07-14-first-github-actions-workflow.yaml) | [Install the gh CLI](../github-actions/notes/2026-08-26-install-gh-cli-first-command.md) | [Minimal push-triggered workflow](../github-actions/snippets/2026-08-26-first-workflow.yaml) | [Composite action input reuse](../github-actions/snippets/2026-08-26-composite-action-input-reuse.yaml)
- **Syft** — SBOM generation in CycloneDX and SPDX formats. Integrates with Grype for vulnerability correlation. [Primer](../syft/notes/0000-primer-syft.md) | [Output format comparison](../syft/notebooks/output-format-comparison.ipynb) | [SBOM pipeline scaffold](../syft/templates/sbom-pipeline-scaffold/README.md) | [Syft + Trivy K8s scan scaffold](../syft/templates/syft-trivy-k8s-scan-scaffold/README.md)
- **Grype** — Vulnerability scanner for container images and filesystems. Designed to consume Syft SBOMs. [Primer](../grype/notes/0000-primer-grype.md) | [Vulnerability diff](../grype/scripts/vuln-diff-two-images.sh) | [End-to-end pipeline](../grype/scripts/grype-end-to-end-scan-pipeline.sh) | [SBOM-to-SARIF pipeline](../grype/scripts/grype-scan-pipeline-end-to-end.sh)
- **CodeQL** — Semantic code analysis with custom QL queries. Supports multiple languages and CI integration. [Primer](../codeql/notes/0000-primer-codeql.md) | [Install and run a first query](../codeql/notes/2026-08-26-install-codeql-first-query.md) | [Datalog gotchas](../codeql/notes/2026-06-14-codeql-datalog-gotchas.md) | [Custom queries in CI](../codeql/docs/wired-custom-queries-into-ci.md)
- **GitGuardian** — Secrets detection platform with ggshield CLI for pre-commit and CI scanning. [Primer](../gitguardian/notes/0000-primer-gitguardian.md) | [Custom policy engine](../gitguardian/snippets/custom-policy-engine-ggshield.sh)
- **Snyk** — Developer security platform for open-source dependencies and containers. [Primer](../snyk/notes/0000-primer-snyk.md) | [CI pipeline integration](../snyk/configs/snyk-ci-github-actions.yaml) | [Multi-language scan scaffold](../snyk/templates/snyk-multilang-scan-scaffold/README.md) | [Vulnerability prioritization with reachability and Fix PRs](../snyk/docs/vulnerability-prioritization-reachability-fix-prs-license-compliance.md)
- **Dependabot** — GitHub's automated dependency update tool for vulnerability patching. [Primer](../dependabot/notes/0000-primer-dependabot.md) | [npm config](../dependabot/configs/tried-npm-dependabot.yaml) | [Python config](../dependabot/configs/2026-07-18-python-project-version-update.yaml) | [Enabling alerts](../dependabot/notes/2026-07-10-enabling-dependabot-alerts.md) | [Alerts + security updates](../dependabot/notes/2026-07-21-enabling-dependabot-alerts-security-updates.md) | [Custom registry tutorial](../dependabot/notes/2026-08-08-dependabot-custom-registry-tutorial.md)
- **Terrascan** — IaC static analysis for Terraform and Kubernetes with custom Rego rules. [Primer](../terrascan/notes/0000-primer-terrascan.md) | [First scan](../terrascan/notes/2026-06-13-first-scan.md) | [Custom Rego rules](../terrascan/configs/tried-custom-s3-rule.yaml)
- **Prometheus** — Time-series metrics collection and alerting for cloud-native environments. [Primer](../prometheus/notes/0000-primer-prometheus.md)
- **Grafana** — Dashboard and visualization layer for metrics. [Primer](../grafana/notes/0000-primer-grafana.md)
- **Ansible** — Configuration management and automation over SSH, built on the Configuration Management fundamentals. [Provision a Kubernetes cluster](../docs/how-to/k8s-terraform-ansible-provisioning.md) | [Quickstart trip-ups](../ansible/notes/2026-08-25-followed-ansible-quickstart-what-tripped-me-up.md) | [Minimal playbook: package and service](../ansible/snippets/2026-08-25-minimal-ansible-playbook-package-service.yaml) | [CVE-2026-33228 path verification](../ansible/notes/2026-08-17-verify-ansible-cve-2026-33228-paths.md) | [Bootstrap a node](../ansible/scripts/bootstrap-target-node.sh)

## Stage 4: Advanced Tools

Tools that depend on foundational concepts and earlier tools being complete.

- **ArgoCD** — Declarative GitOps continuous delivery for Kubernetes. Requires Kubernetes and Git fluency. [Primer](../argocd/notes/0000-primer-argocd.md) | [Quickstart trip-ups](../argocd/notes/2026-08-12-quickstart-tripups.md) | [First app deployment](../argocd/notes/2026-07-06-install-argocd-first-app.md) | [Private repo credentials and RBAC](../argocd/configs/2026-08-17-private-repo-credentials-rbac.yaml)
- **SonarQube** — Static analysis platform for bugs, code smells, and security issues with Quality Gates. [Primer](../sonarqube/notes/0000-primer-sonarqube.md) | [Explore quality gates and profiles](../sonarqube/notes/2026-07-19-explore-sonarqube-quality-gates-profiles.md)
- **Cosign** — Container image signing and verification as part of the Sigstore project. Requires SBOM and vulnerability awareness. [Primer](../cosign/notes/0000-primer-cosign.md) | [Sign first image](../cosign/notes/2026-06-13-install-cosign-sign-first-image.md) | [Verification patterns](../cosign/docs/cosign-verification-patterns.md) | [Custom signing image](../cosign/dockerfiles/custom-cosign-image.Dockerfile)
- **Falco** — Runtime security monitoring for containers and Kubernetes. Requires understanding of container behaviour and system calls. [Primer](../falco/notes/0000-primer-falco.md) | [Custom rules](../falco/configs/first-custom-rule-detect-shell-in-container.yaml) | [Explore CLI, rules, events, output](../falco/notes/2026-07-19-explore-falco-cli-rules-events-output.md)
- **OPA / Gatekeeper** — Policy engine for Kubernetes admission control and IaC validation. Requires understanding of Rego and Kubernetes policies. [Primer](../opa/notes/0000-primer-opa.md) | [Gatekeeper constraint](../opa/configs/tried-a-gatekeeper-constraint.yaml) | [Constraint template design patterns](../opa/docs/constraint-template-design-patterns.md) | [Policy library scaffold](../opa/templates/gatekeeper-policy-library-scaffold/README.md) | [Export audit results](../opa/scripts/export-audit-results.sh)
- **HashiCorp Vault** — Secrets management, dynamic secrets, encryption-as-a-service. [Primer](../vault/notes/0000-primer-vault.md) | [Install and first command](../vault/notes/2026-08-26-install-vault-first-command.md) | [Secrets engine selection guide](../vault/docs/vault-secrets-engine-selection-guide.md) | [KV CRUD](../vault/scripts/vault-kv-crud.sh) | [Policy-as-code](../vault/configs/2026-06-26-dev-test-policies.hcl) | [AWS secrets engine policy](../vault/configs/2026-09-04-aws-secrets-engine-policy.hcl) | [Agent auto-auth on Kubernetes](../vault/docs/vault-agent-auto-auth-kubernetes.md)
- **Tetragon** — eBPF-based runtime security observability for detecting kernel-level anomalies in containers. [Primer](../tetragon/notes/0000-primer-tetragon.md) | [Docker install](../tetragon/notes/2026-06-23-install-tetragon-docker-first-events.md) | [Observability tutorial](../tetragon/notes/2026-08-06-tetragon-observability-tutorial.md) | [Network tracing policy](../tetragon/configs/2026-08-05-minimal-network-tracing-policy.yaml) | [Event collection pipeline](../tetragon/scripts/2026-08-05-tetragon-event-collection-pipeline.sh)
- **DefectDojo** — Vulnerability management platform for aggregating and tracking security findings. [Primer](../defectdojo/notes/0000-primer-defectdojo.md) | [Install and import report](../defectdojo/snippets/install-defectdojo-first-scan-report.sh)

## Stage 5: Mastery

Cross-cutting integration and custom tooling.

- **Custom policy authoring** — Writing Checkov policies, Semgrep rules, Falco rules, OPA Rego policies, and TruffleHog custom detectors. [Gatekeeper policy library scaffold](../opa/templates/gatekeeper-policy-library-scaffold/README.md) | [Local policy test suite](../opa/templates/gatekeeper-policy-library-scaffold/tests/test-policies.sh)
- **Multi-stage CI/CD pipelines** — Combining SAST + SCA + DAST + secret scanning + SBOM generation + container signing in a single gated pipeline. [TruffleHog PR secret scan reusable workflow](../trufflehog/manifests/trufflehog-pr-secret-scan-reusable.yaml)
- **CVE remediation workflows** — Using the CVE-specific scripts and guides for Ansible, Docker, Jenkins, Kafka, Kubernetes, and Trivy.
- **Multi-cluster security posture management** — Integrating Falco, OPA, Trivy Operator, and kubescape across multiple Kubernetes clusters.
- **Observability stack integration** — Wiring Prometheus metrics, Grafana dashboards, Loki logs, and Jaeger traces into a unified SLO-driven alerting pipeline.

## Progression Map

```mermaid
flowchart LR
  subgraph Foundations
    Linux["Linux & Shell"]
    Git["Version Control (Git)"]
    CICD["CI/CD Pipeline Concepts"]
    IaC["Infrastructure as Code"]
    AppSec["AppSec Testing Concepts"]
    Container["Container & Runtime Security"]
    Secrets["Secrets & Access Management"]
    SupplyChain["Software Supply Chain Security"]
    Observ["Observability & Monitoring"]
  end

   subgraph Core[Stage 2: Core Tools]
     Docker
     Kubernetes
     Terraform
     Trivy
     Semgrep
     Checkov
     TruffleHog
     ZAP
   end

  subgraph Intermediate[Stage 3: Building Skills]
    Helm
    Kustomize
    GitHubActions["GitHub Actions"]
    Syft
    Grype
    CodeQL
    GitGuardian
    Snyk
    Dependabot
    Terrascan
    Prometheus
    Grafana
  end

  subgraph Advanced[Stage 4: Advanced Tools]
    ArgoCD
    SonarQube
    Cosign
    Falco
    OPA["OPA/Gatekeeper"]
    Vault
    Tetragon
    DefectDojo
  end

  Linux --> Docker & Kubernetes & Trivy & Semgrep & Checkov & TruffleHog & ZAP
  Git --> TruffleHog & CodeQL & Semgrep & Dependabot
  CICD --> Trivy & Semgrep & Checkov & Syft & Grype & ZAP
   IaC --> Checkov & Terrascan & OPA & Terraform
  AppSec --> Semgrep & CodeQL & ZAP & Snyk & Checkov
  Container --> Trivy & Syft & Grype & Cosign & Falco & OPA
  Secrets --> Vault & TruffleHog & GitGuardian
  SupplyChain --> Syft & Grype & Cosign & Trivy & Dependabot & Snyk
  Observ --> Prometheus & Grafana

  Docker --> Kubernetes
  Kubernetes --> Helm & Kustomize & ArgoCD
  Git --> GitHubActions
  CICD --> GitHubActions
  Trivy --> Syft & Grype & ZAP & Vault & Falco
  Falco --> Tetragon
  Semgrep --> ZAP & CodeQL & Snyk
  Checkov --> Terrascan & OPA
  TruffleHog --> GitGuardian
  Syft --> Grype & Cosign
  Grype --> Cosign
  Prometheus --> Grafana
```
