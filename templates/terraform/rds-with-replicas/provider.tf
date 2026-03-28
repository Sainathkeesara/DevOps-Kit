################################################################################
# RDS PostgreSQL with Read Replicas — Terraform Configuration
# Purpose: Deploy a production-grade RDS PostgreSQL instance with read replicas
#          for high availability and read scaling
# Requirements: AWS provider >= 5.0, Terraform >= 1.5
# Safety: All destructive operations require explicit confirmation via variables
# Tested on: Terraform 1.7.x, AWS provider 5.40.x
################################################################################

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
