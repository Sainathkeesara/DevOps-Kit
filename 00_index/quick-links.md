# Quick Links

## I need to...

### Audit and remediate CVEs
- [Ansible CVE-2026-33228 path verification](../ansible/notes/2026-08-17-verify-ansible-cve-2026-33228-paths.md)
- [Trivy CVE severity filtering](../scripts/bash/ci_cd_toolkit/trivy-severity-filter.sh)
- [TruffleHog PR secret scan reusable workflow](../trufflehog/manifests/trufflehog-pr-secret-scan-reusable.yaml)

### Build and sign container images
- [First custom Docker image](../docker/dockerfiles/2026-07-10-first-custom-image.Dockerfile)
- [Sign and verify my first image](../cosign/snippets/first-cosign-sign-verify-image.sh)
- [Cosign verification patterns](../cosign/docs/cosign-verification-patterns.md)
- [Cosign key management workflow](../cosign/scripts/cosign-key-management-workflow.sh)
- [Custom Cosign image](../cosign/dockerfiles/custom-cosign-image.Dockerfile)
- [Multi-stage SBOM Dockerfile](../syft/dockerfiles/multi-stage-sbom.Dockerfile)
- [Multi-stage Grype scan Dockerfile](../grype/dockerfiles/multi-stage-grype-scan.Dockerfile)
- [Build a multi-service Docker Compose app](../docker/scripts/build-multi-service-compose-app.sh)
- [Syft + Trivy Kubernetes scan scaffold](../syft/templates/syft-trivy-k8s-scan-scaffold/README.md)

### Diagnose failures
- [Kubernetes CrashLoopBackOff](../docs/troubleshooting/k8s-crashloopbackoff.md)
- [Terraform errors](../docs/how-to/terraform-troubleshooting.md)
- [Vault seal/unseal troubleshooting](../docs/troubleshooting/vault-seal-unseal.md)

### Explore Tetragon observability
- [Tetragon observability tutorial](../tetragon/notes/2026-08-06-tetragon-observability-tutorial.md)
- [Minimal network tracing policy](../tetragon/configs/2026-08-05-minimal-network-tracing-policy.yaml)
- [Tetragon event collection pipeline](../tetragon/scripts/2026-08-05-tetragon-event-collection-pipeline.sh)

### Get started with vulnerability scanning
- [Install Trivy and run a first container scan](../trivy/notes/2026-09-05-install-trivy-first-container-scan.md)
- [Install ZAP and run a baseline scan](../zap/notes/2026-09-05-install-zap-first-baseline-scan.md)
- [Trivy primer](../trivy/notes/0000-primer-trivy.md)
- [Trivy scanning performance optimization](../trivy/notes/scanning-performance-optimization.md)
- [Trivy ignore-rules pipeline](../trivy/scripts/ignore-rules-pipeline.sh)
- [Trivy SARIF code-scanning output](../trivy/docs/ci-pipeline-sarif-output.md)
- [Multi-arch vulnerability scanning with Trivy](../trivy/docs/multi-arch-vulnerability-scanning.md)
- [Container vulnerability scan with Trivy](../trivy/scripts/container-vuln-scan.sh)
- [Minimal Grype scan](../grype/scripts/minimal-grype-scan.sh)
- [CI-ready Grype scanning](../grype/scripts/ci-ready-grype-scan.sh)
- [SBOM generation with Syft](../syft/scripts/gen-multi-format-sboms.sh)
- [Syft output format comparison](../syft/notebooks/output-format-comparison.ipynb)
- [Snyk vulnerability prioritization with reachability and Fix PRs](../snyk/docs/vulnerability-prioritization-reachability-fix-prs-license-compliance.md)
- [Snyk multi-language scan scaffold](../snyk/templates/snyk-multilang-scan-scaffold/README.md)

### Learn Linux shell scripting
- [Linux VM terminal first commands](../linux/notes/2026-07-21-install-linux-vm-terminal-first-commands.md)
- [Linux shell scripting tutorial confusions](../linux/notes/2026-08-06-linux-shell-scripting-tutorial-confusions.md)
- [Cron job configuration](../linux/configs/2026-08-06-cron-job-configuration.ini)

### Manage infrastructure as code
- [Terraform primer](../terraform/notes/0000-primer-terraform.md)
- [Composing Terraform modules](../terraform/docs/terraform-module-composition.md)
- [Terraform workspace variable precedence](../terraform/configs/workspace-variable-precedence.hcl)
- [OpenTofu primer](../opentofu/notes/0000-primer-opentofu.md)
- [Kubernetes primer](../kubernetes/notes/0000-primer-kubernetes.md)
- [Helm primer](../helm/notes/0000-primer-helm.md)
- [Kustomize primer](../kustomize/notes/0000-primer-kustomize.md)
- [ArgoCD primer](../argocd/notes/0000-primer-argocd.md)
- [ArgoCD private repo credentials and RBAC](../argocd/configs/2026-08-17-private-repo-credentials-rbac.yaml)
- [ArgoCD quickstart trip-ups](../argocd/notes/2026-08-12-quickstart-tripups.md)
- [Provision a Kubernetes cluster with Terraform + Ansible](../docs/how-to/k8s-terraform-ansible-provisioning.md)

### Manage policies and compliance
- [OPA/Gatekeeper primer](../opa/notes/0000-primer-opa.md)
- [My first OPA policy evaluation](../opa/snippets/my-first-opa-policy-eval.sh)
- [Gatekeeper constraint template design patterns](../opa/docs/constraint-template-design-patterns.md)
- [Gatekeeper policy library scaffold](../opa/templates/gatekeeper-policy-library-scaffold/README.md)
- [Gatekeeper production deployment manifest](../opa/manifests/gatekeeper-production-deployment.yaml)
- [Test Gatekeeper policies locally](../opa/templates/gatekeeper-policy-library-scaffold/tests/test-policies.sh)
- [Export Gatekeeper audit results](../opa/scripts/export-audit-results.sh)
- [Terrascan primer](../terrascan/notes/0000-primer-terrascan.md)

### Manage secrets and access
- [HashiCorp Vault primer](../vault/notes/0000-primer-vault.md)
- [Install Vault and run a first command](../vault/notes/2026-08-26-install-vault-first-command.md)
- [Vault KV CRUD operations](../vault/scripts/vault-kv-crud.sh)
- [Vault multi-environment access control](../vault/configs/multi-environment-access-control.hcl)
- [Vault AWS secrets engine policy](../vault/configs/2026-09-04-aws-secrets-engine-policy.hcl)
- [Vault dynamic secrets for cloud IAM](../vault/scripts/cloud-iam-dynamic-secrets.sh)
- [Vault Agent auto-auth on Kubernetes](../vault/docs/vault-agent-auto-auth-kubernetes.md)

### Practice and learn
- [Version control with Git fundamentals](../docs/concepts/git-001-version-control-fundamentals.md)
- [CI/CD pipeline concepts](../docs/concepts/ci-cd-pipeline-concepts/0000-primer-ci-cd-pipeline-concepts.md)
- [Application Security Testing concepts](../docs/concepts/application-security-testing-concepts/0000-primer-application-security-testing-concepts.md)
- [SCA and dependency exercises](../docs/concepts/application-security-testing-concepts/snippets/2026-08-26-appsec-sca-dependency-exercises.py)
- [Infrastructure as Code fundamentals](../docs/concepts/infrastructure-as-code/0000-primer-infrastructure-as-code.md)
- [Applying secrets & access management](../docs/concepts/secrets-access-management/snippets/2026-08-25-applying-secrets-access-management.py)
- [Applying version control in DevSecOps](../docs/concepts/version-control-with-git/snippets/2026-08-25-applying-version-control-in-devsecops.py)

### Run infrastructure tasks
- [Ansible quickstart trip-ups](../ansible/notes/2026-08-25-followed-ansible-quickstart-what-tripped-me-up.md)
- [Minimal Ansible playbook: package and service](../ansible/snippets/2026-08-25-minimal-ansible-playbook-package-service.yaml)
- [Context switcher](../scripts/bash/k8s_toolkit/context/context-manager.sh)
- [Rollout restart](../scripts/bash/k8s_toolkit/rollout-restart.sh)
- [Debug pod](../scripts/bash/k8s_toolkit/debug/debug-pod.sh)

### Run static analysis
- [Semgrep primer](../semgrep/notes/0000-primer-semgrep.md)
- [Checkov primer](../checkov/notes/0000-primer-checkov.md)
- [Checkov platform config](../checkov/configs/platform-config.yaml)
- [CodeQL primer](../codeql/notes/0000-primer-codeql.md)
- [Install CodeQL and run a first query](../codeql/notes/2026-08-26-install-codeql-first-query.md)
- [Custom Semgrep rule example](../semgrep/snippets/first-custom-rule.yaml)
- [Semgrep rule performance optimization](../semgrep/docs/semgrep-rule-performance-optimization.md)
- [AST-based security pattern checker](../docs/concepts/application-security-testing-concepts/scripts/2026-08-26-ast-devsecops.py)

### Scan for secrets
- [TruffleHog primer](../trufflehog/notes/0000-primer-trufflehog.md)
- [GitGuardian primer](../gitguardian/notes/0000-primer-gitguardian.md)
- [GitGuardian incident response workflow](../gitguardian/docs/gitguardian-incident-response-workflow.md)
- [GitGuardian API integration](../gitguardian/scripts/gitguardian-api-integration.py)
- [Scan a GitHub repo for secrets](../trufflehog/snippets/scan-github-repo-for-secrets.sh)
- [Secrets detection workflow analysis](../docs/concepts/secrets-access-management/notebooks/secrets-detection-remediation-workflow-analysis.ipynb)
- [Configure Dependabot for private registries](../dependabot/notes/2026-08-08-dependabot-custom-registry-tutorial.md)
- [Dependabot alerts and security updates](../dependabot/notes/2026-07-21-enabling-dependabot-alerts-security-updates.md)

### Secure version control
- [Git primer](../git/notes/0000-primer-git.md)
- [Git first repo stage and log](../git/scripts/2026-08-24-first-repo-stage-log.sh)
- [Git hooks for security checks](../docs/concepts/version-control-with-git/scripts/git-hooks-devsecops-security-checks.sh)

### Set up CI/CD pipelines
- [GitHub Actions primer](../github-actions/notes/0000-primer-github-actions.md)
- [Install the GitHub CLI and run a first command](../github-actions/notes/2026-08-26-install-gh-cli-first-command.md)
- [My first GitHub Actions workflow](../github-actions/snippets/2026-08-26-first-workflow.yaml)
- [Reusing inputs with a composite action](../github-actions/snippets/2026-08-26-composite-action-input-reuse.yaml)
- [CI/CD security scanner wrapper](../docs/concepts/linux-shell-fundamentals/scripts/ci-cd-pipeline-security-scanner-wrapper.sh)
- [ZAP baseline scan for CI](../zap/notes/2026-07-20-install-zap-baseline-scan.md)
- [Trivy CI/CD pipeline recipes](../trivy/docs/ci-cd-pipeline-recipes.md)
