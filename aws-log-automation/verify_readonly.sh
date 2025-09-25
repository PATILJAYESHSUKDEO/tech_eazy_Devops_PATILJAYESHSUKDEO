#!/bin/bash

# Replace with your account ID and role ARN
ROLE_ARN="arn:aws:iam::<ACCOUNT_ID>:role/readonly-s3-role"
SESSION_NAME="readonly-test-session"

echo "Assuming role: $ROLE_ARN"
CREDENTIALS=$(aws sts assume-role \
  --role-arn "$ROLE_ARN" \
  --role-session-name "$SESSION_NAME")

if [ $? -ne 0 ]; then
  echo "Failed to assume role"
  exit 1
fi

export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS | jq -r '.Credentials.SessionToken')

# List the contents of the logs folder
BUCKET_NAME="your-bucket-name-here" # <- Replace with actual bucket name
aws s3 ls s3://${BUCKET_NAME}/logs/

# Unset temporary credentials
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
