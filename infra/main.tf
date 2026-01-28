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