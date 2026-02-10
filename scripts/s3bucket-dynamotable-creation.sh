#!/bin/bash

aws s3api create-bucket \
  --bucket my-terraform-state-bucket-vijaya \
  --region eu-central-1 \
  --create-bucket-configuration LocationConstraint=eu-central-1

aws dynamodb create-table \
  --table-name terraform-locks-vijaya \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST