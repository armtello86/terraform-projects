variable "function_name" {
  type = string
}

variable "source_dir" {
  description = "Folder containing lambda_function.py"
  type        = string
}

variable "runtime" {
  type = string
}

variable "timeout" {
  type    = number
  default = 3
}

variable "memory_size" {
  type    = number
  default = 128
}

variable "environment" {
  description = "Environment variables for the function"
  type        = map(string)
  default     = {}
}

variable "policy_json" {
  description = "Inline least-privilege policy (null = none)"
  type        = string
  default     = null
}

variable "managed_policy_arns" {
  description = "Extra managed policies (e.g. SQS/DynamoDB execution roles)"
  type        = list(string)
  default     = []
}