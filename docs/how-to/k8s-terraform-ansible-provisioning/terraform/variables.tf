# terraform/variables.tf

variable "cluster_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "prod-k8s"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "Availability zone for subnets"
  type        = string
  default     = "us-east-1a"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "admin_cidr" {
  description = "CIDR block allowed to SSH to bastion (your IP)"
  type        = string
  default     = "0.0.0.0/0"
}

# Set create_vpc = false and provide vpc_id + subnet IDs to use existing VPC
variable "create_vpc" {
  description = "Set to false to use an existing VPC"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "Existing VPC ID (used when create_vpc = false)"
  type        = string
  default     = ""
}

variable "public_subnet_id" {
  description = "Existing public subnet ID (used when create_vpc = false)"
  type        = string
  default     = ""
}

variable "private_subnet_id" {
  description = "Existing private subnet ID (used when create_vpc = false)"
  type        = string
  default     = ""
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair in AWS"
  type        = string
  default     = "k8s-provisioning-key"
}

variable "cp_instance_type" {
  description = "EC2 instance type for control plane nodes"
  type        = string
  default     = "t3.medium"
}

variable "cp_instance_count" {
  description = "Number of control plane nodes"
  type        = number
  default     = 3
}

variable "worker_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.large"
}

variable "worker_instance_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

variable "ami_id" {
  description = "Custom AMI ID (leave empty to use Ubuntu 22.04 from data source)"
  type        = string
  default     = ""
}
