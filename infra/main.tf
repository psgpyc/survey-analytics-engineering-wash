data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "random_id" "bucket_suffix" {
    byte_length = 3
}

locals {
  bucket_name_global = "${var.bucket_name}-${random_id.bucket_suffix.hex}"
}

module "kms" {

    source = "./modules/kms"

    description = var.description

    alias_name = var.alias_name

    kms_key_policy = templatefile("./policies/wash-kms-key-policy.json.tpl", {

        account_id = data.aws_caller_identity.current.account_id
    })
}


module "s3" {

    source = "./modules/s3"

    bucket_name = local.bucket_name_global

    bucket_tags = var.bucket_tags

    bucket_force_destroy = var.bucket_force_destroy

    bucket_versioning_status = var.bucket_versioning_status

    current_v_lifecycle_rules = var.current_v_lifecycle_rules

    noncurrent_v_lifecycle_rules = var.noncurrent_v_lifecycle_rules

    sse_algorithm = var.sse_algorithm

    kms_master_key_id = module.kms.key_arn

    depends_on = [ module.kms ]

}


module "sns" {

    source = "./modules/sns"

    sns_topic_name = var.sns_topic_name

    sns_topic_display_name = var.sns_topic_display_name

    sns_delivery_policy = file("./policies/wash-sns-delivery-policy.json")

    sns_topic_policy = templatefile("./policies/wash-sns-resource-policy.json.tpl", {

        current_region = data.aws_region.current.id
        account_id = data.aws_caller_identity.current.account_id
        bucket_name = module.s3.bucket_name
        topic_name = var.sns_topic_name

    })

    sns_tags = var.sns_tags
  
}

module "sqs_dlq" {

    source = "./modules/sqs"

    sqs_name = var.sqs_dlq_name

    sqs_tags = var.sqs_dlq_tags

    sqs_policy = null

    redrive_policy = null

    redrive_allow_policy = templatefile("./policies/wash-sqs-redrive-allow-policy.json.tpl", {
        source_sqs_queue_arn = module.sqs_main.queue_arn

    })

}

module "sqs_main" {

    source = "./modules/sqs"

    sqs_name = var.sqs_main_name

    sqs_tags = var.sqs_main_tags

    sqs_policy = templatefile("./policies/wash-sqs-resource-policy.json.tpl", {
        region = data.aws_region.current.id
        account_id = data.aws_caller_identity.current.account_id
        queue_name = var.sqs_main_name
        sns_topic_name = module.sns.topic_name

    })

    redrive_policy = templatefile("./policies/wash-sqs-redrive-policy.json.tpl", {
        dlq_arn = module.sqs_dlq.queue_arn
        max_receive_count = 4
    })

    redrive_allow_policy = null
  
}

resource "aws_sns_topic_subscription" "this" {

    topic_arn = module.sns.topic_arn

    protocol = "sqs"

    endpoint = module.sqs_main.queue_arn

    raw_message_delivery = true

    depends_on = [ module.sns, module.sqs_main ]
  
}


resource "aws_s3_bucket_notification" "this" {
    
    bucket = module.s3.bucket_id

    topic {
        topic_arn = module.sns.topic_arn

        events = ["s3:ObjectCreated:*"]
        filter_prefix = "raw/"
        filter_suffix = ".json"
    }

    depends_on = [ 
        module.s3,
        module.sns,
        aws_sns_topic_subscription.this
     ]
  
}

module "wash_iam" {

    source = "./modules/iam"

    iam_role_name = var.iam_role_name

    iam_role_assume_role_policy = templatefile("./policies/wash-ingest-assume-role.json.tpl", {

        account_id = data.aws_caller_identity.current.account_id
        region = data.aws_region.current.id
        function_name = var.function_name
    })

    iam_role_policy = templatefile("./policies/wash-ingest-iam-role-policy.json.tpl", {

        bucket_name = module.s3.bucket_name
        bucket_prefix = "raw"
        kms_key_arn = module.kms.key_arn
    })
  
}



module "wash_lambda" {

    source = "./modules/lambda"

    raw_bucket_name = module.s3.bucket_name

    raw_prefix = var.raw_prefix

    kms_key_arn = module.kms.key_arn

    function_name = var.function_name

    handler = var.handler

    runtime = var.runtime

    lambda_iam_role = module.wash_iam.role_arn

    source_dir = "${path.root}/lambda_src"

    environment = {
        N_HOUSEHOLDS = "10"
        BAD_ROW_RATE = "0.12"
        LOG_LEVEL    = "INFO"
        RAW_BUCKET = module.s3.bucket_name
    }

    tags = {
        Project     = "wash"
        ManagedBy   = "terraform"
        Environment = "dev"
        Domain      = "raw"
    }

    depends_on = [ module.s3, module.kms, module.wash_iam ]
}


module "scheduler_iam" {

    source = "./modules/iam"

    iam_role_name = var.scheduler_iam_role_name

    iam_role_assume_role_policy = templatefile("./policies/wash-scheduler-assume-role.json.tpl", {

        account_id = data.aws_caller_identity.current.account_id
    })

    iam_role_policy = templatefile("./policies/wash-scheduler-iam-role-policy.json.tpl", {

        lambda_func_arn = module.wash_lambda.function_arn
    })
  
}


module "scheduler" {

    source = "./modules/eventbridge"

    name_prefix = var.name_prefix

    schedule_expression = var.schedule_expression

    lambda_function_arn = module.wash_lambda.function_arn

    scheduler_iam_role_arn = module.scheduler_iam.role_arn
  
}