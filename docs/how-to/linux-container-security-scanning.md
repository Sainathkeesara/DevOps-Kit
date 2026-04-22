# Container Security Scanning with Trivy and Falco

## Purpose

This project provides comprehensive guidance on setting up and using container security scanning tools Trivy and Falco for container runtime security monitoring. Trivy scans container images for vulnerabilities while Falco provides runtime security monitoring.

## When to Use

- When you need to scan container images for known vulnerabilities before deployment
- When you want runtime security monitoring for containerized applications
- When building CI/CD pipelines that require security gates
- When responding to security incidents in container environments
- When auditing container image supply chains

## Prerequisites

- Linux server (Ubuntu 20.04+, RHEL 8+, Debian 11+)
- Docker or container runtime installed
- Root or sudo access
- Basic understanding of container security concepts
- At least 2GB available disk space for vulnerability database

## Steps

### Step 1: Install Trivy

Install Trivy vulnerability scanner:

```bash
# Download Trivy binary
wget https://github.com/aquasecurity/trivy/releases/download/v0.57.0/trivy_0.57.0_linux_amd64.tar.gz

# Extract the tarball
tar -xzf trivy_0.57.0_linux_amd64.tar.gz

# Install Trivy
sudo mv trivy /usr/local/bin/
sudo chown root:root /usr/local/bin/trivy
sudo chmod 755 /usr/local/bin/trivy

# Verify installation
trivy --version
```

### Step 2: Install Falco

Install Falco runtime security monitoring:

```bash
# Add Falco repository
curl -s https://falco.org/repo/falcosecurity-x86_64.pub | sudo apt-key add -
echo "deb https://falco.org/deb stable main" | sudo tee /etc/apt/sources.list.d/falcosecurity.list

# Update and install
sudo apt-get update
sudo apt-get install -y falco

# Enable Falco service
sudo systemctl enable falco
sudo systemctl start falco

# Verify installation
falco --version
```

### Step 3: Configure Trivy Scanning

Create Trivy configuration:

```bash
# Create config directory
mkdir -p ~/.config/trivy

# Create config file
cat > ~/.config/trivy/trivy.yaml << 'EOF'
format: table
severity: UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL
exit-code: 0
skip-dirs:
  - ^/tmp
  - ^/var
timeout: 10m

vulnerability:
  type: os
 db-repository: ghcr.io/aquasecurity/trivy-db:2

security:
  type:misconfig,secret
EOF

# Test configuration
trivy config
```

### Step 4: Scan Container Images

Scan images for vulnerabilities:

```bash
# Scan a local image
trivy image --severity CRITICAL,HIGH myapp:latest

# Scan and output JSON
trivy image --format json myapp:latest > scan-results.json

# Scan with security checks
trivy image --security-checks vuln,config myapp:latest

# Scan image from private registry
trivy image --registry-auth myregistry.com:5000/myapp:latest
```

### Step 5: Configure Falco Rules

Create custom Falco rules:

```bash
# Create rules directory
sudo mkdir -p /etc/falco/custom-rules

# Create custom rule file
sudo cat > /etc/falco/custom-rules/my-security-rules.yaml << 'EOF'
- rule: Container privileged mode
  desc: Detect containers running in privileged mode
  condition: >
    container.privileged = true
  output: >
    Privileged container detected (command=%proc.cmdline container_id=%container.id image=%container.image.repository)
  priority: WARNING
  tags: [container, security]

- rule: Sensitive file access in container
  desc: Detect sensitive files being accessed
  condition: >
    evt.type = openat and (fd.name in (/etc/shadow, /etc/passwd, /etc/sudoers))
  output: >
    Sensitive file accessed (file=%fd.name container_id=%container.id image=%container.image.repository)
  priority: WARNING
  tags: [container, security, filesystem]
EOF

# Reload Falco with custom rules
sudo falco --reload
```

### Step 6: Create Security Scanning Script

Create automated scanning script:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="container-security-scan.sh"
SCRIPT_VERSION="1.0.0"
LOG_FILE="/var/log/container-security.log"
REPORT_DIR="${REPORT_DIR:-/tmp/security-reports}"
DRY_RUN="${DRY_RUN:-false}"
TRIVY_DB_DIR="${TRIVY_DB_DIR:-$HOME/.cache/trivy}"

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2 | tee -a "$LOG_FILE"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_dependencies() {
    log_info "Checking dependencies..."
    local missing=()
    for cmd in trivy falco docker; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        exit 1
    fi
    log_info "All dependencies found"
}

update_trivy_db() {
    log_info "Updating Trivy database..."
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would update Trivy database"
    else
        trivy db update || log_error "Failed to update database"
    fi
}

scan_images() {
    local image="${1:-alpine:latest}"
    log_info "Scanning image: $image"
    
    mkdir -p "$REPORT_DIR"
    local report_file="$REPORT_DIR/trivy-scan-$(date +%Y%m%d-%H%M%S).json"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would scan $image"
    else
        trivy image --format json --severity CRITICAL,HIGH "$image" > "$report_file" 2>&1 || true
        local vuln_count=$(jq -r '.Vulnerabilities | length' "$report_file" 2>/dev/null || echo "0")
        log_info "Found $vuln_count vulnerabilities in $image"
    fi
}

check_container_activity() {
    log_info "Checking container runtime activity..."
    
    if ! command_exists docker; then
        log_error "Docker not installed"
        return
    fi
    
    local running_containers
    running_containers=$(docker ps --format '{{.Names}}' 2>/dev/null || echo "")
    
    if [[ -z "$running_containers" ]]; then
        log_info "No running containers"
        return
    fi
    
    log_info "Running containers: $running_containers"
}

main() {
    log_info "=== Container Security Scan v$SCRIPT_VERSION ==="
    check_dependencies
    
    update_trivy_db
    
    local images=("alpine:latest" "nginx:latest" "redis:latest")
    for img in "${images[@]}"; do
        scan_images "$img"
    done
    
    check_container_activity
    
    log_info "Scan complete. Reports saved to $REPORT_DIR"
}

main "$@"
```

Make it executable:

```bash
chmod +x container-security-scan.sh
```

### Step 7: Create Falco Integration

Create Falco alerting script:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="falco-alerts.sh"
SCRIPT_VERSION="1.0.0"
ALERT_LOG="/var/log/falco-alerts.log"
DRY_RUN="${DRY_RUN:-false}"

log_alert() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: $1" | tee -a "$ALERT_LOG"
}

check_falco_running() {
    if systemctl is-active --quiet falco; then
        log_alert "Falco is running"
        return 0
    else
        log_alert "Falco is NOT running"
        return 1
    fi
}

get_recent_alerts() {
    local count="${1:-10}"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY-RUN] Would get $count recent Falco alerts"
        return
    fi
    
    if journalctl -u falco -n "$count" --no-pager 2>/dev/null | grep -q "falco"; then
        journalctl -u falco -n "$count" --no-pager | grep "falco" | tail -n "$count"
    else
        echo "No recent Falco alerts"
    fi
}

main() {
    log_alert "=== Falco Alert Checker v$SCRIPT_VERSION ==="
    
    if check_falco_running; then
        get_recent_alerts 10
    fi
    
    log_alert "Check complete"
}

main "$@"
```

### Step 8: Create CI/CD Integration

Create a GitHub Actions workflow for container security:

```yaml
name: Container Security Scan

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  trivy-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Trivy scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'table'
          severity: 'CRITICAL,HIGH'
          exit-code: '1'
          
      - name: Upload results
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: trivy-results
          path: trivy-report.json
```

## Verify

### Verify Trivy Installation

```bash
trivy --version
# Should output: trivy version 0.57.0

trivy image nginx:latest
# Should scan and output vulnerabilities
```

### Verify Falco Installation

```bash
falco --version
# Should output: Falco version 0.38.x

systemctl status falco
# Should show: active (running)
```

### Test Scanning Script

```bash
./container-security-scan.sh
# Should complete without errors
```

### Check Falco Logs

```bash
sudo journalctl -u falco -f
# Should show real-time events
```

## Rollback

Remove Trivy:

```bash
sudo rm /usr/local/bin/trivy
sudo rm -rf ~/.cache/trivy
```

Remove Falco:

```bash
sudo systemctl stop falco
sudo systemctl disable falco
sudo apt-get remove --purge falco
sudo rm -rf /etc/falco
```

Remove custom scripts:

```bash
sudo rm -f /usr/local/bin/container-security-scan.sh
sudo rm -f /usr/local/bin/falco-alerts.sh
sudo rm -f /var/log/container-security.log
sudo rm -f /var/log/falco-alerts.log
```

## Common Errors

| Error | Solution |
|-------|----------|
| `trivy: command not found` | Add Trivy to PATH or use full path: `/usr/local/bin/trivy` |
| `database not found` | Run `trivy db update` to download vulnerability database |
| `permission denied` | Run with sudo for privileged container scanning |
| `Falco kernel module not loaded` | Run `sudo falco --install` to load kernel module |
| `no containers detected` | Ensure Docker is running and containers exist: `docker ps` |
| `database download timeout` | Increase timeout in config or use mirror |

## References

- [Trivy Official Documentation](https://aquasecurity.github.io/trivy/)
- [Trivy GitHub Repository](https://github.com/aquasecurity/trivy)
- [Falco Official Documentation](https://falco.org/docs/)
- [Falco GitHub Repository](https://github.com/falcosecurity/falco)
- [Container Security Best Practices](https://docs.docker.com/engine/security/)