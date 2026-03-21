output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "instance_ids" {
  description = "IDs of EC2 instances"
  value       = module.compute.instance_ids
}

output "instance_public_ips" {
  description = "Public IP addresses of EC2 instances"
  value       = module.compute.instance_public_ips
}

output "bucket_name" {
  description = "Name of S3 bucket"
  value       = module.storage.bucket_name
}

output "bucket_arn" {
  description = "ARN of S3 bucket"
  value       = module.storage.bucket_arn
}
