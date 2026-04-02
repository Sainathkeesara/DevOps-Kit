# Development Environment Variables
environment            = "dev"
aws_region             = "us-east-1"
project_name           = "multi-env"
vpc_cidr               = "10.0.0.0/16"
availability_zones     = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs    = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs   = ["10.0.11.0/24", "10.0.12.0/24"]
enable_nat_gateway     = true
single_nat_gateway     = true

environment_tags = {
  CostCenter = "DevOps-Dev"
  Team       = "Platform"
  Owner      = "devops@example.com"
}