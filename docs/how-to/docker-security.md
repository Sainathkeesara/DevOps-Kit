# Docker Security Best Practices Guide

## Purpose

This guide provides comprehensive security hardening recommendations for Docker containerized environments. It covers essential configurations, network settings, access controls, and runtime protections that should be applied to any production Docker deployment.

## When to use

- Securing new Docker installations before deployment
- Auditing existing Docker configurations for security gaps
- Hardening Docker Desktop and Docker Engine installations
- Implementing security controls in CI/CD pipelines
- Meeting compliance requirements (CIS, PCI-DSS, SOC2)

## Prerequisites

- Docker Engine 20.10+ or Docker Desktop 4.20+
- Root or sudo access to the Docker host
- Basic understanding of Docker concepts (images, containers, networks, volumes)
- For some recommendations: Kubernetes knowledge (if using Docker with K8s)

## Steps

### 1. Image Security

#### 1.1 Use Minimal Base Images
Prefer minimal images like `alpine` or `distroless` to reduce attack surface:
```dockerfile
FROM alpine:3.18 AS builder
# Use minimal base to reduce vulnerabilities
```

#### 1.2 Scan Images for Vulnerabilities
Use Trivy or other scanners in your build pipeline:
```bash
trivy image myimage:latest --severity HIGH,CRITICAL
```

#### 1.3 Pin Specific Image Versions
Avoid using `:latest` tag; pin to specific versions:
```dockerfile
FROM node:20.10.0-alpine3.18
```

#### 1.4 Use Multi-Stage Builds
Minimize final image size and attack surface:
```dockerfile
FROM node:20.10.0-alpine3.18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:20.10.0-alpine3.18
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
```

### 2. Container Runtime Security

#### 2.1 Run Containers as Non-Root User
Always run containers with a non-root user:
```dockerfile
RUN addgroup -g 1000 appgroup && \
    adduser -u 1000 -G appgroup -D appuser
USER appuser
```

Or at runtime:
```bash
docker run --user 1000:1000 myimage
```

#### 2.2 Enable Read-Only Root Filesystem
Prevent container from writing to filesystem:
```bash
docker run --read-only myimage
```

#### 2.3 Drop All Capabilities and Add Specific Ones
Drop default capabilities and add only what's needed:
```bash
docker run --cap-drop ALL --cap-add NET_BIND_SERVICE myimage
```

#### 2.4 Set Resource Limits
Prevent DoS from runaway containers:
```bash
docker run --memory=512m --cpus=0.5 myimage
```

#### 2.5 Disable Inter-Container Communication
Isolate containers by disabling inter-container communication:
```dockerfile
# In docker-compose.yml
 networks:
   default:
     driver: bridge
     enable_ip_masquerade: false
```

### 3. Network Security

#### 3.1 Use Custom Networks
Create dedicated networks for application tiers:
```bash
docker network create --driver bridge frontend_net
docker network create --driver bridge backend_net
```

#### 3.2 Don't Expose Unnecessary Ports
Only expose ports that are absolutely necessary:
```bash
# Instead of -p 80:80 -p 443:443 -p 22:22
docker run -p 8080:8080 myimage
```

#### 3.3 Use TLS for Registry Communication
Configure Docker to use HTTPS for all registry operations:
```json
{
  "registry-mirrors": [],
  "insecure-registries": [],
  "debug": false,
  "experimental": false,
  "features": {"buildkit": true}
}
```

#### 3.4 Implement Network Segmentation
Use Docker's built-in network drivers for isolation:
```yaml
networks:
  dmz:
    driver: bridge
  internal:
    driver: bridge
    internal: true
```

### 4. Secrets Management

#### 4.1 Never Bake Secrets into Images
Use environment variables or secret mounts instead:
```bash
# Don't do this - secrets visible in image
ENV API_KEY=secret123

# Instead, use runtime injection
docker run --env-file .env.prod myimage
```

#### 4.2 Use Docker Secrets in Swarm Mode
For Docker Swarm deployments:
```bash
echo "mypassword" | docker secret create db_password -
docker secret ls
```

#### 4.3 Use External Secrets Management
Integrate with Vault, AWS Secrets Manager, or similar:
```bash
docker run -v /vault/secrets:/vault/secrets:ro myimage
```

### 5. Host Security

#### 5.1 Enable Docker Daemon Authorization
Enable authorization plugin:
```json
{
  "authorization-plugins": ["docker-runtime-argus"],
  "log-driver": "journald",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

#### 5.2 Enable Content Trust
Verify image integrity before pulling:
```bash
export DOCKER_CONTENT_TRUST=1
```

#### 5.3 Secure Docker Socket
Never expose Docker socket to containers:
```bash
# Bad - container can control host
docker run -v /var/run/docker.sock:/var/run/docker.sock

# Use Docker-in-Docker alternatives instead
```

#### 5.4 Keep Docker Updated
Regularly update Docker to patch security vulnerabilities:
```bash
apt-get update && apt-get upgrade docker-ce docker-ce-cli containerd.io
```

#### 5.5 Enable AppArmor/SELinux
Enable mandatory access control:
```bash
# For AppArmor
docker run --security-opt "apparmor:docker-default" myimage

# For SELinux
docker run --security-opt label:level:s0:c100,c200 myimage
```

### 6. Logging and Monitoring

#### 6.1 Enable Audit Logging
Configure Docker daemon audit rules:
```bash
# Add to /etc/audit/rules.d/docker.rules
-w /var/lib/docker -k docker
-w /etc/docker -k docker
-w /usr/bin/docker -k docker
-w /var/run/docker.sock -k docker
```

#### 6.2 Centralize Logs
Send container logs to centralized logging:
```bash
docker run --log-driver=syslog --log-opt syslog-address=tcp://logger:514 myimage
```

### 7. Image Build Security

#### 2.1 Use .dockerignore
Exclude sensitive files from build context:
```
.git
*.md
.env
*.pem
id_rsa
```

#### 7.2 Add Health Checks
Enable container health checks:
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/health || exit 1
```

## Verify

1. Run security scanning on images:
   ```bash
   docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
     aquasecurity/trivy image myimage:latest
   ```

2. Check for running containers as root:
   ```bash
   docker ps --format "{{.ID}} {{.Names}} {{.User}}" | grep -v "^1000"
   ```

3. Verify capabilities dropped:
   ```bash
   docker inspect mycontainer --format '{{.HostConfig.CapDrop}}'
   ```

4. Test resource limits:
   ```bash
   docker run --memory=256m --memory-swap=256m \
     stress --vm 1 --vm-bytes 300M --timeout 5s || echo "Memory limit working"
   ```

5. Verify user namespace mapping:
   ```bash
   docker run --user 1000:1000 id
   ```

## Rollback

### Revert to Previous Configuration

1. Restore daemon.json:
   ```bash
   sudo cp /etc/docker/daemon.json.bak /etc/docker/daemon.json
   sudo systemctl restart docker
   ```

2. Remove security enhancements from Dockerfile:
   ```bash
   # Remove USER directive
   # Remove --read-only flag
   # Restore original base image
   ```

3. Rebuild images without security changes:
   ```bash
   docker build -t myimage:rollback .
   ```

4. Redeploy with previous configuration:
   ```bash
   docker-compose -f docker-compose.rollback.yml up -d
   ```

## Common Errors

### Error: "permission denied while trying to connect to Docker daemon"
**Cause:** User not in docker group
**Fix:** Add user to docker group and re-login
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Error: "container create failed: capabilities not allowed"
**Cause:** Attempting to add capabilities not allowed by security profile
**Fix:** Remove the capability or adjust AppArmor/SELinux profile
```bash
# Instead of NET_ADMIN which requires privileged mode
docker run --cap-add=NET_ADMIN myimage  # May fail
```

### Error: "exec format error" when running binary
**Cause:** Architecture mismatch between image and host
**Fix:** Use multi-arch images or build for correct architecture
```dockerfile
FROM --platform=linux/amd64 node:20-alpine
```

### Error: "OCI runtime create failed"
**Cause:** Resource limits syntax error or conflicts
**Fix:** Verify correct syntax and resource availability
```bash
# Correct syntax
docker run --memory=512m --cpus=0.5 myimage
```

### Error: "network driver not supported"
**Cause:** Network plugin not installed
**Fix:** Install required network plugin or use default bridge
```bash
docker plugin install store/weaveworks/net-plugin:2.8
```

## References

- Docker Security Documentation: https://docs.docker.com/engine/security/
- CIS Docker Benchmark: https://www.cisecurity.org/benchmark/docker
- Docker Content Trust: https://docs.docker.com/engine/security/trust/
- NIST Container Security Guide: https://nvd.nist.gov/800-53 Rev 5
- CVE-2026-2664: Docker Desktop grpcfuse kernel module privilege escalation
- Trivy Vulnerability Scanner: https://aquasecurity.github.io/trivy/
- Docker Bench Security: https://github.com/docker/docker-bench-security