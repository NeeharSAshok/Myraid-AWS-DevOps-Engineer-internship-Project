variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment tag for resources"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name prefix for resource naming"
  type        = string
  default     = "devops-assignment"
}

variable "instance_type" {
  description = "EC2 instance type (Free Tier eligible)"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the AWS SSH key pair to access EC2"
  type        = string
  default     = "devops-ssh-key"
}
