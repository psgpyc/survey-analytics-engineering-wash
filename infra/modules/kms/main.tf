resource "aws_kms_key" "this" {

  description             = var.description
  enable_key_rotation     = var.enable_key_rotation
  deletion_window_in_days = var.deletion_window_in_days

  key_usage                = var.key_usage
  customer_master_key_spec = var.customer_master_key_spec
  multi_region             = var.multi_region

  tags = var.tags

}

resource "aws_kms_alias" "this" {

  name          = "alias/${var.alias_name}"

  target_key_id = aws_kms_key.this.key_id

}

resource "aws_kms_key_policy" "this" {

  key_id = aws_kms_key.this.id
  
  policy = var.kms_key_policy
  
}