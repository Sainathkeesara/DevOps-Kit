# RDS PostgreSQL with Read Replicas

## Purpose

Deploy a production-grade Amazon RDS PostgreSQL instance with read replicas for high availability and read scaling. This walkthrough covers Multi-AZ primary, read replicas, encryption at rest, automated backups, CloudWatch monitoring, and security hardening using Terraform.

## When to use

- Production databases requiring 99.95%+ uptime SLA
- Read-heavy workloads needing horizontal read scaling (reporting, analytics)
- Applications requiring automated failover with < 2 minute RTO
- Environments needing encryption at rest and in transit by default
- Multi-AZ deployments for disaster recovery
- Compliance requirements (SOC 2, PCI-DSS, HIPAA) mandating encrypted backups

## Prerequisites

- AWS account with permissions: RDS, VPC, KMS, IAM, CloudWatch, SNS
- Terraform >= 1.5 installed (`terraform version` to check)
- AWS CLI configured (`aws sts get-caller-identity` to verify)
- VPC with at least 2 private subnets in different AZs
- SNS topic for CloudWatch alarms (optional but recommended)

## Steps

### Step 1: Clone the template and configure variables

```bash
cd templates/terraform/rds-with-replicas
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your actual values. Set the database password via environment variable — never in the tfvars file:

```bash
export TF_VAR_db_password="YourSecurePassword16+"
```

### Step 2: Initialize and validate

```bash
terraform init
terraform validate
```

Expected output: `Success! The configuration is valid.`

### Step 3: Review the execution plan

```bash
terraform plan -out=rds.tfplan
```

Review the plan output carefully. You should see:
- 1 KMS key with rotation enabled
- 1 DB subnet group spanning 2+ AZs
- 1 security group with PostgreSQL ingress
- 1 parameter group with SSL enforced
- 1 primary RDS instance (Multi-AZ if enabled)
- N read replicas (per `read_replica_count`)
- CloudWatch alarms (if SNS topic configured)

Verify resource counts match expectations before proceeding.

### Step 4: Apply the configuration

```bash
terraform apply rds.tfplan
```

This creates the primary instance first, then read replicas. The primary takes 10-20 minutes; each replica takes 5-10 minutes. Monitor progress:

```bash
aws rds describe-db-instances \
  --db-instance-identifier myapp-prod-postgres-primary \
  --query 'DBInstances[0].DBInstanceStatus'
```

### Step 5: Verify connectivity

```bash
# Get endpoints from Terraform output
PRIMARY=$(terraform output -raw primary_address)
READER=$(terraform output -raw reader_endpoint)

# Test primary connection
psql "postgresql://dbadmin:${TF_VAR_db_password}@${PRIMARY}:5432/appdb?sslmode=require" \
  -c "SELECT version();"

# Test reader endpoint (load-balanced across replicas)
psql "postgresql://dbadmin:${TF_VAR_db_password}@${READER}:5432/appdb?sslmode=require" \
  -c "SELECT inet_server_addr();"  # Shows which replica handled the query
```

### Step 6: Verify replication

Connect to the primary and check replica status:

```sql
-- On primary
SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn,
       pg_wal_lsn_diff(sent_lsn, replay_lsn) AS replay_lag_bytes
FROM pg_stat_replication;
```

### Step 7: Configure application connection strings

For read/write operations (primary):
```
postgresql://dbadmin:PASSWORD@PRIMARY_ENDPOINT:5432/appdb?sslmode=require
```

For read-only operations (replicas, load-balanced):
```
postgresql://dbadmin:PASSWORD@READER_ENDPOINT:5432/appdb?sslmode=require
```

For direct replica access:
```
postgresql://dbadmin:PASSWORD@REPLICA_N_ENDPOINT:5432/appdb?sslmode=require
```

### Step 8: Set up parameter tuning for production

Modify `parameter_group_name` or add parameters in `main.tf`:

```hcl
parameter {
  name  = "max_connections"
  value = "200"
}

parameter {
  name  = "shared_buffers"
  value = "{DBInstanceClassMemory/4}"  # 25% of instance memory
}

parameter {
  name  = "effective_cache_size"
  value = "{DBInstanceClassMemory*3/4}"  # 75% of instance memory
}
```

After modifying, apply with:
```bash
terraform plan -out=rds.tfplan
terraform apply rds.tfplan
# Some parameters require a reboot:
aws rds reboot-db-instance --db-instance-identifier myapp-prod-postgres-primary
```

### Step 9: Test failover (production readiness)

```bash
# Force a failover on the primary
aws rds reboot-db-instance \
  --db-instance-identifier myapp-prod-postgres-primary \
  --force-failover

# Monitor the failover (typically 60-120 seconds)
watch -n 5 'aws rds describe-db-instances \
  --db-instance-identifier myapp-prod-postgres-primary \
  --query "DBInstances[0].[DBInstanceStatus,SecondaryAvailabilityZone]"'
```

After failover, verify the application reconnects automatically.

## Verify

1. Check all instances are available:
```bash
terraform output
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]'
```

2. Verify encryption is enabled:
```bash
aws rds describe-db-instances \
  --db-instance-identifier myapp-prod-postgres-primary \
  --query 'DBInstances[0].[StorageEncrypted,KmsKeyId]'
```

3. Verify backups are configured:
```bash
aws rds describe-db-instances \
  --db-instance-identifier myapp-prod-postgres-primary \
  --query 'DBInstances[0].[BackupRetentionPeriod,PreferredBackupWindow]'
```

4. Check CloudWatch alarms:
```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix myapp-prod-rds \
  --query 'MetricAlarms[*].[AlarmName,StateValue]'
```

5. Verify replica lag:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name ReplicaLag \
  --dimensions Name=DBInstanceIdentifier,Value=myapp-prod-postgres-replica-1 \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

## Rollback

### Scale down replicas (keep primary)
```bash
# Set replica count to 0 in terraform.tfvars
# read_replica_count = 0
terraform plan -out=rds.tfplan
terraform apply rds.tfplan
```

### Destroy everything (CAUTION)
```bash
# First disable deletion protection
# deletion_protection = false
# skip_final_snapshot = true  # for dev only
terraform plan -destroy -out=destroy.tfplan
terraform apply destroy.tfplan
```

### Manual snapshot before destroy
```bash
aws rds create-db-snapshot \
  --db-instance-identifier myapp-prod-postgres-primary \
  --db-snapshot-identifier myapp-prod-manual-snapshot-$(date +%Y%m%d)
```

## Common errors

### Error: "DBSubnetGroupDoesNotCoverEnoughAZs"

**Symptom:** `The DB subnet group doesn't meet Availability Zone coverage requirement`

**Solution:** Ensure `private_subnet_ids` includes subnets in at least 2 different AZs:
```bash
aws ec2 describe-subnets --subnet-ids subnet-aaa111 subnet-bbb222 \
  --query 'Subnets[*].[SubnetId,AvailabilityZone]'
```

### Error: "InvalidParameterCombination: Enhanced Monitoring requires a monitoring role"

**Symptom:** `The feature Enhanced Monitoring requires a monitoring role ARN`

**Solution:** Set `monitoring_interval = 0` to disable Enhanced Monitoring, or ensure the IAM role creation is not blocked by permissions.

### Error: "KmsKeyNotFoundException"

**Symptom:** `The specified KMS key does not exist or is not enabled`

**Solution:** Verify the KMS key policy allows the RDS service. Check:
```bash
aws kms describe-key --key-id alias/myapp-prod-rds
```

### Error: "Replica creation fails with 'source instance not found'"

**Symptom:** Read replica creation fails immediately after primary

**Solution:** Wait for the primary instance to reach `available` status before applying replica configuration. Terraform handles this via `replicate_source_db` dependency, but cross-AZ propagation can take 2-3 minutes.

### Error: "Parameter apply requires reboot"

**Symptom:** `The parameter XXX requires a DB instance reboot to apply`

**Solution:** Some parameters (like `rds.force_ssl`, `shared_preload_libraries`) require a reboot. Schedule during maintenance window or force reboot:
```bash
aws rds reboot-db-instance --db-instance-identifier myapp-prod-postgres-primary
```

### Error: "Cannot delete KMS key immediately"

**Symptom:** Terraform destroy fails on KMS key deletion

**Solution:** KMS keys have a mandatory 7-30 day deletion window. Run `terraform destroy` again after the window expires, or reduce `deletion_window_in_days` in `main.tf` (minimum 7 days).

## References

- [Amazon RDS for PostgreSQL Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [RDS Read Replicas](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html)
- [RDS Multi-AZ Deployments](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html)
- [RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
- [Terraform AWS RDS Instance Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance)
- [PostgreSQL Performance Insights](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PerfInsights.html)
- [RDS Monitoring with CloudWatch](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/MonitoringOverview.html)
