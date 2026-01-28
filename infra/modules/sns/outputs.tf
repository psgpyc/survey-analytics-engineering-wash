output "topic_name" {
  description = "SNS topic name."
  value       = aws_sns_topic.this.name
}

output "topic_arn" {
  description = "SNS topic ARN."
  value       = aws_sns_topic.this.arn
}

output "topic_id" {
  description = "SNS topic ID (Terraform uses the ARN as the ID for SNS topics)."
  value       = aws_sns_topic.this.id
}

output "display_name" {
  description = "SNS topic display name."
  value       = aws_sns_topic.this.display_name
}

output "policy" {
  description = "SNS topic access policy JSON."
  value       = aws_sns_topic.this.policy
}

output "delivery_policy" {
  description = "SNS delivery policy JSON (if set)."
  value       = aws_sns_topic.this.delivery_policy
}