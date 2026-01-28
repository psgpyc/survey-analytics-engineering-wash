resource "aws_sqs_queue" "this" {

    name = var.sqs_name

    visibility_timeout_seconds = var.visibility_timeout_seconds

    delay_seconds = var.delay_seconds

    max_message_size = var.max_message_size

    message_retention_seconds = var.message_retention_seconds

    receive_wait_time_seconds = var.receive_wait_time_seconds

    policy = var.sqs_policy

    tags = var.sqs_tags

}

resource "aws_sqs_queue_redrive_policy" "this" {

    count = var.redrive_policy != null ? 1: 0

    queue_url = aws_sqs_queue.this.id

    redrive_policy = var.redrive_policy
  
}

resource "aws_sqs_queue_redrive_allow_policy" "this" {

    count = var.redrive_allow_policy != null ? 1:0

    queue_url = aws_sqs_queue.this.id

    redrive_allow_policy = var.redrive_allow_policy
  
}

