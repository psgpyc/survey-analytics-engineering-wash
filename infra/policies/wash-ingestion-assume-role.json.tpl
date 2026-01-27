{
    "Version": "2012-10-17",
    
    "Statement": [{
        "Sid": "LambdaAssumeRoleWASH",

        "Effect": "Allow",
        "Principal": {
            "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole",
        "Condition": {
            "StringEquals": {
                "aws:SourceAccount": "${account_id}"
            }
        },
        "ArnLike": {
            "aws:SourceArn": [
                "arn:aws:lambda:${region}:${account_id}:function:${function_name}"
            ]
        }      
    }]
    
}