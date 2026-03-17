# Helm Chart Security Scanning Guide

## Purpose

This guide provides comprehensive procedures for scanning Helm charts for security vulnerabilities, misconfigurations, and best practices violations. It covers static analysis, runtime security, CI/CD integration, and remediation workflows for Helm-based Kubernetes deployments.

## When to use

- Scanning Helm charts before deployment to production
- Integrating security scanning into CI/CD pipelines
- Auditing third-party Helm charts from public repositories
- Meeting security compliance requirements (PCI-DSS, SOC 2, HIPAA)
- hardening Helm releases in existing Kubernetes clusters

## Prerequisites

- Kubernetes cluster 1.21+ with Helm 3.10+
- Trivy or similar vulnerability scanner installed
- kube-score or helm-unittest for configuration analysis
- Access to Helm chart repositories (public or private)
- Permissions to install CRDs and operators if using in-cluster scanning

## Steps

### 1. Install Security Scanning Tools

#### Install Trivy

```bash
# Install Trivy
curl -sfL https://aquasecurity.github.io/trivy/install.sh | sh

# Verify installation
trivy version

# Initialize Trivy database
trivy db download
```

#### Install kube-score

```bash
# Install kube-score via brew
brew install kube-score

# Or download binary
curl -Lo kube-score https://github.com/zegl/kube-score/releases/download/v1.16.1/kube-score_1.16.1_linux_amd64.tar.gz
tar -xzf kube-score_1.16.1_linux_amd64.tar.gz
mv kube-score /usr/local/bin/
```

#### Install Helm Scanner (Checkov)

```bash
# Install Checkov
pip install checkov

# Verify
checkov --version
```

### 2. Scan Helm Chart for Vulnerabilities

#### Scan Chart Archives

```bash
# Package Helm chart
helm package ./mychart

# Scan with Trivy
trivy chart mychart-1.0.0.tgz

# Scan with severity filter
trivy chart --severity HIGH,CRITICAL mychart-1.0.0.tgz

# Exit code for CI/CD integration
trivy chart --exit-code 1 --severity CRITICAL mychart-1.0.0.tgz
```

#### Scan Deployed Releases

```bash
# Get manifest from deployed release
helm get manifest my-release --namespace myns > manifest.yaml

# Scan the manifest
trivy k8s manifest manifest.yaml

# Scan all deployed resources in namespace
trivy k8s cluster --namespace myns
```

### 3. Analyze Helm Chart Configuration

#### Run kube-score

```bash
# Render template and score
helm template mychart ./mychart | kube-score score -

# With specific Kubernetes version
helm template mychart ./mychart | kube-score score -o ci -

# Score specific file
kube-score score deployment.yaml service.yaml
```

#### Checkov Helm Scanning

```bash
# Scan Helm chart directory
checkov -d ./mychart --framework helm

# Scan rendered template
helm template mychart ./mychart | checkov -f -

# Skip baseline
checkov -d ./mychart --skip-check CKV_K8S_1
```

### 4. Scan Helm Dependencies

#### Scan Chart Dependencies

```bash
# Update dependencies
helm dependency update ./mychart

# List dependencies
helm dependency list ./mychart

# Scan each dependency
for chart in $(helm dependency list ./mychart | tail -n +2 | awk '{print $1}'); do
    echo "Scanning $chart"
    trivy chart $(find . -name "$chart-*.tgz" | head -1)
done
```

### 5. Security Scanning in CI/CD

#### GitHub Actions Example

```yaml
name: Helm Security Scan

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Trivy
        run: |
          curl -sfL https://aquasecurity.github.io/trivy/install.sh | sh
          
      - name: Install Helm
        run: |
          curl -fsSL https://get.helm.sh/helm-v3.14.0-linux-amd64.tar.gz | tar -xz
          sudo mv linux-amd64/helm /usr/local/bin/helm
          
      - name: Update dependencies
        run: helm dependency update ./charts/myapp
        
      - name: Run Trivy scan
        run: |
          trivy chart --exit-code 1 --severity HIGH,CRITICAL ./charts/myapp
          
      - name: Run kube-score
        run: |
          helm template ./charts/myapp | kube-score score -
```

#### GitLab CI Example

```yaml
stages:
  - security

helm-scan:
  image: alpine/helm:latest
  before_script:
    - apk add --no-cache curl trivy
  script:
    - helm template myapp ./chart | trivy fs -
    - trivy chart --severity CRITICAL ./chart
```

### 6. Runtime Security Scanning

#### Install Kubescape

```bash
# Install Kubescape
curl -s https://raw.githubusercontent.com/kubescape/kubescape/master/install.sh | /bin/bash

# Scan Helm chart against frameworks
kubescape scan helm ./mychart --framework NSA-CISA

# Scan deployed release
kubescape scan helm release my-release -n myns
```

#### Falco Integration

```bash
# Install Falco
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco

# Create Helm Chart Security Rule
cat > security-rule.yaml <<EOF
- rule: Helm Chart Security Violation
  desc: Detect deployment of Helm chart with security issues
  condition: container.image.repository != "" and cauth
  output: "Helm security violation detected"
  priority: WARNING
EOF
```

### 7. Verify Chart Integrity

#### Check Chart Signing

```bash
# Enable signature verification
export HELM_SIGNING_KEY="your-key-id"

# Sign chart
helm package --sign --key $HELM_SIGNING_KEY --keyring ~/.gnupg/secring.gpg ./mychart

# Verify signature
helm verify mychart-1.0.0.tgz

# Install with verification
helm install --verify myrelease ./mychart
```

### 8. Generate Security Report

```bash
# Generate HTML report
trivy chart --format template --template "@/contrib/html.tpl" -o report.html ./mychart

# Generate JSON report for automation
trivy chart --format json ./mychart > results.json

# Generate SARIF report for GitHub
trivy chart --format sarif ./mychart > results.sarif
```

## Verify

### Security Scan Verification Checklist

```bash
#!/bin/bash
set -euo pipefail

CHART_PATH="${1:-./mychart}"
EXIT_CODE=0

echo "=== Helm Chart Security Scan ==="

# Check for critical vulnerabilities
echo -n "Critical vulnerabilities: "
CRITICAL=$(trivy chart --severity CRITICAL --quiet "$CHART_PATH" 2>&1 || echo "0")
echo "$CRITICAL"
if [ "$CRITICAL" -gt 0 ]; then
    EXIT_CODE=1
fi

# Check configuration score
echo -n "Configuration issues: "
CONFIG_ISSUES=$(helm template "$CHART_PATH" | kube-score score - | grep -c "Score:" || echo "0")
echo "$CONFIG_ISSUES (lower is better)"

# Check for secrets in values
echo -n "Potential secrets in values: "
SECRETS=$(grep -rE "(password|token|key|secret)" "$CHART_PATH/values.yaml" 2>/dev/null | grep -v "example\|#\|placeholder" | wc -l || echo "0")
echo "$SECRETS"

# Check for latest base images
echo -n "Outdated base images: "
OUTDATED=$(grep -rE "^from:" "$CHART_PATH/templates/" | grep -v ":latest" | wc -l || echo "0")
echo "$OUTDATED"

echo "=== Scan Complete ==="
exit $EXIT_CODE
```

### Test Scanning Pipeline

```bash
# Test on sample vulnerable chart
git clone https://github.com/bitnami/containers
cd containers
trivy chart --severity HIGH,CRITICAL ./bitnami/nginx

# Verify exit code behavior
trivy chart --exit-code 1 --severity CRITICAL ./bitnami/nginx && echo "FAIL: Should have failed" || echo "PASS: Correctly failed on critical"
```

## Rollback

### Revert Chart Version

```bash
# List release history
helm history my-release

# Rollback to previous version
helm rollback my-release 1

# Rollback to specific version
helm rollback my-release 3

# Verify rollback
helm list --all
helm get manifest my-release
```

### Remove Scanning Tools

```bash
# Remove Trivy
rm -rf /usr/local/bin/trivy
rm -rf $HOME/.trivy

# Remove kube-score
rm -f /usr/local/bin/kube-score

# Remove Checkov
pip uninstall checkov -y

# Remove Kubescape
rm -rf ~/.kubescape
kubescape reset
```

### Restore Previous Security Policy

```bash
# Restore baseline
trivy baseline reset

# Use previous baseline file
trivy baseline --format json --output previous-baseline.json

# Apply previous baseline
trivy image --baseline-results previous-baseline.json myimage:latest
```

## Common Errors

### Error: "chart: malformed RFC 5017 YAML"

**Cause**: Chart contains non-standard YAML that fails parsing.

**Resolution**:
```bash
# Validate chart syntax
helm lint ./mychart

# Check YAML syntax
yamllint ./mychart/values.yaml

# Use Helm template debug
helm template --debug ./mychart
```

### Error: "trivy: command not found"

**Cause**: Trivy not installed or not in PATH.

**Resolution**:
```bash
# Reinstall Trivy
curl -sfL https://aquasecurity.github.io/trivy/install.sh | sh

# Add to PATH
export PATH=$PATH:/usr/local/bin/trivy

# Verify
which trivy
```

### Error: "Kube-score: error: no input"

**Cause**: No Kubernetes manifests to score.

**Resolution**:
```bash
# Render chart first
helm template myrelease ./mychart > manifest.yaml

# Then score
kube-score score manifest.yaml

# Or pipe directly
helm template myrelease ./mychart | kube-score score -
```

### Error: "CVE scan results are outdated"

**Cause**: Trivy database not updated.

**Resolution**:
```bash
# Update vulnerability database
trivy db update

# Or in CI/CD
trivy image --download-db-only myimage:latest
```

### Error: "Permission denied" during scan

**Cause**: Insufficient permissions to read chart files.

**Resolution**:
```bash
# Check file permissions
ls -la ./mychart

# Fix permissions
chmod -R 755 ./mychart

# Run as appropriate user
sudo -u scanning-user trivy chart ./mychart
```

## References

- Trivy Helm Chart Scanning — https://aquasecurity.github.io/trivy/latest/docs/coverage/arch/helm/ (verified: 2026-03-17)
- Kube-score Documentation — https://github.com/zegl/kube-score (verified: 2026-03-17)
- Checkov Helm Support — https://www.checkov.io/4.Headless%20and%20Supported%20Scanners/Base%20Helm%20Scanner.html (verified: 2026-03-17)
- Kubescape Helm Scanning — https://github.com/kubescape/kubescape (verified: 2026-03-17)
- Helm Security Best Practices — https://helm.sh/docs/topics/security/ (verified: 2026-03-17)
- CIS Kubernetes Benchmark — https://www.cisecurity.org/benchmark/kubernetes (verified: 2026-03-17)
