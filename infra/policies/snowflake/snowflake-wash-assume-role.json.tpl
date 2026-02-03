{
    "Version": "2012-10-17",
    "Statement": [{
        "Sid": "SnowflakeReaderAssumeRole",

        "Effect": "Allow",

        "Action": "sts:AssumeRole",

        "Principal": {
            "AWS": "${snowflake_iam_arn}"
        },
        "Condition": {
            "StringEquals": {
                "sts:ExternalId": "${snowflake_iam_external_id}"
            }
        }
    }]
}