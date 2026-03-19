# terraform/main.tf — VPC and shared networking
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu-pro-server-22.04-lts-*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_vpc" "main" {
  count = var.create_vpc ? 1 : 0
  cidr_block = var.vpc_cidr
}

resource "aws_vpc" "k8s" {
  count = var.create_vpc ? 1 : 0
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

resource "aws_internet_gateway" "k8s" {
  count = var.create_vpc ? 1 : 0
  vpc_id = aws_vpc.k8s[0].id
  tags = { Name = "${var.cluster_name}-igw" }
}

resource "aws_subnet" "public" {
  count = var.create_vpc ? 1 : 0
  vpc_id                  = aws_vpc.k8s[0].id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, 0)
  availability_zone        = var.availability_zone
  map_public_ip_on_launch = true
  tags = { Name = "${var.cluster_name}-public-subnet" }
}

resource "aws_subnet" "private" {
  count = var.create_vpc ? 1 : 0
  vpc_id           = aws_vpc.k8s[0].id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, 1)
  availability_zone = var.availability_zone
  tags = { Name = "${var.cluster_name}-private-subnet" }
}

resource "aws_eip" "nat" {
  count = var.create_vpc ? 1 : 0
  domain = "vpc"
  tags = { Name = "${var.cluster_name}-nat-eip" }
  depends_on = [aws_internet_gateway.k8s]
}

resource "aws_nat_gateway" "k8s" {
  count = var.create_vpc ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
  tags = { Name = "${var.cluster_name}-nat" }
  depends_on = [aws_internet_gateway.k8s]
}

resource "aws_route_table" "public" {
  count = var.create_vpc ? 1 : 0
  vpc_id = aws_vpc.k8s[0].id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s[0].id
  }
  tags = { Name = "${var.cluster_name}-public-rt" }
}

resource "aws_route_table" "private" {
  count = var.create_vpc ? 1 : 0
  vpc_id = aws_vpc.k8s[0].id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.k8s[0].id
  }
  tags = { Name = "${var.cluster_name}-private-rt" }
}

resource "aws_route_table_association" "public" {
  count = var.create_vpc ? 1 : 0
  subnet_id      = aws_subnet.public[0].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "private" {
  count = var.create_vpc ? 1 : 0
  subnet_id      = aws_subnet.private[0].id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_security_group" "bastion" {
  name        = "${var.cluster_name}-bastion-sg"
  description = "SSH access to bastion host"
  vpc_id      = var.create_vpc == 1 ? aws_vpc.k8s[0].id : var.vpc_id

  ingress {
    from_ip   = ["${var.admin_cidr}"]
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["${var.admin_cidr}"]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.cluster_name}-bastion-sg" }
}

locals {
  vpc_id        = var.create_vpc == 1 ? aws_vpc.k8s[0].id : var.vpc_id
  public_subnet = var.create_vpc == 1 ? aws_subnet.public[0].id : var.public_subnet_id
  private_subnet = var.create_vpc == 1 ? aws_subnet.private[0].id : var.private_subnet_id
}
