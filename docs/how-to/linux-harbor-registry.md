# Linux Container Registry with Harbor

## Purpose

Deploy a production-ready private container registry using Harbor on a Linux server. This guide covers Harbor installation with Docker Compose, HTTPS/TLS configuration, user authentication, image replication, vulnerability scanning with Trivy, and automated backup procedures.

## When to use

- Hosting private container images for internal teams without relying on Docker Hub
- Requiring vulnerability scanning of container images before deployment
- Needing RBAC and LDAP integration for multi-team registry access
- Setting up image replication between multiple registries for disaster recovery
- Compliance requirements that mandate on-premises image storage

## Prerequisites

- Linux server: Ubuntu 22.04 or CentOS Stream 9
- Minimum: 2 CPU cores, 4 GB RAM, 40 GB disk
- Recommended: 4 CPU cores, 8 GB RAM, 100+ GB disk
- Docker Engine 20.10+ and Docker Compose v2+ installed
- DNS A record for the registry hostname (e.g., `harbor.example.com`)
- TLS certificate (self-signed for testing, CA-signed for production)
- Open ports: 443 (HTTPS), 80 (HTTP redirect)

## Steps

### Step 1: Install Docker and Docker Compose

```bash
# Install Docker Engine
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable --now docker
```

### Step 2: Create TLS certificates

For production, use certificates from a trusted CA. For testing, generate self-signed certs:

```bash
HARBOR_HOSTNAME="harbor.example.com"
CERT_DIR="/opt/harbor/cert"
mkdir -p "$CERT_DIR"

# Generate CA key and cert
openssl genrsa -out "$CERT_DIR/ca.key" 4096
openssl req -x509 -new -nodes -sha512 -days 3650 \
  -subj "/C=US/ST=California/L=SanFrancisco/O=DevOps/CN=${HARBOR_HOSTNAME}" \
  -key "$CERT_DIR/ca.key" \
  -out "$CERT_DIR/ca.crt"

# Generate server key and CSR
openssl genrsa -out "$CERT_DIR/server.key" 4096
openssl req -sha512 -new \
  -subj "/C=US/ST=California/L=SanFrancisco/O=DevOps/CN=${HARBOR_HOSTNAME}" \
  -key "$CERT_DIR/server.key" \
  -out "$CERT_DIR/server.csr"

# Create x509 v3 extension file
cat > "$CERT_DIR/v3.ext" <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=${HARBOR_HOSTNAME}
DNS.2=harbor
IP.1=127.0.0.1
EOF

# Sign the server certificate
openssl x509 -req -sha512 -days 3650 \
  -extfile "$CERT_DIR/v3.ext" \
  -CA "$CERT_DIR/ca.crt" -CAkey "$CERT_DIR/ca.key" -CAcreateserial \
  -in "$CERT_DIR/server.csr" \
  -out "$CERT_DIR/server.crt"

# Convert to Docker-compatible format
openssl x509 -inform PEM -in "$CERT_DIR/server.crt" -out "$CERT_DIR/server.cert"
```

### Step 3: Download and configure Harbor

```bash
HARBOR_VERSION="v2.10.0"
HARBOR_DIR="/opt/harbor"

mkdir -p "$HARBOR_DIR"
cd "$HARBOR_DIR"

# Download Harbor installer
wget "https://github.com/goharbor/harbor/releases/download/${HARBOR_VERSION}/harbor-online-installer-${HARBOR_VERSION}.tgz"
tar xzf "harbor-online-installer-${HARBOR_VERSION}.tgz"

# Generate configuration from template
cp harbor.yml.tmpl harbor.yml
```

Edit `harbor.yml`:

```yaml
# hostname must match the TLS certificate CN and SAN
hostname: harbor.example.com

# HTTP configuration (redirect to HTTPS)
http:
  port: 80

# HTTPS configuration
https:
  port: 443
  certificate: /opt/harbor/cert/server.crt
  private_key: /opt/harbor/cert/server.key

# Harbor admin password (change immediately after first login)
harbor_admin_password: "ChangeMeOnFirstLogin!"

# Database configuration
database:
  password: "dbpassword123"
  max_idle_conns: 100
  max_open_conns: 900

# Data volume for Harbor storage
data_volume: /data

# Trivy vulnerability scanner
trivy:
  ignore_unfixed: false
  skip_update: false
  insecure: false

# Job service configuration
jobservice:
  max_job_workers: 10

# Log configuration
log:
  level: info
  local:
    rotate_count: 50
    rotate_size: 200M
    location: /var/log/harbor
```

### Step 4: Install Harbor

```bash
cd /opt/harbor

# Install with Trivy scanner and Notary (optional: add --with-notary)
sudo ./install.sh --with-trivy

# Verify all containers are running
docker compose ps
```

Expected containers: `harbor-core`, `harbor-db`, `harbor-jobservice`, `harbor-log`, `harbor-portal`, `harbor-registry`, `harbor-trivy`, `redis`, `registryctl`.

### Step 5: Configure Docker client trust

On every machine that will push/pull from this registry:

```bash
# Create Docker certs directory
sudo mkdir -p /etc/docker/certs.d/harbor.example.com

# Copy the CA certificate
sudo cp /opt/harbor/cert/ca.crt /etc/docker/certs.d/harbor.example.com/

# For systems using Docker Desktop or podman, also update the system trust store
sudo cp /opt/harbor/cert/ca.crt /usr/local/share/ca-certificates/harbor-example-ca.crt
sudo update-ca-certificates

# Restart Docker to pick up new certs
sudo systemctl restart docker
```

### Step 6: Configure LDAP authentication (optional)

Log into the Harbor web UI at `https://harbor.example.com` with admin credentials.
Navigate to **Administration -> Configuration -> Authentication**:

```yaml
Auth Mode: LDAP
LDAP URL: ldap://ldap.example.com:389
LDAP Search DN: cn=admin,dc=example,dc=com
LDAP Search Password: <ldap-admin-password>
LDAP Base DN: ou=people,dc=example,dc=com
LDAP UID: sAMAccountName (Active Directory) or uid (OpenLDAP)
LDAP Group Base DN: ou=groups,dc=example,dc=com
LDAP Group Admin DN: cn=harbor-admins,ou=groups,dc=example,dc=com
```

### Step 7: Push and pull images

```bash
# Login to Harbor
docker login harbor.example.com

# Tag a local image
docker tag myapp:latest harbor.example.com/myproject/myapp:v1.0.0

# Push to Harbor
docker push harbor.example.com/myproject/myapp:v1.0.0

# Pull from another machine
docker pull harbor.example.com/myproject/myapp:v1.0.0
```

### Step 8: Configure image replication

In the Harbor web UI, go to **Administration -> Registries -> New Endpoint**:
- Provider: Harbor
- Name: dr-registry
- Endpoint URL: `https://dr-harbor.example.com`
- Access ID: admin
- Access Secret: <password>

Then go to **Administration -> Replication -> New Rule**:
- Name: push-to-dr
- Source registry: local
- Resource filter: myproject/**
- Trigger: Event Based (on push)
- Destination registry: dr-registry
- Override: enabled

### Step 9: Configure automated garbage collection

```bash
# Schedule garbage collection via Harbor API
HARBOR_URL="https://harbor.example.com"
ADMIN_USER="admin"
ADMIN_PASS="ChangeMeOnFirstLogin!"

# Create GC schedule (runs Sunday at 2 AM)
curl -k -X POST "${HARBOR_URL}/api/v2.0/system/gc/schedule" \
  -u "${ADMIN_USER}:${ADMIN_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "parameters": {
      "delete_untagged": true,
      "dry_run": false
    },
    "schedule": {
      "type": "Custom",
      "cron": "0 2 * * 0"
    }
  }'
```

### Step 10: Set up automated backups

Use the backup script provided in this project (see `scripts/bash/harbor/harbor-backup.sh`).

## Verify

1. Check all Harbor services are healthy:

```bash
cd /opt/harbor && docker compose ps
```

All services should show `Up` status.

2. Test the registry API:

```bash
curl -k -u admin:ChangeMeOnFirstLogin! https://harbor.example.com/api/v2.0/health
```

Expected: `{"status":"healthy"}`

3. Verify vulnerability scanning:

```bash
# Push a test image and check scan results in the web UI
docker pull nginx:1.25
docker tag nginx:1.25 harbor.example.com/library/nginx:1.25
docker push harbor.example.com/library/nginx:1.25
# Check the project page in Harbor UI for scan results
```

4. Test image pull from a clean machine:

```bash
# On a remote machine with the CA cert installed
docker login harbor.example.com
docker pull harbor.example.com/library/nginx:1.25
```

## Rollback

Stop and remove Harbor (preserves data volume):

```bash
cd /opt/harbor
docker compose down
```

Complete removal including data:

```bash
cd /opt/harbor
docker compose down -v
sudo rm -rf /data /opt/harbor
```

Restore from backup (if configured):

```bash
# Stop Harbor
cd /opt/harbor && docker compose down

# Restore database
docker run --rm -v /data/database:/var/lib/postgresql/13/main \
  -v /backup/harbor-db:/backup \
  postgres:13-alpine \
  bash -c "cd /var/lib/postgresql/13/main && rm -rf * && tar xzf /backup/harbor-db-latest.tar.gz"

# Restore registry data
tar xzf /backup/harbor-registry-latest.tar.gz -C /data/

# Start Harbor
cd /opt/harbor && docker compose up -d
```

## Common errors

### Error: x509: certificate signed by unknown authority

**Symptom:** `Error response from daemon: Get "https://harbor.example.com/v2/": x509: certificate signed by unknown authority`

**Solution:** The Docker client does not trust the Harbor TLS certificate. Copy the CA cert to `/etc/docker/certs.d/harbor.example.com/ca.crt` and restart Docker. For system-wide trust, add to `/usr/local/share/ca-certificates/` and run `update-ca-certificates`.

### Error: unauthorized: authentication required

**Symptom:** `denied: unauthorized: authentication required` when pushing images

**Solution:** Run `docker login harbor.example.com` and enter valid credentials. Check that the user has Developer or higher role on the target project.

### Error: no space left on device

**Symptom:** Harbor fails to push images, logs show disk space errors

**Solution:** Check `/data` partition usage with `df -h /data`. Run garbage collection via Harbor UI (Administration -> Garbage Collection -> GC Now) to reclaim space from deleted images and tags.

### Error: database connection refused

**Symptom:** Harbor core container in restart loop, logs show `dial tcp 127.0.0.1:5432: connect: connection refused`

**Solution:** Check if the database container is running: `docker compose -f /opt/harbor/docker-compose.yml ps harbor-db`. Verify the database password in `harbor.yml` matches. Check database logs: `docker logs harbor-db`.

### Error: Trivy scanner unavailable

**Symptom:** Image scans fail with "scanner unavailable" error in Harbor UI

**Solution:** Verify the Trivy container is running: `docker ps | grep trivy`. Restart if needed: `docker compose -f /opt/harbor/docker-compose.yml restart harbor-trivy`. Check if the vulnerability database needs updating — Trivy auto-updates on startup but may fail if outbound internet is blocked.

## References

- [Harbor Installation Guide](https://goharbor.io/docs/2.10.0/install-config/)
- [Harbor HTTPS Configuration](https://goharbor.io/docs/2.10.0/install-config/configure-https/)
- [Harbor LDAP Configuration](https://goharbor.io/docs/2.10.0/administration/configuring-authentication/ldap-auth/)
- [Harbor Replication](https://goharbor.io/docs/2.10.0/administration/configuring-replication/)
- [Harbor Backup and Restore](https://goharbor.io/docs/2.10.0/administration/backup-restore/)
- [Docker Registry Client](https://docs.docker.com/reference/cli/docker/login/)
