output "primary_endpoint" {
  description = "Primary RDS instance endpoint (host:port)"
  value       = aws_db_instance.primary.endpoint
}

output "primary_address" {
  description = "Primary RDS instance hostname"
  value       = aws_db_instance.primary.address
}

output "primary_port" {
  description = "Primary RDS instance port"
  value       = aws_db_instance.primary.port
}

output "primary_arn" {
  description = "Primary RDS instance ARN"
  value       = aws_db_instance.primary.arn
}

output "reader_endpoint" {
  description = "RDS reader endpoint (load-balanced across replicas)"
  value       = aws_db_instance.primary.reader_endpoint
}

output "replica_endpoints" {
  description = "List of read replica endpoints"
  value       = aws_db_instance.read_replica[*].endpoint
}

output "replica_addresses" {
  description = "List of read replica hostnames"
  value       = aws_db_instance.read_replica[*].address
}

output "security_group_id" {
  description = "Security group ID for the RDS instances"
  value       = aws_security_group.rds.id
}

output "db_name" {
  description = "Name of the default database"
  value       = var.db_name
}

output "db_username" {
  description = "Master username"
  value       = var.db_username
  sensitive   = true
}

output "connection_string" {
  description = "PostgreSQL connection string for primary (password redacted)"
  value       = "postgresql://${var.db_username}:<REDACTED>@${aws_db_instance.primary.endpoint}/${var.db_name}?sslmode=require"
  sensitive   = true
}

output "kms_key_arn" {
  description = "KMS key ARN used for RDS encryption"
  value       = aws_kms_key.rds.arn
}
