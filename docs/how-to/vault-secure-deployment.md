# Vault Secure Deployment Best Practices

## Purpose

This guide provides comprehensive security hardening recommendations for HashiCorp Vault production deployments. It covers authentication, authorization, storage, networking, and operational security controls to protect sensitive secrets.

## When to use

- Deploying Vault in production for the first time
- Hardening an existing Vault deployment
- Conducting security audits of Vault infrastructure
- Preparing for compliance certifications (SOC2, PCI-DSS, HIPAA)

## Prerequisites

- HashiCorp Vault installed (v1.12+ recommended)
- Infrastructure for storage backend (Consul, etcd, or cloud-native)
- TLS certificates for Vault API communication
- Access to configure system-level security (firewalls, audit logging)

## Steps

### 1. Storage Backend Security

Vault requires a high-availability storage backend for persistence. The storage backend itself must be secured.

#### Use Encrypted Storage

```hcl
# storage "consul" {
#   address = "consul.example.com:8500"
#   path    = "vault/"
#   token   = "${ consul_token }"
#   scheme  = "https"
#   tls_ca_file = "/etc/vault/tls/ca.crt"
#   tls_cert_file = "/etc/vault/tls/consul-client.crt"
#   tls_key_file = "/etc/vault/tls/consul-client.key"
# }
```

#### Recommended Storage Backends

| Backend | Use Case | Encryption |
|---------|----------|------------|
| Consul | Production HA | TLS in transit + Consul encryption |
| etcd | Kubernetes | TLS + etcd encryption at rest |
| AWS DynamoDB | AWS cloud | AWS KMS encryption |
| Azure Blob | Azure cloud | Azure Storage encryption |
| GCS | GCP cloud | Google-managed encryption |

### 2. TLS Configuration

All Vault communication must use TLS.

#### Generate TLS Certificates

```bash
# Generate CA
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 -out ca.crt

# Generate Vault server certificate
openssl genrsa -out vault.key 4096
openssl req -new -key vault.key -out vault.csr
openssl x509 -req -in vault.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out vault.crt -days 365 -sha256
```

#### Configure TLS in Vault config

```hcl
# /etc/vault.d/vault.hcl
tls_cert_file = "/etc/vault/tls/vault.crt"
tls_key_file = "/etc/vault/tls/vault.key"
tls_ca_file = "/etc/vault/tls/ca.crt"
tls_min_version = "tls12"
tls_cipher_suites = "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
tls_prefer_server_cipher_suites = "true"
```

### 3. Authentication Methods

Enable strong authentication methods and disable insecure defaults.

#### Enable Recommended Auth Methods

```bash
# Enable Kubernetes auth
vault auth enable kubernetes

# Enable JWT/OIDC auth
vault auth enable oidc

# Enable LDAP auth (if needed)
vault auth enable ldap

# Disable token auth (if not needed)
vault auth disable token
```

#### Configure Kubernetes Auth

```bash
# Configure Kubernetes auth
vault write auth/kubernetes/config \\
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \\
    token_reviewer_jwt="$JWT_TOKEN" \\
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```

#### Enable MFA

```bash
# Enable Duo MFA
vault write sys/mfa/method/duo/primary \\
    method_name="duo" \\
    username_format="%s" \\
    integration_key="${DUO_INTEGRATION_KEY}" \\
    secret_key="${DUO_SECRET_KEY}" \\
    api_host="${DUO_API_HOST}"
```

### 4. Authorization - Policies

Implement least-privilege access using Vault policies.

#### Create Granular Policies

```hcl
# policy-admin.hcl
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# policy-developer.hcl
path "secret/data/dev/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/data/dev" {
  capabilities = ["read", "list"]
}

path "kv/data/build/*" {
  capabilities = ["create", "read", "update"]
}

# policy-readonly.hcl
path "secret/*" {
  capabilities = ["read", "list"]
}
```

#### Apply Policies

```bash
vault policy write admin policy-admin.hcl
vault policy write developer policy-developer.hcl
vault policy write readonly policy-readonly.hcl
```

### 5. Audit Logging

Enable comprehensive audit logging for compliance and forensics.

#### Enable Audit Devices

```bash
# Enable file audit log
vault audit enable file file_path=/var/log/vault/audit.log

# Enable syslog audit (optional)
vault audit enable syslog tag="vault"

# Enable socket audit (for SIEM integration)
vault audit enable socket address=tcp://siem.example.com:9000
```

#### Configure Audit Log Rotation

```bash
# /etc/logrotate.d/vault
/var/log/vault/audit.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0600 vault vault
    postrotate
        systemctl reload vault
    endscript
}
```

### 6. Network Security

Restrict network access to Vault.

#### Firewall Rules

```bash
# Allow only specific IPs
iptables -A INPUT -p tcp --dport 8200 -s 10.0.0.0/8 -j ACCEPT
iptables -A INPUT -p tcp --dport 8200 -j DROP

# Or using ufw
ufw allow from 10.0.0.0/8 to any port 8200
ufw deny to any port 8200
```

#### Use Vault with a Load Balancer

```hcl
# In HA mode, use cluster address
cluster_addr = "https://vault-node-1.example.com:8201"
api_addr = "https://vault.example.com:8200"
```

### 7. Sealing and Unsealing

Configure secure key management for sealing/unsealing.

#### Use Auto-Unseal with Cloud KMS

```hcl
# /etc/vault.d/vault.hcl
seal "awskms" {
  region     = "us-east-1"
  kms_key_id = "alias/vault-kms-key"
}

# Or Azure Key Vault
seal "azurekeyvault" {
  tenant_id      = "${AZURE_TENANT_ID}"
  vault_name     = "vault-keyvault"
  key_name       = "vault-unseal-key"
  client_id      = "${AZURE_CLIENT_ID}"
  client_secret  = "${AZURE_CLIENT_SECRET}"
}

# Or GCP Cloud KMS
seal "gcpckms" {
  project    = "my-project"
  location   = "global"
  key_ring   = "vault-ring"
  crypto_key = "vault-unseal-key"
}
```

#### Manual Unseal with Shamir Keys

```bash
# Initialize with 5 shares, require 3 to unseal
vault operator init -key-shares=5 -key-threshold=3

# Unseal with 3 keys
vault operator unseal
# Enter key 1
vault operator unseal
# Enter key 2
vault operator unseal
# Enter key 3
```

### 8. Resource Limits and Rate Limiting

Protect against DoS attacks.

#### Configure Rate Limits

```hcl
# /etc/vault.d/vault.hcl
ui = true
api_addr = "https://vault.example.com:8200"

# Rate limiting
rate_limit_config {
  rate_limit_threshold = 1000
  rate_limit_token_burst = 100
}
```

#### Use Namespaces for Multi-Tenant Isolation

```bash
# Create namespaces
vault namespace create admin
vault namespace create prod
vault namespace create dev

# Create policy for prod namespace
vault policy write prod-admin - <<EOF
path "prod/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF
```

### 9. Enterprise Features (if applicable)

If using Vault Enterprise:

#### Enable Replication

```bash
# Enable performance replication
vault write -f sys/replication/performance/primary/enable \\
    primary_cluster_addresses="https://vault-primary-1:8201"

# Enable disaster recovery replication
vault write -f sys/replication/dr/primary/enable \\
    primary_cluster_addresses="https://vault-primary-1:7201"
```

#### Enable HSM Auto-Unseal

```hcl
seal "pkcs11" {
  lib                     = "/usr/lib64/libsofthsm2.so"
  slot                    = "0"
  pin                     = "1234"
  key_label               = "vault-hsm-key"
  hmac_key_label          = "vault-hmac-key"
}
```

### 10. Hardening Checklist

| Item | Description | Priority |
|------|-------------|----------|
| TLS 1.2+ | Force TLS 1.2 minimum | Critical |
| Audit logging | Enable file audit device | Critical |
| Least privilege policies | Create granular policies | Critical |
| MFA | Enable multi-factor authentication | High |
| Auto-unseal | Use cloud KMS or HSM | High |
| Network isolation | Restrict by IP/firewall | High |
| Rate limiting | Configure API rate limits | Medium |
| Namespaces | Use for multi-tenancy | Medium |
| Replication | Enable for HA/DR | Medium |
| Storage encryption | Enable at-rest encryption | Medium |

## Verify

### Check Vault Status

```bash
vault status
# Verify: Seal status, HA mode, encryption
```

### Verify TLS Configuration

```bash
curl -k -s https://vault.example.com:8200/v1/sys/health | jq
# Verify: TLS is working, certificate is valid
```

### List Enabled Auth Methods

```bash
vault auth list
# Verify: Only required auth methods are enabled
```

### List Policies

```bash
vault policy list
# Verify: Granular policies exist
```

### Check Audit Devices

```bash
vault audit list
# Verify: Audit logging is enabled
```

### Test Authentication

```bash
# Login with a test user
vault login -method=kubernetes role=dev
vault token lookup
# Verify: Token has expected policies
```

## Rollback

### Disable Auth Method

```bash
vault auth disable kubernetes
```

### Revoke Policies

```bash
vault policy delete developer
```

### Disable Audit Device

```bash
vault audit disable file
```

### Seal Vault (Emergency)

```bash
vault operator seal
```

## Common errors

### "x509: certificate signed by unknown authority"

Cause: TLS CA certificate not trusted. Ensure the CA certificate is added to the system trust store or use `-k` flag with curl.

### "permission denied" after login

Cause: User's token lacks required policy. Verify the policy is attached to the auth method role or entity.

### "audit logging failed"

Cause: Audit device file not writable or disk full. Check file permissions and disk space.

### "seal key not found"

Cause: Auto-unseal KMS key missing or inaccessible. Verify KMS key exists and Vault has permission to use it.

### "too many requests"

Cause: Rate limit exceeded. Increase rate limits or implement client-side caching.

## References

- HashiCorp Vault Production Hardening Guide — https://developer.hashicorp.com/vault/docs/enterprise/production-hardening (verified: 2026-03-16)
- Vault Security Best Practices — https://developer.hashicorp.com/vault/docs/secrets-management/best-practices (verified: 2026-03-16)
- Vault Configuration Reference — https://developer.hashicorp.com/vault/docs/configuration (verified: 2026-03-16)
- HashiCorp Vault TLS Configuration — https://developer.hashicorp.com/vault/docs/configuration/tls (verified: 2026-03-16)
- Vault Audit Logging — https://developer.hashicorp.com/vault/docs/audit (verified: 2026-03-16)
