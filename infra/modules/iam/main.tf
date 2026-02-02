resource "aws_iam_role" "this" {

  name                 = var.iam_role_name
  description          = var.iam_role_description
  assume_role_policy   = var.iam_role_assume_role_policy
  path                 = var.iam_role_path
  max_session_duration = var.iam_role_max_session_duration
  permissions_boundary = var.permissions_boundary_arn

  tags = var.iam_role_tags

}

resource "aws_iam_policy" "this" {

  name        = var.iam_policy_name != null ? var.iam_policy_name : "${var.iam_role_name}-policy"
  description = var.iam_policy_description
  policy      = var.iam_role_policy
  path        = var.iam_policy_path

  tags = var.iam_role_policy_tags

  depends_on = [ aws_iam_role.this ]

}

resource "aws_iam_role_policy_attachment" "this" {

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn

  depends_on = [ aws_iam_role.this, aws_iam_policy.this ]
  
}