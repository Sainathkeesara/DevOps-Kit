# terraform/workers.tf

resource "aws_security_group" "k8s_workers" {
  name        = "${var.cluster_name}-worker-sg"
  description = "Security group for Kubernetes worker nodes"
  vpc_id      = local.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = 10250
    to_port   = 10250
    protocol  = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "kubelet API"
  }
  ingress {
    from_port = 30000
    to_port   = 32767
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NodePort services"
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.cluster_name}-worker-sg" }
}

resource "aws_instance" "worker" {
  count         = var.worker_instance_count
  ami           = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type = var.worker_instance_type
  subnet_id    = local.private_subnet
  key_name     = var.ssh_key_name
  security_groups = [aws_security_group.k8s_workers.id]
  source_dest_check = false

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.cluster_name}-worker-${count.index + 1}"
    Role = "worker"
    Cluster = var.cluster_name
  }
}
