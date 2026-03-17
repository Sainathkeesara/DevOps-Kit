# Troubleshooting Vault Seal/Unseal Issues

## Purpose

Diagnose and resolve HashiCorp Vault seal and unseal issues. This guide covers common failure scenarios, recovery procedures, and preventive measures for Vault sealed states.

## When to use

- Vault cluster shows `Sealed: true` status
- Unseal process fails with authentication or key errors
- Vault fails to start after restart or failover
- Lost unseal keys require recovery procedures
- Performance degradation due to seal/unseal operations

## Prerequisites

- Access to Vault server host (SSH or console)
- Unseal keys (for auto-unseal: cloud KMS credentials or Vault configuration)
- Root or operator access to the Vault cluster
- For Kubernetes: kubectl access to the Vault namespace
- For cloud: appropriate IAM permissions for KMS operations

## Steps

### 1. Verify Vault Status

```bash
vault status
```

Expected output for a healthy Vault:
```
Key Value
--- -----
Seal Type Shamir
Initialized true
Sealed false
Total Shares 5
Threshold 3
Version 1.16.0
Build Date 2024-01-15T14:46:58Z
Storage Type raft
Cluster Name vault-cluster
Cluster ID abcdef12-3456-7890-abcd-ef1234567890
HA Enabled true
```

If sealed, note the `Seal Type`:
- `shamir` — requires manual unseal with key shares
- `awskms`, `azurekeyvault`, `gcpckms`, `vault` — auto-unseal configured

### 2. Check System Logs

#### Systemd-based Linux:

```bash
journalctl -u vault -n 100 --no-pager
```

#### Kubernetes:

```bash
kubectl get pods -n vault -l app.kubernetes.io/name=vault
kubectl logs vault-0 -n vault
kubectl describe pod vault-0 -n vault
```

#### Docker:

```bash
docker logs <vault-container-id>
```

Look for error patterns:
- `permission denied` — file or key access issues
- `connection refused` — network or storage backend problems
- `key not found` — storage backend corruption
- `unseal failed` — invalid keys or KMS issues

### 3. Manual Unseal (Shamir)

For Shamir-based seal, you need `threshold` number of key shares:

```bash
vault operator unseal <key-share-1>
vault operator unseal <key-share-2>
vault operator unseal <key-share-3>
```

Verify status after each key:
```bash
vault status
```

Common errors:

| Error | Cause | Resolution |
|-------|-------|------------|
| `invalid key` | Wrong key or corrupted key | Verify key; check for typos |
| `stored keys do not add up` | Keys from wrong Vault | Use correct key set for this cluster |
| `cannot fetch master key` | Insufficient key shares | Provide more key shares |

### 4. Auto-Unseal Configuration Issues

#### AWS KMS:

```bash
vault status
aws kms describe-key --key-id <kms-key-id>
```

Verify KMS key is accessible and not disabled:
- Check IAM role has `kms:Decrypt` permission
- Verify KMS key is not scheduled for deletion
- Ensure KMS key region matches Vault configuration

#### Azure Key Vault:

```bash
az keyvault key show --vault-name <vault-name> --name <key-name>
```

Verify:
- Azure AD application has Key Vault permissions
- Key is not soft-deleted or in recovery mode
- Vault can authenticate to Azure

#### GCP Cloud KMS:

```bash
gcloud kms keys describe --key-ring <ring> --location global --key <key>
```

Verify:
- Service account has Cloud KMS CryptoKey Decrypter role
- Key version is enabled
- Project has Cloud KMS API enabled

### 5. Recovery from Lost Keys

If unseal keys are lost, use the recovery mechanism:

#### Generate new recovery keys (requires security token):

```bash
vault operator generate-root -init
vault operator generate-root
```

#### For Raft storage, attempt recovery from snapshot:

```bash
vault operator raft snapshot save /backup/vault.snap
vault operator raft snapshot restore /backup/vault.snap
```

#### For etcd backend:

```bash
etcdctl snapshot save /backup/etcd.snap
etcdctl snapshot restore /backup/etcd.snap
```

### 6. Cluster-Specific Procedures

#### HA Cluster Unseal:

1. Unseal the leader first:
```bash
vault operator unseal <key>
```

2. Verify leader election:
```bash
vault status
```

3. Unseal standby nodes:
```bash
# For each standby node
ssh <standby-host>
vault operator unseal <key>
```

#### Kubernetes StatefulSet:

```bash
# Check Vault pod status
kubectl get pods -n vault -l app.kubernetes.io/name=vault

# For each Vault pod, exec and unseal
kubectl exec -n vault vault-0 -- vault operator unseal <key>
kubectl exec -n vault vault-1 -- vault operator unseal <key>
```

### 7. Storage Backend Issues

#### Integrated Raft:

```bash
# Check Raft storage status
vault operator raft list-peers

# Check for leader issues
vault operator raft inspect
```

Common issues:
- Node not reaching consensus — check network connectivity
- Snapshot mismatch — restore from backup
- Journal too large — run defragmentation

#### Consul:

```bash
consul members
consul info
```

Verify:
- Consul cluster is healthy
- Network connectivity between Vault and Consul
- ACL policies allow Vault access

## Verify

After unsealing, verify Vault is operational:

```bash
vault status
vault operator raft list-peers
vault write sys/health -format=json
```

Test read/write:
```bash
vault kv put secret/test key=value
vault kv get secret/test
vault kv delete secret/test
```

For HA clusters:
```bash
# Verify all nodes are unsealed and communicating
curl -s http://<leader-ip>:8200/v1/sys/health | jq
curl -s http://<standby-ip>:8200/v1/sys/health | jq
```

## Rollback

If changes cause issues:

1. Revert configuration changes:
```bash
# Restore Vault config from backup
sudo systemctl restart vault
```

2. For Kubernetes:
```bash
kubectl rollout undo statefulset/vault -n vault
```

3. Restore from backup:
```bash
vault operator raft snapshot restore /backup/vault-backup.snap
```

## Common Errors

### Error: "Vault is already sealed"

```
Error sealing: Error making API request.
URL: PUT http://127.0.0.1:8200/v1/sys/unseal
Code: 400. Errors:

* Vault is already sealed
```

**Cause**: Vault received a seal command or detected a failure condition.

**Resolution**:
```bash
vault operator unseal <key>
```

### Error: "Failed to decrypt key"

```
Error unsealing: Error making API request.
URL: PUT http://127.0.0.1:8200/v1/sys/unseal
Code: 500. Errors:

* failed to decrypt key: cipher: message too short
```

**Cause**: Corrupted unseal key or KMS key issue.

**Resolution**:
- Verify KMS key status
- Check for key rotation that may have invalidated old keys
- Review KMS key policy

### Error: "Failed to fetch storage entry"

```
Error initializing: Error making API request.
URL: PUT http://127.0.0.1:8200/v1/sys/init
Code: 500. Errors:

* failed to fetch storage entry: connection refused
```

**Cause**: Storage backend unreachable.

**Resolution**:
- Verify storage backend (Consul, etcd, Raft) is running
- Check network connectivity
- Verify storage backend credentials

### Error: "Unable to get token from"

```
Error unsealing: Error making API request.
URL: PUT http://127.0.0.1:8200/v1/sys/unseal
Code: 400. Errors:

* unable to get token: Vault agent token not found
```

**Cause**: Vault Agent misconfiguration or failure.

**Resolution**:
- Check Vault Agent logs
- Verify agent cache and sink configuration
- Restart Vault Agent

### Error: "Raft cluster needs to have 3 nodes"

```
Error initializing: Error making API request.
URL: PUT http://127.0.0.1:8200/v1/sys/init
Code: 400. Errors:

* storage backend: Raft cluster needs to have 3 nodes to support failover
```

**Cause**: Insufficient nodes for Raft consensus.

**Resolution**:
- Add more nodes to the cluster
- For dev/test: use `-raft-multi-node=false` (not for production)

## References

- HashiCorp Vault Unseal Documentation — https://developer.hashicorp.com/vault/docs/concepts/seal (verified: 2026-03-17)
- Vault Auto-Unseal Guide — https://developer.hashicorp.com/vault/docs/configuration/seal (verified: 2026-03-17)
- Vault Recovery Mode — https://developer.hashicorp.com/vault/docs/concepts/recovery-mode (verified: 2026-03-17)
- Vault Raft Storage — https://developer.hashicorp.com/vault/docs/configuration/storage/raft (verified: 2026-03-17)
- AWS KMS Seal Configuration — https://developer.hashicorp.com/vault/docs/configuration/seal/awskms (verified: 2026-03-17)
- Azure Key Vault Seal — https://developer.hashicorp.com/vault/docs/configuration/seal/azurekeyvault (verified: 2026-03-17)
- GCP Cloud KMS Seal — https://developer.hashicorp.com/vault/docs/configuration/seal/gcpckms (verified: 2026-03-17)
