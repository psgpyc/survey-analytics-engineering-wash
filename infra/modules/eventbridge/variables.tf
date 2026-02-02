variable "name_prefix" {
  type        = string
  description = "Prefix used for naming scheduler resources (e.g. 'wash-dev')."
}

variable "lambda_function_arn" {
  type        = string
  description = "Lambda function ARN to invoke."
}

variable "schedule_expression" {
  type        = string
  description = "EventBridge Scheduler expression: rate() or cron()."
}

variable "schedule_timezone" {
  type        = string
  description = "Timezone for schedule execution"
  default     = "Europe/London"
}

variable "enabled" {
  type        = bool
  description = "Enable/disable the schedule."
  default     = true
}

variable "scheduler_iam_role_arn" {
  type        = string
  description = "IAM Role ARN for scheduler"
  nullable = false

  validation {
    condition = (
        length(trimspace(var.scheduler_iam_role_arn)) > 0 
    ) 
    error_message = "IAM Role cannot be empty"
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to scheduler resources."
  default     = {}
}