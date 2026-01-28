variable "sqs_name" {
    type = string
    description = "SQS queue name. 1–80 characters. Allowed: alphanumeric, hyphen (-), underscore (_)."
    nullable = false

    validation {
      condition = (
        length(trimspace(var.sqs_name)) >= 1 
        && length(trimspace(var.sqs_name)) <= 80
        && can(regex("^[a-zA-Z0-9_-]+$", var.sqs_name))
      )
      error_message = "Queue names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 80 characters long"
    }
  
}

variable "visibility_timeout_seconds" {

    type = number
    description = "Visibility timeout for the queue. An integer from 0 to 43200 (12 hours)"
    nullable = false
    default = 60 # currently 1 minutes

    validation {
      condition = var.visibility_timeout_seconds >= 0 && var.visibility_timeout_seconds < 43200
      error_message = "visibility_timeout_seconds must be between 0 and 43200 seconds."
    }
  
}

variable "delay_seconds" {

    type = number
    description = "Time in seconds that the delivery of all messages in the queue will be delayed. An integer from 0 to 900 (15 minutes)"

    nullable = false
    default = 0

    validation {
      condition = var.delay_seconds >= 0 && var.delay_seconds <= 900
      error_message = "delay_seconds must be between 0 and 900 seconds."
    }
  
}

variable "max_message_size" {

    type = number
    description = "Limit of how many bytes a message can contain before Amazon SQS rejects it. An integer from 1024 bytes (1 KiB) up to 1048576 bytes (1024 KiB). The default for this attribute is 262144 (256 KiB)."
    nullable = false
    default = 262144

    validation {
      condition = var.max_message_size >= 1024 && var.max_message_size <= 1048576
      error_message = "max_message_size must be between 1024 and 1048576 bytes."
    }
}

variable "message_retention_seconds" {

    type = number
    description = "Number of seconds Amazon SQS retains a message. Integer representing seconds, from 60 (1 minute) to 1209600 (14 days). The default for this attribute is 345600 (4 days)."
    nullable = false
    default = 345600

    validation {
      condition = var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600
      error_message = "message_retention_seconds must be between 60 and 1209600 seconds."
    }
    
}

variable "receive_wait_time_seconds" {

    type = number
    description = "Time for which a ReceiveMessage call will wait for a message to arrive (long polling) before returning. An integer from 0 to 20 (seconds). The default for this attribute is 0"
    nullable = false
    default = 20

    validation {
      condition = var.receive_wait_time_seconds >= 0 && var.receive_wait_time_seconds <=20
      error_message = "receive_wait_time_seconds must be between 0 and 20 seconds."
    }
  
}

variable "sqs_tags" {

    type = map(string)
    description = "value"
    nullable = true
  
}

variable "sqs_policy" {

    type = string
    description = "value"
    nullable = true
    default = null

    validation {
      condition = (
        var.sqs_policy == null ? true 
        : (
            length(trimspace(var.sqs_policy)) > 0 
            && can(jsondecode(var.sqs_policy))
        )
      )
      error_message = "sqs_policy must be valid JSON"
    } 
}

variable "redrive_policy" {
    type = string
    description = "value"
    nullable = true

    validation {
      condition = (
        var.redrive_policy == null
        ? true
        : length(trimspace(var.redrive_policy)) > 0
            && can(jsondecode(var.redrive_policy))

      )
      error_message = "redrive_policy must be valid JSON"
    }
  
}

variable "redrive_allow_policy" {

    type = string
    description = "value"
    nullable = true

    validation {
        condition = (
        var.redrive_allow_policy == null
        ? true
        : length(trimspace(var.redrive_allow_policy)) > 0
            && can(jsondecode(var.redrive_allow_policy))

        )
        error_message = "redrive_allow_policy must be valid JSON"
        
    }
  
}