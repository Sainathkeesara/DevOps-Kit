# Container Host Setup with Docker and Security Hardening

## Purpose

This guide provides a comprehensive walkthrough for setting up a Linux container host with Docker Engine and applying security hardening measures. The objective is to create a production-ready container runtime environment that follows industry best practices for container security.

## When to Use

- Setting up a new Linux server to run Docker containers
- Hardening an existing Docker installation for production use
- Preparing a base image for Kubernetes nodes
- Building a container host for CI/CD runners

## Prerequisites

- Linux server running Ubuntu 22.04 LTS, Debian 11+, or RHEL/CentOS 8+
- Root or sudo access
- Minimum 2 CPU cores, 4GB RAM, 20GB disk space
- Static IP address recommended for production
- Internet connectivity for package installation

## Steps

### 1. Update System Packages

```bash
sudo apt-get update && sudo apt-get upgrade -y
```

For RHEL/CentOS:
```bash
sudo yum update -y
```

### 2. Install Prerequisites

Ubuntu/Debian:
```bash
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
```

RHEL/CentOS:
```bash
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
```

### 3. Add Docker Repository

**Ubuntu/Debian:**
```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
```

**RHEL/CentOS:**
```bash
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

### 4. Install Docker Engine

```bash
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

RHEL/CentOS:
```bash
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

### 5. Configure Docker Service

```bash
sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl status docker
```

### 6. Add User to Docker Group

```bash
sudo usermod -aG docker $USER
newgrp docker
```

### 7. Security Hardening - Create Docker Configuration

Create the Docker daemon configuration file:

```bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "icc": false,
  "userns-remap": "default",
  "live-restore": true,
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  },
  "authorization-plugins": [],
  "seccomp-profile": "",
  "apparmor-profile": "generated",
  "selinux-enabled": false,
  "no-new-privileges": true,
  "dns": ["8.8.8.8", "8.8.4.4"],
  "hosts": [],
  "bridge": "none"
}
EOF
```

### 8. Enable Docker Content Trust

```bash
export DOCKER_CONTENT_TRUST=1
echo 'export DOCKER_CONTENT_TRUST=1' | sudo tee -a /etc/environment
```

### 9. Configure Resource Limits

Create a systemd drop-in for Docker:

```bash
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/10-machine.conf <<EOF
[Service]
MemoryMax=4G
CPUQuota=200%
TasksMax=infinity
EOF
```

### 10. Configure Firewall Rules

**Using UFW (Ubuntu/Debian):**
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp    # SSH
sudo ufw --force enable
```

**Using firewalld (RHEL/CentOS):**
```bash
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-interface=docker0 --zone=trusted
sudo firewall-cmd --reload
```

### 11. Enable AppArmor for Docker

```bash
sudo apt-get install -y apparmor-utils
sudo aa-status
sudo systemctl reload docker
```

### 12. Configure Audit Rules for Docker

Add Docker audit rules:

```bash
sudo tee /etc/audit/rules.d/docker.rules <<EOF
-w /var/lib/docker -k docker
-w /etc/docker -k docker
-w /usr/bin/docker -k docker
-w /var/run/docker.sock -k docker
EOF
sudo auditctl -R /etc/audit/rules.d/docker.rules
```

### 13. Create Container Network Isolation

```bash
docker network create --driver bridge \
  --opt "com.docker.network.bridge.name"=docker-br0 \
  --opt "com.docker.network.bridge.enable_icc"=false \
  --subnet=172.20.0.0/16 \
  isolated-network
```

### 14. Create Resource Limits Template

Create `/etc/docker/limit-config.json`:

```json
{
  "default-ulimits": {
    "nofile": {"Name": "nofile", "Hard": 64000, "Soft": 64000},
    "nproc": {"Name": "nproc", "Hard": 4096, "Soft": 4096}
  },
  "default-cpu-shares": 1024,
  "default-memory": "2g",
  "default-memory-swap": "4g"
}
```

### 15. Set Up Docker Security Script

Create a security hardening script:

```bash
cat > /usr/local/bin/docker-security.sh <<'SCRIPT'
#!/bin/bash
set -euo pipefail

echo "=== Docker Security Hardening Script ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Verify Docker is installed
command -v docker >/dev/null 2>&1 || { echo "Docker not installed"; exit 1; }

# Enable Docker daemon authentication
if [ ! -f /etc/docker/daemon.json ]; then
  mkdir -p /etc/docker
  echo '{"authorization-plugins": []}' > /etc/docker/daemon.json
  echo "Created daemon.json with minimal security"
fi

# Set Docker socket permissions
chmod 660 /var/run/docker.sock
chown root:docker /var/run/docker.sock

# Disable Docker API exposed on TCP (security risk)
if grep -q '"hosts":\s*\[\s*""\s*\]' /etc/docker/daemon.json 2>/dev/null; then
  echo "WARNING: Docker API exposed on TCP - remove this in production"
fi

# Enable Docker Content Trust
export DOCKER_CONTENT_TRUST=1
echo "Docker Content Trust enabled"

# Log Docker daemon settings
echo "Docker daemon configuration:"
docker info --format '{{json .ServerVersion}}'

echo "=== Security hardening complete ==="
SCRIPT

chmod +x /usr/local/bin/docker-security.sh
```

### 16. Verify Installation

```bash
docker run --rm hello-world
docker info | grep -E "Server Version|Storage Driver|Kernel Version"
```

## Verify

1. Docker service is running: `systemctl status docker`
2. Docker version: `docker --version`
3. Container can run: `docker run hello-world`
4. User in docker group: `groups $USER`
5. Firewall enabled: `sudo ufw status` or `firewall-cmd --list-all`
6. Audit rules loaded: `auditctl -l | grep docker`
7. AppArmor enabled: `aa-status | grep docker`

## Rollback

To remove Docker and start fresh:

```bash
sudo systemctl stop docker
sudo apt-get remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo rm -rf /var/lib/docker
sudo rm -rf /etc/docker
```

For RHEL/CentOS:
```bash
sudo systemctl stop docker
sudo yum remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo rm -rf /var/lib/docker
```

## Common Errors

### "Cannot connect to Docker daemon"

- Ensure Docker service is running: `sudo systemctl start docker`
- Check socket permissions: `ls -la /var/run/docker.sock`
- Verify user is in docker group: `groups $USER`

### "iptables: No chain/target/match by that name"

- Load kernel modules: `sudo modprobe ip_tables`
- Restart Docker: `sudo systemctl restart docker`

### "failed to create task for daemon: cannot set property"

- Use systemd drop-in instead of systemctl set-property

### "Error response from daemon: user namespace remapping enabled"

- Ensure `/etc/subuid` and `/etc/subgid` have entries for the user

## References

- Docker Engine installation: https://docs.docker.com/engine/install/
- Docker security best practices: https://docs.docker.com/engine/security/
- Docker daemon configuration: https://docs.docker.com/engine/reference/commandline/daemon/
- CIS Docker Benchmark: https://www.cisecurity.org/benchmark/docker
- Docker Hardening Guide: https://docs.docker.com/engine/security/security/