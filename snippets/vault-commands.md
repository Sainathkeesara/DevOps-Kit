# Vault CLI Commands Reference

## Purpose

This snippet provides common Vault CLI commands for daily operations including authentication, secret management, policies, and troubleshooting.

## When to use

- Managing secrets and sensitive data in HashiCorp Vault
- Configuring authentication methods
- Creating and managing policies
- Debugging Vault connectivity issues

## Prerequisites

- Vault CLI installed (`vault` command available)
- Network access to Vault server
- Valid Vault token or authentication credentials

## Common Commands

### Server Management

```bash
# Check Vault status
vault status

# List all mounted secrets engines
vault secrets list

# List all enabled auth methods
vault auth list

# Get Vault version
vault version
```

### Authentication

```bash
# Login with token
vault login <token>

# Login with username/password (userpass auth)
vault login -method=userpass username=<username>

# Login with Kubernetes auth
vault login -method=kubernetes role=<role_name>

# Login with AWS IAM auth
vault login -method=aws role=<role_name>

# Revoke current token
vault token revoke -self

# Revoke a specific token
vault token revoke <token>

# Create new token with specific policies
vault token create -policy=<policy_name>
```

### Key-Value Secrets (v2)

```bash
# Read a secret
vault kv get secret/<path>

# List secrets at path
vault kv list secret/

# Write a secret
vault kv put secret/<path> key1=value1 key2=value2

# Delete a secret
vault kv delete secret/<path>

# Permanently delete a secret (metadata must be deleted first)
vault kv metadata delete secret/<path>

# Undelete a secret version
vault kv undelete -version=<version> secret/<path>

# Get specific version of secret
vault kv get -version=<version> secret/<path>

# Patch a secret (modify only specified keys)
vault kv patch secret/<path> key1=new_value
```

### Policies

```bash
# List all policies
vault policy list

# Read a specific policy
vault policy read <policy_name>

# Write a policy from file
vault policy write <policy_name> @policy.hcl

# Read current token capabilities for a path
vault capabilities <path>

# Read capabilities for a specific token
vault token capabilities <token> <path>
```

### Transit Secrets Engine (Encryption)

```bash
# Enable Transit secrets engine
vault secrets enable transit

# Create encryption key
vault write -f transit/keys/<key_name>

# Encrypt data
vault transit encrypt <key_name> plaintext=<base64_data>

# Decrypt data
vault transit decrypt <key_name> ciphertext=<ciphertext>

# Rewrap data (rotate key, re-encrypt)
vault transit rewrap <key_name> ciphertext=<old_ciphertext>

# Generate hash of data
vault transit hash <key_name> plaintext=<data>
```

### Database Secrets Engine

```bash
# Enable Database secrets engine
vault secrets enable database

# Configure database connection
vault write database/config/<config_name> \
    plugin_name=postgresql-database-plugin \
    connection_url="postgresql://user:pass@localhost:5432/vault" \
    allowed_roles=<role_name>

# Create database role
vault write database/roles/<role_name> \
    db_name=<config_name> \
    creation_statements="CREATE ROLE ..." \
    default_ttl=1h max_ttl=24h

# Generate database credentials
vault read database/creds/<role_name>
```

### Kubernetes Authentication

```bash
# Enable Kubernetes auth method
vault auth enable kubernetes

# Configure Kubernetes auth
vault write auth/kubernetes/config \
    kubernetes_host=https://<k8s_api_host> \
    kubernetes_ca_cert=@<ca_cert_file>

# Create Kubernetes auth role
vault write auth/kubernetes/role/<role_name> \
    bound_service_account_names=<sa_name> \
    bound_service_account_namespaces=<namespace> \
    policies=<policy_name> \
    ttl=1h
```

### PKI Secrets Engine

```bash
# Enable PKI secrets engine
vault secrets enable pki

# Generate root CA
vault write pki/root/generate/internal \
    common_name=<company> Root CA \
    ttl=87600h

# Generate intermediate CA
vault write pki_int/intermediate/generate/internal \
    common_name=<company> Intermediate CA \
    | tee pki_int.csr

# Sign intermediate CSR
vault write pki_root/root/sign-intermediate \
    csr=@pki_int.csr \
    format=pem_bundle | tee intermediate.cert.pem

# Issue certificate
vault write pki/issue/<role_name> \
    common_name=<hostname> \
    ttl=24h

# Revoke certificate
vault write pki/revoke serial_number=<serial_number>
```

### Monitoring and Debugging

```bash
# Get health status
vault read sys/health

# Get leader status
vault read sys/leader

# Get raft peer status
vault read sys/storage/raft/configuration

# List all Vault metrics
vault metrics

# Get configuration
vault read sys/config/state

# Audit device status
vault audit list
```

### Transit Operations

```bash
# Rotate encryption key (creates new version)
vault write -f transit/keys/<key_name>/rotate

# Get key version info
vault read transit/keys/<key_name>

# Verify decryption (without returning plaintext)
vault transit verifySignature <key_name> signature=<signature> hash=sha2-256 plaintext=<data>
```

### Token Management

```bash
# Look up token info
vault token lookup

# Look up another token
vault token lookup <token>

# Renew token
vault token renew <token>

# Create orphan token (not inheriting parent's TTL)
vault token create -orphan -policy=<policy_name>
```

### Monitoring Health

```bash
# Check if Vault is sealed
vault status -format=json | jq '.sealed'

# Check storage backend health
vault read sys/storage/raft/health

# Get audit log status
vault audit list -detailed
```

## Verify

After running commands, verify:
- `vault status` shows Vault as initialized and unsealed
- Authentication commands succeed without errors
- Secrets can be read after writing
- Policies have correct permissions

## Rollback

- For accidentally deleted secrets: use `vault kv undelete` within the deletion window
- For policy changes: restore from version control
- For token revocation: request new token from Vault admin

## Common Errors

| Error | Solution |
|-------|----------|
| `permission denied` | Check token capabilities with `vault capabilities` |
| `vault is sealed` | Unseal Vault with `vault operator unseal` |
| `connection refused` | Verify Vault server is running and accessible |
| `invalid token` | Re-authenticate with `vault login` |
| `role not found` | Verify role exists in the auth method |
| `database connection failed` | Check database credentials and network connectivity |

## References

- [Vault CLI Documentation](https://developer.hashicorp.com/vault/docs/commands)
- [Vault Secrets Engines](https://developer.hashicorp.com/vault/docs/secrets)
- [Vault Authentication](https://developer.hashicorp.com/vault/docs/auth)
- [Vault Policies](https://developer.hashicorp.com/vault/docs/concepts/policies)
