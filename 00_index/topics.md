# Topics

> A map of what's here. For a beginner-to-advanced reading order, see [learning-path.md](learning-path.md).

## checkov  ·  44 files
- **primer:** [0000-primer-checkov.md](../checkov/notes/0000-primer-checkov.md)
- **notes** (4): [2026-05-27-checkov-quickstart-trip-ups.md](../checkov/notes/2026-05-27-checkov-quickstart-trip-ups.md), [2026-05-26-cli-vs-sdk-comparison.md](../checkov/notes/2026-05-26-cli-vs-sdk-comparison.md), [2026-05-25-scan-terraform-plan.md](../checkov/notes/2026-05-25-scan-terraform-plan.md) — _…and 1 more under `checkov/notes/`._
- **docs** (5): [checkov-v3-migration-guide.md](../checkov/docs/checkov-v3-migration-guide.md), [checkov-ai-infrastructure-checks.md](../checkov/docs/checkov-ai-infrastructure-checks.md), [checkov-integration-patterns.md](../checkov/docs/checkov-integration-patterns.md) — _…and 2 more under `checkov/docs/`._
- **scripts** (2): [deep-terraform-plan-scan.sh](../checkov/scripts/deep-terraform-plan-scan.sh), [scan-terraform-plan.sh](../checkov/scripts/scan-terraform-plan.sh)
- **configs** (3): [checkov-ci-config.yaml](../checkov/configs/checkov-ci-config.yaml), [platform-config.yaml](../checkov/configs/platform-config.yaml), [checkov-skip-severity-config.yaml](../checkov/configs/checkov-skip-severity-config.yaml)
- **snippets** (4): [scan-kubernetes.sh](../checkov/snippets/scan-kubernetes.sh), [scan-a-terraform-file.py](../checkov/snippets/scan-a-terraform-file.py), [scan-terraform-dir.py](../checkov/snippets/scan-terraform-dir.py) — _…and 1 more under `checkov/snippets/`._
- **templates** (20): [example-caller-workflow.yml](../checkov/templates/multi-repo-drift-auto-pr-remediation/example-caller-workflow.yml), [README.md](../checkov/templates/multi-repo-drift-auto-pr-remediation/README.md), [repositories.yaml](../checkov/templates/multi-repo-drift-auto-pr-remediation/repositories.yaml) — _…and 17 more under `checkov/templates/`._
- **manifests** (3): [checkov-sarif-pr-blocking.yaml](../checkov/manifests/checkov-sarif-pr-blocking.yaml), [checkov-gitlab-ci-multi-cloud-drift.yaml](../checkov/manifests/checkov-gitlab-ci-multi-cloud-drift.yaml), [layered-checkov-ci-pr-gate-deep-scan-merge-block.yaml](../checkov/manifests/layered-checkov-ci-pr-gate-deep-scan-merge-block.yaml)
- **notebooks** (2): [compare-static-vs-plan-scanning.ipynb](../checkov/notebooks/compare-static-vs-plan-scanning.ipynb), [compare-builtin-vs-custom-k8s.ipynb](../checkov/notebooks/compare-builtin-vs-custom-k8s.ipynb)
- **policies** (1): [no_public_s3_buckets.yaml](../checkov/policies/no-public-s3-buckets/no_public_s3_buckets.yaml)

## snyk  ·  23 files
- **primer:** [0000-primer-snyk.md](../snyk/notes/0000-primer-snyk.md)
- **notes** (4): [2026-06-14-first-vulnerability-scan.md](../snyk/notes/2026-06-14-first-vulnerability-scan.md), [2026-06-08-install-snyk-first-test.md](../snyk/notes/2026-06-08-install-snyk-first-test.md), [2026-06-07-snyk-quickstart-walkthrough.md](../snyk/notes/2026-06-07-snyk-quickstart-walkthrough.md) — _…and 1 more under `snyk/notes/`._
- **docs** (2): [vulnerability-prioritization-reachability-fix-prs-license-compliance.md](../snyk/docs/vulnerability-prioritization-reachability-fix-prs-license-compliance.md), [multi-project-ci-pipeline.md](../snyk/docs/multi-project-ci-pipeline.md)
- **scripts** (1): [snyk-vuln-scan-pipeline.sh](../snyk/scripts/snyk-vuln-scan-pipeline.sh)
- **configs** (2): [snyk-dependency-patch-ignore.yaml](../snyk/configs/snyk-dependency-patch-ignore.yaml), [snyk-ci-github-actions.yaml](../snyk/configs/snyk-ci-github-actions.yaml)
- **snippets** (1): [my-first-snyk-commands.sh](../snyk/snippets/my-first-snyk-commands.sh)
- **templates** (11): [README.md](../snyk/templates/snyk-multilang-scan-scaffold/README.md), [Makefile](../snyk/templates/snyk-multilang-scan-scaffold/Makefile), [snyk-multilang-ci.yml](../snyk/templates/snyk-multilang-scan-scaffold/.github/workflows/snyk-multilang-ci.yml) — _…and 8 more under `snyk/templates/`._
- **manifests** (1): [snyk-github-actions-cicd-workflow.yaml](../snyk/manifests/snyk-github-actions-cicd-workflow.yaml)
- **dockerfiles** (1): [custom-snyk-cli-air-gapped.Dockerfile](../snyk/dockerfiles/custom-snyk-cli-air-gapped.Dockerfile)

## trufflehog  ·  38 files
- **primer:** [0000-primer-trufflehog.md](../trufflehog/notes/0000-primer-trufflehog.md)
- **notes** (4): [2026-07-27-explore-cli.md](../trufflehog/notes/2026-07-27-explore-cli.md), [2026-05-27-following-trufflehog-quickstart.md](../trufflehog/notes/2026-05-27-following-trufflehog-quickstart.md), [2026-05-27-install-trufflehog.md](../trufflehog/notes/2026-05-27-install-trufflehog.md) — _…and 1 more under `trufflehog/notes/`._
- **docs** (2): [trufflehog-output-formats-json-sarif-csv.md](../trufflehog/docs/trufflehog-output-formats-json-sarif-csv.md), [comparing-scan-modes-git-filesystem-s3.md](../trufflehog/docs/comparing-scan-modes-git-filesystem-s3.md)
- **scripts** (3): [multi-repo-scan-pipeline.sh](../trufflehog/scripts/multi-repo-scan-pipeline.sh), [analyze-trufflehog-results.py](../trufflehog/scripts/analyze-trufflehog-results.py), [pre-commit-scan-pipeline.sh](../trufflehog/scripts/pre-commit-scan-pipeline.sh)
- **configs** (2): [custom-detector-rules.yaml](../trufflehog/configs/custom-detector-rules.yaml), [trufflehog-custom-regex-config.yaml](../trufflehog/configs/trufflehog-custom-regex-config.yaml)
- **snippets** (2): [scan-github-repo-for-secrets.sh](../trufflehog/snippets/scan-github-repo-for-secrets.sh), [fake-secrets-test.sh](../trufflehog/snippets/fake-secrets-test.sh)
- **templates** (21): [.gitignore](../trufflehog/templates/github-secret-scanning-integration/.gitignore), [Makefile](../trufflehog/templates/github-secret-scanning-integration/Makefile), [README.md](../trufflehog/templates/github-secret-scanning-integration/README.md) — _…and 18 more under `trufflehog/templates/`._
- **manifests** (1): [trufflehog-pr-secret-scan-reusable.yaml](../trufflehog/manifests/trufflehog-pr-secret-scan-reusable.yaml)
- **dockerfiles** (1): [pre-commit-scanner.Dockerfile](../trufflehog/dockerfiles/pre-commit-scanner.Dockerfile)
- **notebooks** (2): [analyzing-trufflehog-false-positives.ipynb](../trufflehog/notebooks/analyzing-trufflehog-false-positives.ipynb), [trufflehog-scan-modes-comparison.ipynb](../trufflehog/notebooks/trufflehog-scan-modes-comparison.ipynb)

## opa  ·  24 files
- **primer:** [0000-primer-opa.md](../opa/notes/0000-primer-opa.md)
- **notes** (3): [2026-06-15-opa-getting-started-trip-ups.md](../opa/notes/2026-06-15-opa-getting-started-trip-ups.md), [2026-06-06-install-opa-repl.md](../opa/notes/2026-06-06-install-opa-repl.md), [0000-primer-opa.md](../opa/notes/0000-primer-opa.md)
- **docs** (2): [wired-opa-admission-control.md](../opa/docs/wired-opa-admission-control.md), [constraint-template-design-patterns.md](../opa/docs/constraint-template-design-patterns.md)
- **scripts** (2): [how-i-test-policies-locally.sh](../opa/scripts/how-i-test-policies-locally.sh), [export-audit-results.sh](../opa/scripts/export-audit-results.sh)
- **configs** (1): [tried-a-gatekeeper-constraint.yaml](../opa/configs/tried-a-gatekeeper-constraint.yaml)
- **snippets** (3): [my-first-opa-policy-eval.sh](../opa/snippets/my-first-opa-policy-eval.sh), [enforce-image-registry-constraints.rego](../opa/snippets/enforce-image-registry-constraints.rego), [deny-privileged-hostnetwork.rego](../opa/snippets/deny-privileged-hostnetwork.rego)
- **templates** (9): [README.md](../opa/templates/gatekeeper-policy-library-scaffold/README.md), [k8sallowedregistries.yaml](../opa/templates/gatekeeper-policy-library-scaffold/constraint-templates/k8sallowedregistries.yaml), [k8ssecuritybaseline.yaml](../opa/templates/gatekeeper-policy-library-scaffold/constraint-templates/k8ssecuritybaseline.yaml) — _…and 6 more under `opa/templates/`._
- **manifests** (4): [constraint-templates.yaml](../opa/manifests/constraint-templates.yaml), [constraints.yaml](../opa/manifests/constraints.yaml), [gatekeeper-production-deployment.yaml](../opa/manifests/gatekeeper-production-deployment.yaml), [README.md](../opa/manifests/README.md)

## syft  ·  35 files
- **primer:** [0000-primer-syft.md](../syft/notes/0000-primer-syft.md)
- **notes** (4): [2026-05-30-sbom-format-comparison.md](../syft/notes/2026-05-30-sbom-format-comparison.md), [2026-05-29-syft-quickstart-trip-ups.md](../syft/notes/2026-05-29-syft-quickstart-trip-ups.md), [2026-05-27-install-syft-first-sbom.md](../syft/notes/2026-05-27-install-syft-first-sbom.md) — _…and 1 more under `syft/notes/`._
- **docs** (6): [output-format-selection-guide.md](../syft/docs/output-format-selection-guide.md), [enterprise-registry-auth-caching.md](../syft/docs/enterprise-registry-auth-caching.md), [sbom-output-formats-reference.md](../syft/docs/sbom-output-formats-reference.md) — _…and 3 more under `syft/docs/`._
- **scripts** (3): [gen-multi-format-sboms.sh](../syft/scripts/gen-multi-format-sboms.sh), [multi-image-sbom-pipeline.sh](../syft/scripts/multi-image-sbom-pipeline.sh), [sbom-vuln-pipeline.sh](../syft/scripts/sbom-vuln-pipeline.sh)
- **configs** (1): [.syft.yaml](../syft/configs/.syft.yaml)
- **snippets** (1): [tried-sbom-formats.sh](../syft/snippets/tried-sbom-formats.sh)
- **templates** (15): [.gitignore](../syft/templates/syft-trivy-k8s-scan-scaffold/.gitignore), [syft.yaml](../syft/templates/syft-trivy-k8s-scan-scaffold/syft.yaml), [trivy.yaml](../syft/templates/syft-trivy-k8s-scan-scaffold/trivy.yaml) — _…and 12 more under `syft/templates/`._
- **manifests** (2): [syft-gha-multi-arch-sbom-registry-auth.yaml](../syft/manifests/syft-gha-multi-arch-sbom-registry-auth.yaml), [syft-gha-sbom-oci-push-attestation.yaml](../syft/manifests/syft-gha-sbom-oci-push-attestation.yaml)
- **dockerfiles** (1): [multi-stage-sbom.Dockerfile](../syft/dockerfiles/multi-stage-sbom.Dockerfile)
- **notebooks** (2): [sbom-layer-package-analysis.ipynb](../syft/notebooks/sbom-layer-package-analysis.ipynb), [output-format-comparison.ipynb](../syft/notebooks/output-format-comparison.ipynb)

## trivy  ·  35 files
- **primer:** [0000-primer-trivy.md](../trivy/notes/0000-primer-trivy.md)
- **notes** (6): [2026-09-05-install-trivy-first-container-scan.md](../trivy/notes/2026-09-05-install-trivy-first-container-scan.md), [2026-07-27-first-container-scan.md](../trivy/notes/2026-07-27-first-container-scan.md), [2026-05-26-trivy-quickstart.md](../trivy/notes/2026-05-26-trivy-quickstart.md) — _…and 3 more under `trivy/notes/`._
- **docs** (4): [multi-arch-vulnerability-scanning.md](../trivy/docs/multi-arch-vulnerability-scanning.md), [ci-cd-pipeline-recipes.md](../trivy/docs/ci-cd-pipeline-recipes.md), [sbom-scanning-reference-guide.md](../trivy/docs/sbom-scanning-reference-guide.md) — _…and 1 more under `trivy/docs/`._
- **scripts** (6): [compose-multi-scan.sh](../trivy/scripts/compose-multi-scan.sh), [multi-target-scanner.sh](../trivy/scripts/multi-target-scanner.sh), [container-vuln-scan.sh](../trivy/scripts/container-vuln-scan.sh) — _…and 3 more under `trivy/scripts/`._
- **configs** (2): [trivy-scan-config.yaml](../trivy/configs/trivy-scan-config.yaml), [.trivy.yaml](../trivy/configs/.trivy.yaml)
- **snippets** (1): [scan-docker-image.sh](../trivy/snippets/scan-docker-image.sh)
- **templates** (11): [k8s-scan-job.yaml](../trivy/templates/trivy-k8s-workload-scanning/k8s-scan-job.yaml), [k8s-scan-cronjob.yaml](../trivy/templates/trivy-k8s-workload-scanning/k8s-scan-cronjob.yaml), [README.md](../trivy/templates/trivy-k8s-workload-scanning/README.md) — _…and 8 more under `trivy/templates/`._
- **manifests** (2): [trivy-operator-deployment.yaml](../trivy/manifests/trivy-operator-deployment.yaml), [trivy-sarif-code-scanning.yaml](../trivy/manifests/trivy-sarif-code-scanning.yaml)
- **dockerfiles** (1): [custom-policies.Dockerfile](../trivy/dockerfiles/custom-policies.Dockerfile)
- **notebooks** (2): [trivy-sarif-output-processing.ipynb](../trivy/notebooks/trivy-sarif-output-processing.ipynb), [trivy-scan-mode-comparison.ipynb](../trivy/notebooks/trivy-scan-mode-comparison.ipynb)

## zap  ·  26 files
- **primer:** [0000-primer-zap.md](../zap/notes/0000-primer-zap.md)
- **notes** (6): [2026-09-05-install-zap-first-baseline-scan.md](../zap/notes/2026-09-05-install-zap-first-baseline-scan.md), [2026-07-20-install-zap-baseline-scan.md](../zap/notes/2026-07-20-install-zap-baseline-scan.md), [2026-06-13-spider-scan-test-app.md](../zap/notes/2026-06-13-spider-scan-test-app.md) — _…and 3 more under `zap/notes/`._
- **docs** (3): [zap-integration-patterns.md](../zap/docs/zap-integration-patterns.md), [zap-automation-plan-structure.md](../zap/docs/zap-automation-plan-structure.md), [passive-vs-active-scanning-zap.md](../zap/docs/passive-vs-active-scanning-zap.md)
- **scripts** (2): [dast-workflow-from-scratch.sh](../zap/scripts/dast-workflow-from-scratch.sh), [zap-dast-sarif-code-scanning.sh](../zap/scripts/zap-dast-sarif-code-scanning.sh)
- **configs** (2): [ci-dast-automation-framework-plan.yaml](../zap/configs/ci-dast-automation-framework-plan.yaml), [zap-authenticated-scan-context.yaml](../zap/configs/zap-authenticated-scan-context.yaml)
- **snippets** (4): [2026-07-16-zap-docker-quickstart-json-export.sh](../zap/snippets/2026-07-16-zap-docker-quickstart-json-export.sh), [my-first-zap-baseline-scan.sh](../zap/snippets/my-first-zap-baseline-scan.sh), [my-first-zap-spider-scan.sh](../zap/snippets/my-first-zap-spider-scan.sh) — _…and 1 more under `zap/snippets/`._
- **templates** (8): [zap-automation-plan.yaml](../zap/templates/zap-dast-integration-scaffold/zap-automation-plan.yaml), [.gitignore](../zap/templates/zap-dast-integration-scaffold/.gitignore), [Makefile](../zap/templates/zap-dast-integration-scaffold/Makefile) — _…and 5 more under `zap/templates/`._
- **dockerfiles** (1): [custom-zap-automation.Dockerfile](../zap/dockerfiles/custom-zap-automation.Dockerfile)

## gitguardian  ·  22 files
- **primer:** [0000-primer-gitguardian.md](../gitguardian/notes/0000-primer-gitguardian.md)
- **notes** (4): [2026-06-14-first-secrets-scan-repo.md](../gitguardian/notes/2026-06-14-first-secrets-scan-repo.md), [2026-06-13-ggshield-quickstart-trip-ups.md](../gitguardian/notes/2026-06-13-ggshield-quickstart-trip-ups.md), [2026-06-07-first-ggshield-scan.md](../gitguardian/notes/2026-06-07-first-ggshield-scan.md) — _…and 1 more under `gitguardian/notes/`._
- **docs** (2): [monorepo-ci-per-team-exclusions.md](../gitguardian/docs/monorepo-ci-per-team-exclusions.md), [gitguardian-incident-response-workflow.md](../gitguardian/docs/gitguardian-incident-response-workflow.md)
- **scripts** (3): [gitguardian-api-integration.py](../gitguardian/scripts/gitguardian-api-integration.py), [pre-commit-hook-ggshield.sh](../gitguardian/scripts/pre-commit-hook-ggshield.sh), [gg-incident-response-pipeline.sh](../gitguardian/scripts/gg-incident-response-pipeline.sh)
- **configs** (2): [monorepo-allowlists.yaml](../gitguardian/configs/monorepo-allowlists.yaml), [.ggshield.yaml](../gitguardian/configs/.ggshield.yaml)
- **snippets** (2): [custom-policy-engine-ggshield.sh](../gitguardian/snippets/custom-policy-engine-ggshield.sh), [my-first-ggshield-commands.sh](../gitguardian/snippets/my-first-ggshield-commands.sh)
- **templates** (9): [.gitignore](../gitguardian/templates/gitguardian-multi-repo-scanning-scaffold/.gitignore), [ggshield.yaml](../gitguardian/templates/gitguardian-multi-repo-scanning-scaffold/ggshield.yaml), [Makefile](../gitguardian/templates/gitguardian-multi-repo-scanning-scaffold/Makefile) — _…and 6 more under `gitguardian/templates/`._

## grype  ·  20 files
- **primer:** [0000-primer-grype.md](../grype/notes/0000-primer-grype.md)
- **notes** (4): [2026-06-08-first-grype-scan.md](../grype/notes/2026-06-08-first-grype-scan.md), [2026-06-04-grype-quickstart-trip-ups.md](../grype/notes/2026-06-04-grype-quickstart-trip-ups.md), [2026-05-31-install-grype.md](../grype/notes/2026-05-31-install-grype.md) — _…and 1 more under `grype/notes/`._
- **docs** (1): [grype-syft-integration-guide.md](../grype/docs/grype-syft-integration-guide.md)
- **scripts** (8): [grype-scan-pipeline-end-to-end.sh](../grype/scripts/grype-scan-pipeline-end-to-end.sh), [grype-pipeline-ci-scan.sh](../grype/scripts/grype-pipeline-ci-scan.sh), [ci-ready-grype-scan.sh](../grype/scripts/ci-ready-grype-scan.sh) — _…and 5 more under `grype/scripts/`._
- **configs** (1): [grype-ci-github-actions.yaml](../grype/configs/grype-ci-github-actions.yaml)
- **snippets** (2): [minimal-grype-scan.go](../grype/snippets/minimal-grype-scan.go), [my-first-grype-commands.sh](../grype/snippets/my-first-grype-commands.sh)
- **manifests** (2): [grype-sarif-reusable-workflow.yaml](../grype/manifests/grype-sarif-reusable-workflow.yaml), [grype-reusable-sarif-workflow.yaml](../grype/manifests/grype-reusable-sarif-workflow.yaml)
- **dockerfiles** (1): [multi-stage-grype-scan.Dockerfile](../grype/dockerfiles/multi-stage-grype-scan.Dockerfile)
- **notebooks** (1): [grype-sbom-output-explorer.ipynb](../grype/notebooks/grype-sbom-output-explorer.ipynb)

## terraform  ·  20 files
- **primer:** [0000-primer-terraform.md](../terraform/notes/0000-primer-terraform.md)
- **notes** (3): [2026-08-04-install-terraform-first-vm.md](../terraform/notes/2026-08-04-install-terraform-first-vm.md), [2026-07-15-explore-terraform.md](../terraform/notes/2026-07-15-explore-terraform.md), [0000-primer-terraform.md](../terraform/notes/0000-primer-terraform.md)
- **docs** (1): [terraform-module-composition.md](../terraform/docs/terraform-module-composition.md)
- **scripts** (4): [2026-07-18-deploy.sh](../terraform/scripts/2026-07-18-deploy.sh), [2026-07-18-cleanup.sh](../terraform/scripts/2026-07-18-cleanup.sh), [2026-07-13-zip-build.sh](../terraform/scripts/2026-07-13-zip-build.sh) — _…and 1 more under `terraform/scripts/`._
- **configs** (4): [2026-08-04-first-configuration.hcl](../terraform/configs/2026-08-04-first-configuration.hcl), [2026-07-15-first-config.tf](../terraform/configs/2026-07-15-first-config.tf), [workspace-variable-precedence.hcl](../terraform/configs/workspace-variable-precedence.hcl) — _…and 1 more under `terraform/configs/`._
- **snippets** (1): [2026-07-20-practice-terraform-variables-outputs-datasources.hcl](../terraform/snippets/2026-07-20-practice-terraform-variables-outputs-datasources.hcl)

## semgrep  ·  20 files
- **primer:** [0000-primer-semgrep.md](../semgrep/notes/0000-primer-semgrep.md)
- **notes** (3): [2026-05-26-install-semgrep-pitfalls.md](../semgrep/notes/2026-05-26-install-semgrep-pitfalls.md), [2026-05-25-install-semgrep.md](../semgrep/notes/2026-05-25-install-semgrep.md), [0000-primer-semgrep.md](../semgrep/notes/0000-primer-semgrep.md)
- **docs** (5): [github-actions-ci-from-scratch.md](../semgrep/docs/github-actions-ci-from-scratch.md), [comparing-rule-writing-approaches.md](../semgrep/docs/comparing-rule-writing-approaches.md), [semgrep-rule-writing-reference.md](../semgrep/docs/semgrep-rule-writing-reference.md) — _…and 2 more under `semgrep/docs/`._
- **scripts** (3): [bulk-scan-helper.py](../semgrep/scripts/bulk-scan-helper.py), [detect-hardcoded-secrets.py](../semgrep/scripts/detect-hardcoded-secrets.py), [scan-python-codebase.sh](../semgrep/scripts/scan-python-codebase.sh)
- **configs** (1): [multi-rule-pack.yaml](../semgrep/configs/multi-rule-pack.yaml)
- **snippets** (2): [first-custom-rule.yaml](../semgrep/snippets/first-custom-rule.yaml), [catch-privileged-containers.yaml](../semgrep/snippets/catch-privileged-containers.yaml)
- **manifests** (2): [diff-aware-semgrep-ci.yaml](../semgrep/manifests/diff-aware-semgrep-ci.yaml), [semgrep-gitlab-ci.yaml](../semgrep/manifests/semgrep-gitlab-ci.yaml)
- **dockerfiles** (2): [custom-scanning-image.Dockerfile](../semgrep/dockerfiles/custom-scanning-image.Dockerfile), [ci-entrypoint.sh](../semgrep/dockerfiles/ci-entrypoint.sh)
- **notebooks** (2): [semgrep-scan-vs-ci-comparison.ipynb](../semgrep/notebooks/semgrep-scan-vs-ci-comparison.ipynb), [comparing-community-vs-custom-rules.ipynb](../semgrep/notebooks/comparing-community-vs-custom-rules.ipynb)

## terrascan  ·  18 files
- **primer:** [0000-primer-terrascan.md](../terrascan/notes/0000-primer-terrascan.md)
- **notes** (5): [2026-07-10-terrascan-getting-started-trip-ups.md](../terrascan/notes/2026-07-10-terrascan-getting-started-trip-ups.md), [2026-06-29-terrascan-getting-started-trip-ups.md](../terrascan/notes/2026-06-29-terrascan-getting-started-trip-ups.md), [2026-06-19-install-terrascan-tiny-tf.md](../terrascan/notes/2026-06-19-install-terrascan-tiny-tf.md) — _…and 2 more under `terrascan/notes/`._
- **docs** (1): [terrascan-vs-checkov-terraform-iac-scanning.md](../terrascan/docs/terrascan-vs-checkov-terraform-iac-scanning.md)
- **scripts** (2): [tried-terrascan-ci-scan.sh](../terrascan/scripts/tried-terrascan-ci-scan.sh), [policy-as-code-workflow.sh](../terrascan/scripts/policy-as-code-workflow.sh)
- **configs** (1): [tried-custom-s3-rule.yaml](../terrascan/configs/tried-custom-s3-rule.yaml)
- **snippets** (2): [insecure-terraform.tf](../terrascan/snippets/insecure-terraform.tf), [tiny-tf-with-findings.tf](../terrascan/snippets/tiny-tf-with-findings.tf)
- **templates** (6): [.gitignore](../terrascan/templates/scanning-pipeline-scaffold/.gitignore), [config.yaml](../terrascan/templates/scanning-pipeline-scaffold/config.yaml), [README.md](../terrascan/templates/scanning-pipeline-scaffold/README.md) — _…and 3 more under `terrascan/templates/`._
- **manifests** (1): [terrascan-gha-ci-multi-iac.yaml](../terrascan/manifests/terrascan-gha-ci-multi-iac.yaml)

## vault  ·  16 files
- **primer:** [0000-primer-vault.md](../vault/notes/0000-primer-vault.md)
- **notes** (4): [2026-08-26-install-vault-first-command.md](../vault/notes/2026-08-26-install-vault-first-command.md), [2026-06-15-vault-getting-started-trip-ups.md](../vault/notes/2026-06-15-vault-getting-started-trip-ups.md), [2026-06-05-install-vault-and-explore-cli.md](../vault/notes/2026-06-05-install-vault-and-explore-cli.md) — _…and 1 more under `vault/notes/`._
- **docs** (3): [vault-secrets-engine-selection-guide.md](../vault/docs/vault-secrets-engine-selection-guide.md), [vault-agent-auto-auth-kubernetes.md](../vault/docs/vault-agent-auto-auth-kubernetes.md), [configuring-vault-dev-server.md](../vault/docs/configuring-vault-dev-server.md)
- **scripts** (3): [vault-kv-crud.sh](../vault/scripts/vault-kv-crud.sh), [vault-db-dynamic-secrets.sh](../vault/scripts/vault-db-dynamic-secrets.sh), [cloud-iam-dynamic-secrets.sh](../vault/scripts/cloud-iam-dynamic-secrets.sh)
- **configs** (3): [2026-09-04-aws-secrets-engine-policy.hcl](../vault/configs/2026-09-04-aws-secrets-engine-policy.hcl), [2026-06-26-dev-test-policies.hcl](../vault/configs/2026-06-26-dev-test-policies.hcl), [multi-environment-access-control.hcl](../vault/configs/multi-environment-access-control.hcl)
- **snippets** (2): [2026-08-30-first-vault-secret.sh](../vault/snippets/2026-08-30-first-vault-secret.sh), [vault-read-write.go](../vault/snippets/vault-read-write.go)
- **dockerfiles** (1): [custom-vault-image-with-plugins-tls.Dockerfile](../vault/dockerfiles/custom-vault-image-with-plugins-tls.Dockerfile)

## cosign  ·  14 files
- **primer:** [0000-primer-cosign.md](../cosign/notes/0000-primer-cosign.md)
- **notes** (4): [2026-06-22-cosign-getting-started-trip-ups.md](../cosign/notes/2026-06-22-cosign-getting-started-trip-ups.md), [2026-06-14-install-cosign-generate-first-keypair.md](../cosign/notes/2026-06-14-install-cosign-generate-first-keypair.md), [2026-06-13-install-cosign-sign-first-image.md](../cosign/notes/2026-06-13-install-cosign-sign-first-image.md) — _…and 1 more under `cosign/notes/`._
- **docs** (1): [cosign-verification-patterns.md](../cosign/docs/cosign-verification-patterns.md)
- **scripts** (3): [verify-signed-image.sh](../cosign/scripts/verify-signed-image.sh), [minimal-sign-verify.sh](../cosign/scripts/minimal-sign-verify.sh), [cosign-key-management-workflow.sh](../cosign/scripts/cosign-key-management-workflow.sh)
- **configs** (1): [keyless-signing-github-actions.yaml](../cosign/configs/keyless-signing-github-actions.yaml)
- **snippets** (1): [first-cosign-sign-verify-image.sh](../cosign/snippets/first-cosign-sign-verify-image.sh)
- **manifests** (2): [2026-07-10-keyless-oidc-ci.yaml](../cosign/manifests/2026-07-10-keyless-oidc-ci.yaml), [signed-container-build-oidc.yaml](../cosign/manifests/signed-container-build-oidc.yaml)
- **dockerfiles** (2): [entrypoint.sh](../cosign/dockerfiles/entrypoint.sh), [custom-cosign-image.Dockerfile](../cosign/dockerfiles/custom-cosign-image.Dockerfile)

## dependabot  ·  14 files
- **primer:** [0000-primer-dependabot.md](../dependabot/notes/0000-primer-dependabot.md)
- **notes** (7): [2026-08-08-dependabot-custom-registry-tutorial.md](../dependabot/notes/2026-08-08-dependabot-custom-registry-tutorial.md), [2026-07-21-enabling-dependabot-alerts-security-updates.md](../dependabot/notes/2026-07-21-enabling-dependabot-alerts-security-updates.md), [2026-07-10-enabling-dependabot-alerts.md](../dependabot/notes/2026-07-10-enabling-dependabot-alerts.md) — _…and 4 more under `dependabot/notes/`._
- **docs** (1): [dependabot-security-update-auto-merge.md](../dependabot/docs/dependabot-security-update-auto-merge.md)
- **scripts** (2): [2026-08-04-dependabot-alert-triage.py](../dependabot/scripts/2026-08-04-dependabot-alert-triage.py), [dependabot-alert-aggregation.py](../dependabot/scripts/dependabot-alert-aggregation.py)
- **configs** (4): [2026-07-18-python-project-version-update.yaml](../dependabot/configs/2026-07-18-python-project-version-update.yaml), [2026-07-10-npm-version-strategy.yaml](../dependabot/configs/2026-07-10-npm-version-strategy.yaml), [tried-npm-dependabot.yaml](../dependabot/configs/tried-npm-dependabot.yaml) — _…and 1 more under `dependabot/configs/`._

## falco  ·  13 files
- **primer:** [0000-primer-falco.md](../falco/notes/0000-primer-falco.md)
- **notes** (4): [2026-07-19-explore-falco-cli-rules-events-output.md](../falco/notes/2026-07-19-explore-falco-cli-rules-events-output.md), [2026-06-15-falco-rules-macros-lists.md](../falco/notes/2026-06-15-falco-rules-macros-lists.md), [2026-06-10-install-falco-first-detection.md](../falco/notes/2026-06-10-install-falco-first-detection.md) — _…and 1 more under `falco/notes/`._
- **docs** (2): [tuned-falco-rules-noise-reduction.md](../falco/docs/tuned-falco-rules-noise-reduction.md), [syscall-vs-tracepoint-rules.md](../falco/docs/syscall-vs-tracepoint-rules.md)
- **scripts** (3): [deploy-falco-ruleset.sh](../falco/scripts/deploy-falco-ruleset.sh), [tried-falco-k8s-deploy-alert-forwarding.sh](../falco/scripts/tried-falco-k8s-deploy-alert-forwarding.sh), [tried-falco-k8s-alert-forwarding.sh](../falco/scripts/tried-falco-k8s-alert-forwarding.sh)
- **configs** (3): [2026-06-10-first-custom-rule-detect-shell-in-container.yaml](../falco/configs/2026-06-10-first-custom-rule-detect-shell-in-container.yaml), [first-custom-rule-detect-shell-in-container.yaml](../falco/configs/first-custom-rule-detect-shell-in-container.yaml), [container-drift-detection.yaml](../falco/configs/container-drift-detection.yaml)
- **snippets** (1): [tried-file-access-detector.go](../falco/snippets/tried-file-access-detector.go)

## codeql  ·  13 files
- **primer:** [0000-primer-codeql.md](../codeql/notes/0000-primer-codeql.md)
- **notes** (4): [2026-08-26-install-codeql-first-query.md](../codeql/notes/2026-08-26-install-codeql-first-query.md), [2026-06-14-codeql-datalog-gotchas.md](../codeql/notes/2026-06-14-codeql-datalog-gotchas.md), [2026-06-05-install-codeql-first-analysis.md](../codeql/notes/2026-06-05-install-codeql-first-analysis.md) — _…and 1 more under `codeql/notes/`._
- **docs** (1): [wired-custom-queries-into-ci.md](../codeql/docs/wired-custom-queries-into-ci.md)
- **scripts** (1): [first-codeql-analysis.sh](../codeql/scripts/first-codeql-analysis.sh)
- **configs** (1): [first-codeql-analysis.yml](../codeql/configs/first-codeql-analysis.yml)
- **snippets** (4): [find-hardcoded-creds.ql](../codeql/snippets/find-hardcoded-creds.ql), [my-first-codeql-commands.sh](../codeql/snippets/my-first-codeql-commands.sh), [hardcoded-creds-local-flow.ql](../codeql/snippets/hardcoded-creds-local-flow.ql) — _…and 1 more under `codeql/snippets/`._
- **manifests** (1): [multi-language-codeql-analysis.yaml](../codeql/manifests/multi-language-codeql-analysis.yaml)
- **dockerfiles** (1): [custom-codeql-analysis-image.Dockerfile](../codeql/dockerfiles/custom-codeql-analysis-image.Dockerfile)

## github-actions  ·  10 files
- **primer:** [0000-primer-github-actions.md](../github-actions/notes/0000-primer-github-actions.md)
- **notes** (4): [2026-08-26-install-gh-cli-first-command.md](../github-actions/notes/2026-08-26-install-gh-cli-first-command.md), [2026-08-04-explore-github-actions.md](../github-actions/notes/2026-08-04-explore-github-actions.md), [2026-07-14-explore-github-actions.md](../github-actions/notes/2026-07-14-explore-github-actions.md) — _…and 1 more under `github-actions/notes/`._
- **configs** (2): [2026-08-04-first-workflow.yaml](../github-actions/configs/2026-08-04-first-workflow.yaml), [2026-07-14-first-github-actions-workflow.yaml](../github-actions/configs/2026-07-14-first-github-actions-workflow.yaml)
- **snippets** (2): [2026-08-26-first-workflow.yaml](../github-actions/snippets/2026-08-26-first-workflow.yaml), [2026-08-26-composite-action-input-reuse.yaml](../github-actions/snippets/2026-08-26-composite-action-input-reuse.yaml)
- **manifests** (2): [2026-08-04-what-is-github-actions.yaml](../github-actions/manifests/2026-08-04-what-is-github-actions.yaml), [2026-08-04-pr-validation.yml](../github-actions/manifests/2026-08-04-pr-validation.yml)

## argocd  ·  9 files
- **primer:** [0000-primer-argocd.md](../argocd/notes/0000-primer-argocd.md)
- **notes** (6): [2026-08-12-quickstart-tripups.md](../argocd/notes/2026-08-12-quickstart-tripups.md), [2026-08-01-verify-readme-layout.md](../argocd/notes/2026-08-01-verify-readme-layout.md), [2026-07-31-verify-readme-layout.md](../argocd/notes/2026-07-31-verify-readme-layout.md) — _…and 3 more under `argocd/notes/`._
- **configs** (1): [2026-08-17-private-repo-credentials-rbac.yaml](../argocd/configs/2026-08-17-private-repo-credentials-rbac.yaml)
- **manifests** (2): [2026-08-12-gitops-sync-sample-web-app.yaml](../argocd/manifests/2026-08-12-gitops-sync-sample-web-app.yaml), [2026-07-06-sample-app-application.yaml](../argocd/manifests/2026-07-06-sample-app-application.yaml)

## docker  ·  8 files
- **primer:** [0000-primer-docker.md](../docker/notes/0000-primer-docker.md)
- **notes** (2): [2026-07-12-explore-docker-cli.md](../docker/notes/2026-07-12-explore-docker-cli.md), [0000-primer-docker.md](../docker/notes/0000-primer-docker.md)
- **docs** (1): [dockerfile-optimization-patterns.md](../docker/docs/dockerfile-optimization-patterns.md)
- **scripts** (2): [2026-07-18-custom-network-volume-mounts.sh](../docker/scripts/2026-07-18-custom-network-volume-mounts.sh), [build-multi-service-compose-app.sh](../docker/scripts/build-multi-service-compose-app.sh)
- **configs** (1): [docker-compose-dev-environment.yaml](../docker/configs/docker-compose-dev-environment.yaml)
- **dockerfiles** (2): [2026-07-12-first-custom-docker-image.Dockerfile](../docker/dockerfiles/2026-07-12-first-custom-docker-image.Dockerfile), [2026-07-10-first-custom-image.Dockerfile](../docker/dockerfiles/2026-07-10-first-custom-image.Dockerfile)

## git  ·  7 files
- **primer:** [0000-primer-git.md](../git/notes/0000-primer-git.md)
- **notes** (3): [2026-07-12-install-git-identity-first-commit.md](../git/notes/2026-07-12-install-git-identity-first-commit.md), [2026-07-04-git-branching-merge-confusions.md](../git/notes/2026-07-04-git-branching-merge-confusions.md), [0000-primer-git.md](../git/notes/0000-primer-git.md)
- **scripts** (3): [2026-08-24-first-repo-stage-log.sh](../git/scripts/2026-08-24-first-repo-stage-log.sh), [2026-07-12-bump-version.sh](../git/scripts/2026-07-12-bump-version.sh), [2026-07-10-local-ci-simulation.sh](../git/scripts/2026-07-10-local-ci-simulation.sh)
- **snippets** (1): [2026-07-04-git-rebase-vs-merge-conflict-patterns.sh](../git/snippets/2026-07-04-git-rebase-vs-merge-conflict-patterns.sh)

## ansible  ·  6 files
- **notes** (2): [2026-08-25-followed-ansible-quickstart-what-tripped-me-up.md](../ansible/notes/2026-08-25-followed-ansible-quickstart-what-tripped-me-up.md), [2026-08-17-verify-ansible-cve-2026-33228-paths.md](../ansible/notes/2026-08-17-verify-ansible-cve-2026-33228-paths.md)
- **scripts** (3): [2026-08-04-bootstrap-node.sh](../ansible/scripts/2026-08-04-bootstrap-node.sh), [bootstrap-target-node.sh](../ansible/scripts/bootstrap-target-node.sh), [bootstrap.sh](../ansible/scripts/bootstrap.sh)
- **snippets** (1): [2026-08-25-minimal-ansible-playbook-package-service.yaml](../ansible/snippets/2026-08-25-minimal-ansible-playbook-package-service.yaml)

## tetragon  ·  6 files
- **primer:** [0000-primer-tetragon.md](../tetragon/notes/0000-primer-tetragon.md)
- **notes** (3): [2026-08-06-tetragon-observability-tutorial.md](../tetragon/notes/2026-08-06-tetragon-observability-tutorial.md), [2026-06-23-install-tetragon-docker-first-events.md](../tetragon/notes/2026-06-23-install-tetragon-docker-first-events.md), [0000-primer-tetragon.md](../tetragon/notes/0000-primer-tetragon.md)
- **scripts** (1): [2026-08-05-tetragon-event-collection-pipeline.sh](../tetragon/scripts/2026-08-05-tetragon-event-collection-pipeline.sh)
- **configs** (2): [2026-08-05-minimal-network-tracing-policy.yaml](../tetragon/configs/2026-08-05-minimal-network-tracing-policy.yaml), [first-tracing-policy-exec-file.yaml](../tetragon/configs/first-tracing-policy-exec-file.yaml)

## kustomize  ·  3 files
- **primer:** [0000-primer-kustomize.md](../kustomize/notes/0000-primer-kustomize.md)
- **notes** (2): [2026-07-08-install-kustomize-first-overlay.md](../kustomize/notes/2026-07-08-install-kustomize-first-overlay.md), [0000-primer-kustomize.md](../kustomize/notes/0000-primer-kustomize.md)
- **configs** (1): [2026-07-08-minimal-kustomization.yaml](../kustomize/configs/2026-07-08-minimal-kustomization.yaml)

## helm  ·  3 files
- **primer:** [0000-primer-helm.md](../helm/notes/0000-primer-helm.md)
- **notes** (2): [2026-07-19-explore-helm-charts-releases-values-repos.md](../helm/notes/2026-07-19-explore-helm-charts-releases-values-repos.md), [0000-primer-helm.md](../helm/notes/0000-primer-helm.md)
- **manifests** (1): [2026-07-15-first-chart-values.yaml](../helm/manifests/2026-07-15-first-chart-values.yaml)

## sonarqube  ·  3 files
- **primer:** [0000-primer-sonarqube.md](../sonarqube/notes/0000-primer-sonarqube.md)
- **notes** (2): [2026-07-19-explore-sonarqube-quality-gates-profiles.md](../sonarqube/notes/2026-07-19-explore-sonarqube-quality-gates-profiles.md), [0000-primer-sonarqube.md](../sonarqube/notes/0000-primer-sonarqube.md)
- **snippets** (1): [2026-07-16-first-sonarscanner-run.sh](../sonarqube/snippets/2026-07-16-first-sonarscanner-run.sh)

## opentofu  ·  3 files
- **primer:** [0000-primer-opentofu.md](../opentofu/notes/0000-primer-opentofu.md)
- **notes** (2): [2026-07-20-explore-open-tofu.md](../opentofu/notes/2026-07-20-explore-open-tofu.md), [0000-primer-opentofu.md](../opentofu/notes/0000-primer-opentofu.md)
- **configs** (1): [2026-07-20-first-open-tofu-config.hcl](../opentofu/configs/2026-07-20-first-open-tofu-config.hcl)

## kubernetes  ·  3 files
- **primer:** [0000-primer-kubernetes.md](../kubernetes/notes/0000-primer-kubernetes.md)
- **notes** (2): [2026-07-15-explore-kubernetes.md](../kubernetes/notes/2026-07-15-explore-kubernetes.md), [0000-primer-kubernetes.md](../kubernetes/notes/0000-primer-kubernetes.md)
- **manifests** (1): [2026-07-15-first-pod-service.yaml](../kubernetes/manifests/2026-07-15-first-pod-service.yaml)

## linux  ·  3 files
- **notes** (2): [2026-08-06-linux-shell-scripting-tutorial-confusions.md](../linux/notes/2026-08-06-linux-shell-scripting-tutorial-confusions.md), [2026-07-21-install-linux-vm-terminal-first-commands.md](../linux/notes/2026-07-21-install-linux-vm-terminal-first-commands.md)
- **configs** (1): [2026-08-06-cron-job-configuration.ini](../linux/configs/2026-08-06-cron-job-configuration.ini)

## defectdojo  ·  3 files
- **primer:** [0000-primer-defectdojo.md](../defectdojo/notes/0000-primer-defectdojo.md)
- **notes** (2): [2026-08-04-explore-defectdojo-ui.md](../defectdojo/notes/2026-08-04-explore-defectdojo-ui.md), [0000-primer-defectdojo.md](../defectdojo/notes/0000-primer-defectdojo.md)
- **snippets** (1): [install-defectdojo-first-scan-report.sh](../defectdojo/snippets/install-defectdojo-first-scan-report.sh)

## prometheus  ·  2 files
- **primer:** [0000-primer-observability.md](../prometheus/notes/0000-primer-observability.md)
- **notes** (2): [0000-primer-observability.md](../prometheus/notes/0000-primer-observability.md), [0000-primer-prometheus.md](../prometheus/notes/0000-primer-prometheus.md)

## grafana  ·  1 files
- **primer:** [0000-primer-grafana.md](../grafana/notes/0000-primer-grafana.md)
- **notes** (1): [0000-primer-grafana.md](../grafana/notes/0000-primer-grafana.md)
