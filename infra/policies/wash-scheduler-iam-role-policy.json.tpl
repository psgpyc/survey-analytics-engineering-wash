{
    "Version": "2012-10-17",

    "Statement": [{
        "Sid": "",
        "Effect": "Allow",

        "Action": [
            "lambda:InvokeFunction"
        ],

        "Resource": [
            "${lambda_func_arn}"
        ]

    }]
}