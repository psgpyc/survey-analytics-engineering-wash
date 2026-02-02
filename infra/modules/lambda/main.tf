data "archive_file" "this" {

    type        = "zip"
    source_dir  = var.source_dir
    output_path = "${path.module}/.build/${var.function_name}.zip"
}

resource "aws_lambda_function" "this" {

    function_name = var.function_name
    role          = var.lambda_iam_role

    runtime = var.runtime
    handler = var.handler

    filename         = data.archive_file.this.output_path
    source_code_hash = data.archive_file.this.output_base64sha256

    timeout      = var.timeout_seconds
    memory_size  = var.memory_mb

    environment {
        variables = merge(
        {
            RAW_BUCKET = var.raw_bucket_name
            RAW_PREFIX = var.raw_prefix
        },
        var.environment
        )

    }

    depends_on = [ data.archive_file.this ]
}