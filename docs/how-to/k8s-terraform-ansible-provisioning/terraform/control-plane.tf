# terraform/control-plane.tf

resource "aws_security_group" "k8s_control_plane" {
  name        = "${var.cluster_name}-cp-sg"
  description = "Security group for Kubernetes control plane nodes"
  vpc_id      = local.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = 6443
    to_port   = 6443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kubernetes API server (NLB health check)"
  }
  ingress {
    from_port = 2379
    to_port   = 2380
    protocol  = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "etcd peer and client"
  }
  ingress {
    from_port = 10250
    to_port   = 10250
    protocol  = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "kubelet API"
  }
  ingress {
    from_port = 10259
    to_port   = 10259
    protocol  = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "kube-scheduler"
  }
  ingress {
    from_port = 10257
    to_port   = 10257
    protocol  = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "kube-controller-manager"
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.cluster_name}-cp-sg" }
}

resource "aws_instance" "bastion" {
  ami           = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id    = local.public_subnet
  key_name     = var.ssh_key_name
  security_groups = [aws_security_group.bastion.id]

  tags = {
    Name = "${var.cluster_name}-bastion"
    Role = "bastion"
  }
}

resource "aws_instance" "control_plane" {
  count         = var.cp_instance_count
  ami           = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type = var.cp_instance_type
  subnet_id    = local.private_subnet
  key_name     = var.ssh_key_name
  security_groups = [aws_security_group.k8s_control_plane.id]
  source_dest_check = false

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.cluster_name}-cp-${count.index + 1}"
    Role = "control-plane"
    Cluster = var.cluster_name
  }
}

resource "aws_lb_target_group" "k8s_api" {
  name     = "${var.cluster_name}-k8s-api-tg"
  port     = 6443
  protocol = "TCP"
  vpc_id   = local.vpc_id
  target_type = "instance"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval_seconds     = 10
    port                = 10256
    protocol            = "TCP"
  }
}

resource "aws_lb_target_group_attachment" "cp" {
  count = var.cp_instance_count
  target_group_arn = aws_lb_target_group.k8s_api.arn
  target_id        = aws_instance.control_plane[count.index].id
  port             = 6443
}

resource "aws_lb" "k8s_api" {
  name               = "${var.cluster_name}-k8s-api-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [local.public_subnet]

  enableeletion_protection = false

  tags = { Name = "${var.cluster_name}-k8s-api-nlb" }
}

resource "aws_lb_listener" "k8s_api" {
  load_balancer_arn = aws_lb.k8s_api.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_api.arn
  }
}
