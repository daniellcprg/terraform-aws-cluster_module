terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.12.1"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    "Tier" = "public"
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = var.environment

  tags = {
    "Terraform"   = "true"
    "Environment" = var.environment
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name = format("cluster-%s", var.environment)

  assume_role_policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = format("cluster-%s", var.environment)

    policy = jsonencode({
      Statement = [
        {
          Action = [
            "ecs:CreateCluster",
            "ecs:DeregisterContainerInstance",
            "ecs:DiscoverPollEndpoint",
            "ecs:Poll",
            "ecs:RegisterContainerInstance",
            "ecs:StartTelemetrySession",
            "ecs:Submit*",
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }

  tags = {
    "Terraform"   = "true"
    "Environment" = var.environment
  }
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = format("cluster-%s", var.environment)
  role = aws_iam_role.ecs_instance_role.name

  tags = {
    "Terraform"   = "true"
    "Environment" = var.environment
  }
}

resource "aws_security_group" "ecs_instance-sg" {
  name   = format("cluster-%s", var.environment)
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
    "Name"        = format("cluster-%s", var.environment)
    "Terraform"   = "true"
    "Environment" = var.environment
  }
}

resource "aws_instance" "ecs_instance" {
  ami                         = "ami-00131b70724817da9"
  instance_type               = "t2.micro"
  iam_instance_profile        = aws_iam_instance_profile.ecs_instance_profile.name
  subnet_id                   = tolist(data.aws_subnets.public.ids)[0]
  vpc_security_group_ids      = ["${aws_security_group.ecs_instance-sg.id}"]
  associate_public_ip_address = true
  key_name                    = "ec2-access-key"

  user_data = <<EOF
  #!/bin/bash
  echo ECS_CLUSTER=${var.environment} >> /etc/ecs/ecs.config
  EOF

  tags = {
    "Name"        = format("cluster-%s", var.environment)
    "Terraform"   = "true"
    "Environment" = var.environment
  }

  depends_on = [
    aws_ecs_cluster.cluster,
  ]
}
