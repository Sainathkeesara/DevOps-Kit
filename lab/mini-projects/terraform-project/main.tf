terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.common_tags
  }
}

module "vpc" {
  source = "./modules/network"

  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  availability_zones = var.availability_zones

  tags = var.common_tags
}

module "compute" {
  source = "./modules/compute"

  environment     = var.environment
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  instance_type  = var.instance_type
  key_name       = var.key_name

  tags = var.common_tags
}

module "storage" {
  source = "./modules/storage"

  environment = var.environment
  bucket_name = var.bucket_name
  enable_versioning = var.enable_versioning

  tags = var.common_tags
}
