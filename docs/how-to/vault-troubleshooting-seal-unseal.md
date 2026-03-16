# Troubleshooting Vault Seal/Unseal Issues

## Purpose

This guide provides detailed troubleshooting steps for HashiCorp Vault seal and unseal failures. It covers common error scenarios, root cause analysis, and remediation procedures for both development and production environments.

## When to use

- Vault cluster fails to unseal after restart
- Unseal key validation errors occur
- Seal wrap or auto-unseal failures
- Recovery mode access needed
- High availability cluster seal/unseal issues
- Hardware Security Module (HSM) related seal problems

## Prerequisites

- HashiCorp Vault installed (v1.12+ recommended)
- Access to unseal keys (shamir or HSM)
- Root or operator access to Vault server
- For HSM: PKCS#11 library and HSM credentials
- For auto-unseal: Cloud KMS or Transit secrets engine access

## Steps

### 1. Identify Current Vault Seal Status

Check the current status of the Vault service:

```bash
# Check Vault status
vault status

# Detailed status with version info
vault status -format=json

# Check system logs for seal-related errors
journalctl -u vault -n 100 --no-pager
```

Expected output for unsealed Vault:
```
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    5
Threshold       3
Unseal Progress 0/0
Version         1.16.1
Build Date      2024-01-15T14:30:00Z
Storage Type    consul
```

### 2. Unseal Vault with Shamir Keys

If Vault is sealed, provide the unseal keys:

```bash
# Unseal with single key (repeat for threshold count)
vault operator unseal

# Unseal with key provided directly (interactive)
vault operator unseal

# Unseal with key in environment variable (less secure)
VAULT_UNSEAL_KEY="..." vault operator unseal

# Non-interactive unseal with key
echo "unseal-key" | vault operator unseal -
```

### 3. Common Unseal Failure Scenarios

#### Scenario A: Invalid Unseal Key

Error message:
```
Error unsealing: Error making API request.
URL: PUT http://127.0.0.1:8200/v1/sys/unseal
Code: 400. Errors:
* invalid unseal key
```

**Resolution:**
- Verify you have the correct unseal key from key shares
- Ensure no whitespace or newline characters in the key
- Check if Vault was rekeyed and you need new keys
- Restore from backup if keys are lost

#### Scenario B: Key Threshold Not Met

Error message:
```
Unseal Progress: 2/3
```

**Resolution:**
- Continue providing unseal keys until threshold is reached
- Each key must be from the same key share set

#### Scenario C: Storage Connectivity Issue

Error message:
```
Error unsealing: Error making API request.
URL: PUT http://127.0.0.1:8200/v1/sys/unseal
Code: 500. Errors:
* failed to decrypt barrier: encryption key is nil
```

**Resolution:**
- Verify storage backend is accessible
- Check Consul/etcd/network connectivity
- Ensure storage credentials are valid
- Review storage backend logs

### 4. Auto-Unseal Troubleshooting

For cloud-based auto-unseal (AWS KMS, Azure Key Vault, GCP Cloud KMS):

#### AWS KMS Auto-Unseal

```bash
# Check Vault configuration
grep -A 10 "seal" /etc/vault.d/vault.hcl

# Verify KMS key is enabled
aws kms describe-key --key-id <kms-key-id>

# Check IAM permissions
aws iam simulate-principal-policy \
  --policy-source-arn <vault-iam-role> \
  --action-names kms:Decrypt kms:DescribeKey
```

#### Azure Key Vault Auto-Unseal

```bash
# Check Azure authentication
az account show
az keyvault key show --vault-name <vault-name> --name <key-name>

# Verify Vault has access to Key Vault
az keyvault show --name <vault-name>
```

#### GCP Cloud KMS Auto-Unseal

```bash
# Verify GCP credentials
gcloud auth application-default-login
gcloud kms keyrings list --location=global
gcloud kms keys list --keyring=<keyring> --location=global
```

### 5. HSM Seal Troubleshooting

For Hardware Security Module based sealing:

```bash
# Verify PKCS#11 library is accessible
ls -la /usr/lib/pkcs11/libsofthsm2.so

# Check Vault HSM configuration
grep -A 20 "seal" /etc/vault.d/vault.hcl

# Test HSM connectivity
pkcs11-tool --module /usr/lib/pkcs11/libsofthsm2.so --list-slots

# Check HSM slot status
vault operator diagnose
```

Common HSM errors:
- `failed to initialize HSM: no slots available` - Check HSM slot configuration
- `HSM token not found` - Verify PKCS#11 token is initialized
- `key not found` - HSM key may have been rotated or deleted

### 6. Recovery Mode Unseal

When normal unseal fails, use recovery mode:

```bash
# Start Vault in recovery mode
vault server -config=/etc/vault.d/vault.hcl -recovery

# In another terminal, use recovery keys
vault operator unseal -recovery
```

Recovery mode uses separate recovery keys (not the primary unseal keys).

### 7. Seal Status After Unseal

Verify Vault is fully operational:

```bash
# Check seal status
vault status

# Test read access
vault kv get secret/test

# Check audit logs
vault audit list
```

### 8. Manual Seal (Emergency)

If you need to manually seal Vault:

```bash
# Seal Vault normally
vault operator seal

# Force seal (for clustered environments)
vault operator seal -force
```

## Verify

After troubleshooting, verify the fix:

```bash
# Confirm Vault is unsealed and operational
vault status

# Test secret read/write
vault kv put secret/test key=value
vault kv get secret/test
vault kv delete secret/test

# Check cluster health (HA mode)
vault operator raft list-peers
```

## Rollback

If changes cause issues:

```bash
# Restore previous Vault configuration
cp /etc/vault.d/vault.hcl.bak /etc/vault.d/vault.hcl

# Restart Vault service
systemctl restart vault

# If using old unseal keys, restore from backup
# (restore from sealed backup only if absolutely necessary)
```

## Common Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| `invalid unseal key` | Wrong key provided | Use correct key shares |
| `encryption key is nil` | Storage inaccessible | Check storage connectivity |
| `failed to decrypt barrier` | Storage encryption issue | Verify storage credentials |
| `HSM slot not found` | HSM not initialized | Initialize HSM slot |
| `auto-unseal failed` | Cloud KMS access issue | Verify IAM/credentials |
| `recovery key required` | Standard keys don't work | Use recovery mode |
| `unseal progress stalled` | Partial unseal | Continue with remaining keys |

## References

- HashiCorp Vault Seal/Unseal Documentation — https://developer.hashicorp.com/vault/docs/concepts/seal (verified: 2026-03-16)
- Vault Auto-Unseal Guide — https://developer.hashicorp.com/vault/docs/concepts/autosha (verified: 2026-03-16)
- Vault Recovery Mode — https://developer.hashicorp.com/vault/docs/concepts/recovery-mode (verified: 2026-03-16)
- HSM Seal Configuration — https://developer.hashicorp.com/vault/docs/configuration/seal/pkcs11 (verified: 2026-03-16)
