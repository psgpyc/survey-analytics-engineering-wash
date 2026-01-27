variable "alias_name" {
  description = "KMS alias name (without 'alias/'). Example: wash-raw"
  type        = string

  validation {
    condition     = trimspace(var.alias_name) != "" && can(regex("^[A-Za-z0-9/_-]+$", var.alias_name))
    error_message = "alias_name must be non-empty and only contain letters/numbers plus '/', '_', '-'."
  }
}

variable "kms_key_policy" {
  description = "KMS key policy JSON (pass via templatefile())."
  type        = string

  validation {
    condition     = can(jsondecode(var.kms_key_policy))
    error_message = "kms_key_policy must be valid JSON."
  }
}

variable "description" {
  description = "Optional key description."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for key + alias."
  type        = map(string)
  default     = {}
}

variable "enable_key_rotation" {
  description = "Annual automatic rotation."
  type        = bool
  default     = true
}

variable "deletion_window_in_days" {
  description = "Days before a scheduled key deletion is final (7–30)."
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "deletion_window_in_days must be between 7 and 30."
  }
}

variable "multi_region" {
  description = "Set true only if you need a multi-region key."
  type        = bool
  default     = false
}

variable "key_usage" {
  description = "Usually ENCRYPT_DECRYPT for SSE-KMS."
  type        = string
  default     = "ENCRYPT_DECRYPT"

  validation {
    condition     = contains(["ENCRYPT_DECRYPT", "SIGN_VERIFY", "GENERATE_VERIFY_MAC"], var.key_usage)
    error_message = "key_usage must be ENCRYPT_DECRYPT, SIGN_VERIFY, or GENERATE_VERIFY_MAC."
  }
}

variable "customer_master_key_spec" {
  description = "Usually SYMMETRIC_DEFAULT for SSE-KMS."
  type        = string
  default     = "SYMMETRIC_DEFAULT"

  validation {
    condition = contains([
      "SYMMETRIC_DEFAULT",
      "RSA_2048", "RSA_3072", "RSA_4096",
      "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521",
      "ECC_SECG_P256K1",
      "HMAC_224", "HMAC_256", "HMAC_384", "HMAC_512"
    ], var.customer_master_key_spec)
    error_message = "customer_master_key_spec must be a valid KMS spec (use SYMMETRIC_DEFAULT for SSE-KMS)."
  }
}