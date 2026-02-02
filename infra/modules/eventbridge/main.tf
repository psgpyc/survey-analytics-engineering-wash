resource "aws_scheduler_schedule_group" "this" {

    name = "${var.name_prefix}-schedulers"
    tags = var.tags
  
}

resource "aws_scheduler_schedule" "this" {

  name       = "${var.name_prefix}-wash-scheduler"
  group_name = aws_scheduler_schedule_group.this.name

  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = var.schedule_timezone 

  state = var.enabled ? "ENABLED" : "DISABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = var.lambda_function_arn
    role_arn = var.scheduler_iam_role_arn
  }

  depends_on = [
    aws_scheduler_schedule_group.this
  ]
}