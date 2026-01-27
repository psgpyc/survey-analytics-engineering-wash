variable "iam_role_name" {
  type        = string
  description = "Friendly name of the IAM role."

  validation {
    condition = (
      trimspace(var.iam_role_name) != "" &&
      can(regex("^[A-Za-z0-9+=,.@_-]+$", var.iam_role_name))
    )
    error_message = "iam_role_name cannot be empty and must match IAM role naming characters: A-Za-z0-9+=,.@_- (no spaces)."
  }
}

variable "iam_role_description" {
  type        = string
  description = "IAM role description."
  default     = null
}

variable "iam_role_assume_role_policy" {
  type        = string
  description = "Assume role policy JSON (string). Generated via templatefile()."

  validation {
    condition     = can(jsondecode(var.iam_role_assume_role_policy))
    error_message = "iam_role_assume_role_policy must be valid JSON."
  }
}

variable "iam_role_policy" {
  type        = string
  description = "IAM permissions policy JSON (string). Generated via templatefile()."

  validation {
    condition     = can(jsondecode(var.iam_role_policy))
    error_message = "iam_role_policy must be valid JSON."
  }
}

variable "iam_role_tags" {
  type        = map(string)
  description = "Tags applied to role and policy."
  default     = {
    domain      = "raw"
    environment = "dev"
  }
}

variable "iam_role_path" {
  type        = string
  description = "IAM role path."
  default     = "/wash/iam/role"
}

variable "iam_role_max_session_duration" {
  type        = number
  description = "Max session duration in seconds (3600–43200)."
  default     = 3600

  validation {
    condition     = var.iam_role_max_session_duration >= 3600 && var.iam_role_max_session_duration <= 43200
    error_message = "iam_role_max_session_duration must be between 3600 and 43200 seconds."
  }
}

variable "permissions_boundary_arn" {
  type        = string
  description = "Optional permissions boundary ARN."
  default     = null

  validation {
    condition     = var.permissions_boundary_arn == null || can(regex("^arn:aws:iam::\\d{12}:policy/.+$", var.permissions_boundary_arn))
    error_message = "permissions_boundary_arn must be a valid IAM policy ARN or null."
  }
}

variable "iam_policy_name" {
  type        = string
  description = "Optional explicit IAM policy name. If null, defaults to <role_name>-policy."
  default     = null

  validation {
    condition     = var.iam_policy_name == null || can(regex("^[A-Za-z0-9+=,.@_-]+$", var.iam_policy_name))
    error_message = "iam_policy_name must match IAM policy naming characters: A-Za-z0-9+=,.@_- (no spaces)."
  }
}

variable "iam_policy_description" {
  type        = string
  description = "Optional description for the IAM policy."
  default     = null
}

variable "iam_policy_path" {
  type        = string
  description = "IAM policy path."
  default     = "/wash/iam/role/policy"
}