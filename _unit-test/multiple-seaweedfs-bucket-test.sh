#!/usr/bin/env bash

source _unit-test/_test_setup.sh
source install/dc-detect-version.sh
source install/create-docker-volumes.sh

start_service_and_wait_ready seaweedfs

$dcx seaweedfs apk add --no-cache s3cmd
s3cmd="$dc exec seaweedfs s3cmd"

# Create multiple buckets for testing
buckets=(bucket1 bucket2 bucket3)
for bucket in "${buckets[@]}"; do
  $s3cmd --access_key=sentry --secret_key=sentry --no-ssl --region=us-east-1 --host=localhost:8333 --host-bucket='localhost:8333/%(bucket)' mb s3://$bucket
done

# Verify that all buckets were created successfully
bucket_list=$($s3cmd --access_key=sentry --secret_key=sentry --no-ssl --region=us-east-1 --host=localhost:8333 --host-bucket='localhost:8333/%(bucket)' ls)
for bucket in "${buckets[@]}"; do
  if ! echo "$bucket_list" | grep -q "s3://$bucket"; then
    echo "Error: Bucket s3://$bucket was not created successfully."
    exit 1
  fi
done

# Can find "bucket2"
if ! echo "$bucket_list" | grep -q "s3://bucket2"; then
  echo "Error: Bucket s3://bucket2 was not found."
  exit 1
fi

# Can't find "bucket5", should not exist
if echo "$bucket_list" | grep -q "s3://bucket5"; then
  echo "Error: Bucket s3://bucket5 should not exist."
  exit 1
fi

report_success
