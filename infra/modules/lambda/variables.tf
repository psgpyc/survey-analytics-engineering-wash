variable "function_name" {
  type        = string
  description = "Lambda function name."
  nullable    = false

  validation {
    condition     = length(trimspace(var.function_name)) > 0
    error_message = "function_name cannot be empty."
  }
}

variable "lambda_iam_role" {
    type        = string
    description = "Lambda function iam role."
    nullable    = false

    validation {
        condition     = length(trimspace(var.lambda_iam_role)) > 0
        error_message = "iam role cannot be empty."
    }
}

variable "runtime" {
  type        = string
  description = "Lambda runtime (e.g., python3.12)."
  nullable    = false

  validation {
    condition     = contains(["python3.10", "python3.11", "python3.12"], var.runtime)
    error_message = "runtime must be one of: python3.10, python3.11, python3.12."
  }
}

variable "handler" {
  type        = string
  description = "Lambda handler (e.g., app.lambda_handler)."
  nullable    = false

  validation {
    condition     = can(regex("^[a-zA-Z0-9_]+\\.[a-zA-Z0-9_]+$", var.handler))
    error_message = "handler must look like 'file.function' e.g. app.lambda_handler."
  }
}

variable "source_dir" {
  type        = string
  description = "Path to directory containing Lambda source (e.g., ../../lambda_src)."
  nullable    = false
}

variable "timeout_seconds" {
  type        = number
  description = "Lambda timeout in seconds."
  default     = 30
  nullable    = false

  validation {
    condition     = var.timeout_seconds >= 1 && var.timeout_seconds <= 900
    error_message = "timeout_seconds must be between 1 and 900."
  }
}

variable "memory_mb" {
  type        = number
  description = "Lambda memory in MB."
  default     = 256
  nullable    = false

  validation {
    condition     = var.memory_mb >= 128 && var.memory_mb <= 10240
    error_message = "memory_mb must be between 128 and 10240."
  }
}

variable "environment" {
  type        = map(string)
  description = "Environment variables for the Lambda."
  default     = {}
  nullable    = false
}

variable "raw_bucket_name" {
  type        = string
  description = "Target S3 raw bucket name."
  nullable    = false
}

variable "raw_prefix" {
  type        = string
  description = "Prefix for raw writes (e.g., raw/)."
  default     = "raw/"
  nullable    = false

  validation {
    condition     = length(trimspace(var.raw_prefix)) > 0
    error_message = "raw_prefix cannot be empty."
  }
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN used by S3 default encryption (CMK). Needed for kms:Encrypt/GenerateDataKey."
  nullable    = false
}

variable "tags" {
  type        = map(string)
  description = "Tags for Lambda + IAM resources."
  default     = {}
  nullable    = false
}

