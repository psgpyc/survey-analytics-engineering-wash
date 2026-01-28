{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "",
    "Effect": "Allow",
    "Action": ["sqs:SendMessage"],
    "Principal": { "Service": "sns.amazonaws.com" },
    "Resource": ["arn:aws:sqs:${region}:${account_id}:${queue_name}"],
    "Condition": {
      "ArnEquals": { "aws:SourceArn": "arn:aws:sns:${region}:${account_id}:${sns_topic_name}" }
    }
  }]
}