variable "region" {
  description = "The region where the cluster will be created"
  type        = string
}

variable "environment" {
  description = "The environment to deploy to"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID to deploy to"
  type        = string
}
