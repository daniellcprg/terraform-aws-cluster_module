resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_environment

  tags = {
    "Provider"   = "terraform"
    "Environment" = var.cluster_environment
  }
}

resource "aws_security_group" "ecs_instance-sg" {
  name   = format("ecs-instance-%s", var.cluster_environment)
  vpc_id = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name"        = format("ecs-instance-%s", var.cluster_environment)
    "Terraform"   = "true"
    "Environment" = var.cluster_environment
  }
}

resource "aws_launch_configuration" "lc" {
  name = format("cluster-%s", var.cluster_environment)
  image_id = "ami-00131b70724817da9"
  instance_type = "t2.micro"
  iam_instance_profile = "ecsInstanceRole"
  security_groups = ["${aws_security_group.ecs_instance-sg.id}"]
  associate_public_ip_address = true
  key_name = "ec2-access-key"

  user_data = <<EOF
  #!/bin/bash
  echo ECS_CLUSTER=${var.cluster_environment} >> /etc/ecs/ecs.config
  EOF
}

resource "aws_autoscaling_group" "ecs-instance-asg" {
  name                = format("cluster-%s", var.cluster_environment)
  max_size            = 1
  min_size            = 1
  force_delete = true
  vpc_zone_identifier = var.vpc_subnet_ids
  launch_configuration = aws_launch_configuration.lc.name

  depends_on = [
    aws_ecs_cluster.cluster
  ]

  tag {
    key = "Name"
    value = format("cluster-%s", var.cluster_environment)
    propagate_at_launch = true
  }

  tag {
    key = "Provider"
    value = "terraform"
    propagate_at_launch = true
  }

  tag {
    key = "Environment"
    value = var.cluster_environment
    propagate_at_launch = true
  }
}
