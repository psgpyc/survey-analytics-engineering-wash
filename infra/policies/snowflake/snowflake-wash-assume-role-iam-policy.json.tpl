{
    "Version": "2012-10-17",

    "Statement": [{

        "Sid": "AllowSnowflakeGetObject",
        "Effect": "Allow",
        "Action": [

            "s3:GetObject",
            "s3:GetObjectVersion"
        ],
        "Resource": [

            "${bucket_arn}/${prefix}/*"
        ]

    },
    {
        "Sid": "AllowSnowflakeListBucketAndLocation",
        "Effect": "Allow",
        "Action": [

            "s3:ListBucket",
            "s3:GetBucketLocation"
        ],
        "Resource": [
            "${bucket_arn}"
        ],
        "Condition": {
            "StringLike": {
                "s3:prefix": [
                    "${prefix}/*"
                ]
            }
        }

    },
    {
        "Sid": "AllowKmsForS3Only",
        "Effect": "Allow",
        "Action": [
            "kms:Decrypt",
            "kms:GenerateDataKey",
            "kms:DescribeKey"
        ],
        "Resource": "${kms_key_arn}",
        "Condition": {
            "StringEquals": {
            "kms:ViaService": "s3.eu-west-2.amazonaws.com"
            },
            "StringLike": {
            "kms:EncryptionContext:aws:s3:arn": "arn:aws:s3:::${bucket_name}/${prefix}/*"
            }
        }
    }
]
}