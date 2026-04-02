output "environment" {
  value = var.environment
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "vpc_cidr" {
  value       = module.vpc.vpc_cidr
  description = "VPC CIDR"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "Public subnet IDs"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "Private subnet IDs"
}

output "bastion_security_group_id" {
  value       = module.vpc.bastion_security_group_id
  description = "Bastion security group ID"
}

output "app_security_group_id" {
  value       = module.vpc.app_security_group_id
  description = "App security group ID"
}