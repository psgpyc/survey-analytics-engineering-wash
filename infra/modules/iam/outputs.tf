output "role_name" {
  description = "IAM role name."
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "IAM role ARN."
  value       = aws_iam_role.this.arn
}

output "role_id" {
  description = "IAM role stable identifier."
  value       = aws_iam_role.this.id
}

output "policy_name" {
  description = "IAM policy name."
  value       = aws_iam_policy.this.name
}

output "policy_arn" {
  description = "IAM policy ARN."
  value       = aws_iam_policy.this.arn
}

output "policy_id" {
  description = "IAM policy ID."
  value       = aws_iam_policy.this.id
}
