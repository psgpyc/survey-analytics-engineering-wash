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

            "${bucket_arn}/${prefix}"
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

    }
]
}