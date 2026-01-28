output "queue_name" {
  description = "SQS queue name."
  value       = aws_sqs_queue.this.name
}

output "queue_url" {
  description = "SQS queue URL (used by consumers and some AWS APIs)."
  value       = aws_sqs_queue.this.id
}

output "queue_arn" {
  description = "SQS queue ARN (used for SNS subscriptions, IAM policies, and CloudWatch alarms)."
  value       = aws_sqs_queue.this.arn
}

output "queue_policy" {
  description = "Effective queue policy JSON attached to the queue."
  value       = aws_sqs_queue.this.policy
}

output "visibility_timeout_seconds" {
  description = "Configured visibility timeout (seconds)."
  value       = aws_sqs_queue.this.visibility_timeout_seconds
}

output "receive_wait_time_seconds" {
  description = "Configured long polling wait time (seconds)."
  value       = aws_sqs_queue.this.receive_wait_time_seconds
}

output "redrive_policy" {
  description = "Redrive policy JSON applied to the queue, if configured."
  value       = try(aws_sqs_queue_redrive_policy.this[1].redrive_policy, null)
}

output "redrive_allow_policy" {
  description = "Redrive allow policy JSON applied to the queue, if configured."
  value       = try(aws_sqs_queue_redrive_allow_policy.this[1].redrive_allow_policy, null)
}