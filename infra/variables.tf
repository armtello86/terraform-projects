variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, uat, prod)"
  type        = string
  default     = "dev"
}

variable "alert_email" {
  description = "Email address for SNS subscriptions (welcome, digest, ops)"
  type        = string
}

variable "lambda_runtime" {
  description = "Python runtime for all functions"
  type        = string
  default     = "python3.14" # if plan rejects it, your provider is older: use python3.13
}

variable "external_api_key" {
  description = "Demo secret stored as SecureString (not a real credential)"
  type        = string
  sensitive   = true # hides the value in plan/apply output
}