variable "cluster_environment" {
  description = "The environment to deploy to"
  type        = string
}

variable "applications" {
  description = "The applications to deploy"
  type        = list(any)
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "vpc_subnet_ids" {
  description = "The subnet ids to deploy to"
  type        = list(string)
}

variable "alb_arn" {
  description = "The ARN of the ALB"
  type        = string
}
