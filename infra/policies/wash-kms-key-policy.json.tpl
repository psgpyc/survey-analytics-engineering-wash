{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowRootPrivilege",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "AllowDecryptGrenerateKeySnowflakeAssumeRole",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${account_id}:role${path}${role_name}"
            },
            "Action": [
                "kms:Decrypt",
                "kms:GenerateDataKey",
                "kms:DescribeKey"
            ],
            "Resource": "*" 
        }
    ]
}
