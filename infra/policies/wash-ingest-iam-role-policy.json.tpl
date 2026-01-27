{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowWriteOnlyToPrefix",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts"
            ],
            "Resource": [
                "arn:aws:s3:::${bucket_name}/${bucket_prefix}"
            ]
        },
        {
            "Sid": "AllowListBucketForSamePrefix",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource":[
                 "arn:aws:s3:::${bucket_name}/${bucket_prefix}"
            ]
        },
        {
            "Sid": "AllowKmsForS3encryption",
            "Effect": "Allow",
            "Action": [
                "kms:Encrypt",
                "kms:GenerateDataKey",
                "kms:DescribeKey"
            ],
            "Resource": "${kms_key_arn}",
            "Condition": {
                "StringLike": {
                    "kms:EncryptionContext:aws:s3:arn": "arn:aws:s3:::${bucket_name}/*"
                }

            }
        },
        {
            "Sid": "CloudWatchLogs",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}