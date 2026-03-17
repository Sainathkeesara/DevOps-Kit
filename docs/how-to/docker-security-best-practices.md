# Docker Security Best Practices Guide

## Purpose

This guide provides comprehensive security hardening for Docker container deployments. It covers image security, runtime protection, network isolation, and operational security controls for production Docker environments.

## When to use

- Securing new Docker deployments
- Hardening existing Docker installations
- Preparing for security audits
- Implementing container security best practices
- Meeting compliance requirements (PCI-DSS, SOC 2, HIPAA)

## Prerequisites

- Docker Engine 20.10+ or Docker Desktop 4.20+
- Root or sudo access on Docker hosts
- Basic understanding of container concepts
- Access to Docker configuration files

## Steps

### 1. Image Security

#### Use Official Minimal Base Images

Prefer official images from Docker Hub or verified vendors:

```bash
# Pull official minimal image
docker pull alpine:latest

# Use specific version tags, never :latest in production
docker pull nginx:1.25-alpine
```

#### Scan Images for Vulnerabilities

```bash
# Scan with Trivy
docker build -t myapp:latest .
trivy image myapp:latest

# Scan in CI/CD
trivy image --exit-code 1 --severity HIGH,CRITICAL myapp:latest
```

#### Use Multi-Stage Builds

Reduce attack surface with multi-stage builds:

```dockerfile
# Build stage
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o myapp

# Runtime stage
FROM alpine:3.18
RUN apk --no-cache add ca-certificates
COPY --from=builder /app/myapp /usr/local/bin/
CMD ["myapp"]
```

#### Sign and Verify Images

```bash
# Enable Docker Content Trust
export DOCKER_CONTENT_TRUST=1

# Sign an image
docker trust sign myrepo/myimage:tag

# Verify image signatures
docker trust inspect myrepo/myimage:tag
```

### 2. Container Runtime Security

#### Run Containers as Non-Root User

```dockerfile
# Create user in Dockerfile
RUN addgroup -g 1001 appgroup && \
    adduser -u 1001 -G appgroup -s /bin/sh -D appuser

USER appuser
```

#### Use Read-Only Root Filesystem

```bash
docker run --read-only myapp:latest
```

#### Limit Container Capabilities

Drop unnecessary Linux capabilities:

```bash
# Drop all capabilities, add only required ones
docker run \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  myapp:latest
```

#### Enable AppArmor/SELinux Profiles

```bash
# Run with default AppArmor profile
docker run --security-opt apparmor=docker-default myapp:latest

# Custom SELinux policy
docker run --security-opt label:type:container_runtime_t myapp:latest
```

### 3. Resource Security Limits

#### Set Memory and CPU Limits

```bash
docker run \
  --memory=512m \
  --memory-swap=1g \
  --cpus=1.5 \
  myapp:latest
```

#### Prevent Container Escape

```bash
# Disable privileged mode
docker run --privileged myapp:latest  # NEVER in production

# Proper: block device access
docker run --device-read-only /dev/sda myapp:latest
```

### 4. Network Security

#### Network Isolation

```bash
# Create custom network
docker network create --driver bridge myapp-network

# Run containers in isolated network
docker run --network=myapp-network myapp:latest
```

#### Restrict Container-to-Container Communication

```dockerfile
# docker-compose.yml
services:
  app:
    networks:
      - frontend
      - backend
  
  database:
    networks:
      - backend

networks:
  frontend:
  backend:
```

#### Use TLS for Container Communication

```bash
# Generate certificates
openssl req -new -x509 -days 365 -nodes \
  -out server.crt -keyout server.key

# Use TLS with Docker
docker run -v $(pwd)/certs:/certs \
  -e TLS_CERT=/certs/server.crt \
  -e TLS_KEY=/certs/server.key \
  myapp:latest
```

### 5. Secrets Management

#### Use Docker Secrets

```bash
# Create secret
echo "mypassword" | docker secret create db_password -

# Use in service
docker service create \
  --secret db_password \
  --env MYSQL_PASSWORD_FILE=/run/secrets/db_password \
  mysql:latest
```

#### Integrate with External Secrets

```bash
# HashiCorp Vault integration
docker run -e VAULT_ADDR=https://vault.example.com:8200 \
  -e VAULT_TOKEN=${VAULT_TOKEN} \
  myapp:latest
```

### 6. Docker Daemon Security

#### Configure daemon.json

```json
{
  "icc": false,
  "ip-masq": true,
  "iptables": true,
  "userland-proxy": false,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true,
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  }
}
```

#### Enable Docker Authorization Plugin

```bash
# Example: Use Docker's built-in authorization
dockerd --authorization-plugin=docker-ermission
```

### 7. Host Security

#### Dedicated Host

Run containers on dedicated hosts without other workloads:

```bash
# Label nodes for dedicated workloads
docker node update --label-add dedicated=true node1
```

####定期更新 Docker

```bash
# Check for updates
docker version

# Update Docker (Ubuntu/Debian)
sudo apt-get update
sudo apt-get upgrade docker-ce
```

### 8. Image Build Security

#### .dockerignore

```
# Exclude secrets
*.pem
*.key
.env
*.log

# Exclude unnecessary files
.git
.gitignore
node_modules
__pycache__
*.md
```

#### Scan During Build

```dockerfile
# Dockerfile
FROM alpine:3.18 AS security-scan
RUN apk add --no-cache trivy
COPY --from=builder /app /app
RUN trivy image --severity HIGH,CRITICAL /app || exit 1

FROM alpine:3.18
COPY --from=security-scan /app /app
CMD ["myapp"]
```

## Verify

### Security Checklist

Run this verification script:

```bash
#!/bin/bash
echo "=== Docker Security Verification ==="

# Check for privileged containers
echo -n "Privileged containers: "
docker ps --filter "privileged=true" --format "{{.Names}}" | wc -l

# Check for containers running as root
echo -n "Containers running as root: "
docker ps -q | xargs -I {} docker inspect {} --format '{{.Name}}: {{.Config.User}}' | grep -v "1001\|1000" | wc -l

# Check for exposed sensitive ports
echo -n "Sensitive ports exposed: "
docker ps --format "{{.Ports}}" | grep -E "22|23|3389" | wc -l

# Check network isolation
echo -n "Containers in default bridge: "
docker network inspect bridge --format '{{len .Containers}}'

# Check for root filesystem read-only
echo -n "Read-only rootfs: "
docker ps --format "{{.Names}}" | while read c; do
  docker inspect $c --format '{{.HostConfig.ReadonlyRootfs}}'
done | grep -c "false"
```

### Test Image Scanning

```bash
# Run Trivy scan
trivy image --severity CRITICAL myapp:latest

# Should output: Detected 0 critical vulnerabilities
```

## Rollback

### Revert to Previous Image

```bash
# If security issue found in new image
docker pull myapp:previous-known-good
docker tag myapp:previous-known-good myapp:latest
docker push myapp:latest
```

### Restore Daemon Configuration

```bash
# Restore from backup
sudo cp /etc/docker/daemon.json.backup /etc/docker/daemon.json
sudo systemctl restart docker
```

### Remove Security Changes

```bash
# Remove network isolation
docker network rm myapp-network

# Remove secrets
docker secret rm db_password
```

## Common Errors

### Error: "Container uses UID 0 (root)"

**Cause**: Container runs as root user.

**Resolution**:
```dockerfile
# Add to Dockerfile
RUN adduser -D -u 1001 appuser
USER appuser
```

### Error: "Too many open files"

**Cause**: File descriptor limit exceeded.

**Resolution**:
```bash
# Add ulimits to docker run
docker run --ulimit nofile=64000:64000 myapp:latest

# Or in daemon.json
"default-ulimits": {
  "nofile": {
    "Hard": 64000,
    "Soft": 64000
  }
}
```

### Error: "Permission denied" when accessing volume

**Cause**: SELinux or AppArmor blocking access.

**Resolution**:
```bash
# For SELinux
docker run -v /data:/data:Z myapp:latest

# For AppArmor
docker run --security-opt apparmor=unconfined myapp:latest
```

### Error: "Network bridge not found"

**Cause**: Custom network not created.

**Resolution**:
```bash
docker network create myapp-network
docker run --network=myapp-network myapp:latest
```

### Error: "TLS certificate expired"

**Cause**: Expired TLS certificates.

**Resolution**:
```bash
# Regenerate certificates
openssl req -new -x509 -days 90 -nodes \
  -out new-server.crt -keyout new-server.key

# Restart container
docker restart myapp
```

## References

- Docker Security Documentation — https://docs.docker.com/engine/security/ (verified: 2026-03-17)
- CIS Docker Benchmark — https://www.cisecurity.org/benchmark/docker (verified: 2026-03-17)
- Docker Content Trust — https://docs.docker.com/engine/security/trust/ (verified: 2026-03-17)
- Docker Secrets — https://docs.docker.com/engine/swarm/secrets/ (verified: 2026-03-17)
- Falco Container Security — https://falco.org/docs/ (verified: 2026-03-17)
- Trivy Documentation — https://aquasecurity.github.io/trivy/ (verified: 2026-03-17)
