#!/usr/bin/env bash

source _unit-test/_test_setup.sh
source install/dc-detect-version.sh
source install/create-docker-volumes.sh

# Set the flag to apply automatic updates
export APPLY_AUTOMATIC_CONFIG_UPDATES=1

# Here we're just gonna test to run it multiple times
# Only to make sure it doesn't break
for i in $(seq 1 5); do
  source install/bootstrap-s3-nodestore.sh
done

s3_cmd="$dc exec seaweedfs s3cmd --access_key=sentry --secret_key=sentry --no-ssl --region=us-east-1 --host=seaweedfs:8333 --host-bucket=seaweedfs:8333/%(bucket)"

if ! $s3_cmd ls | grep -q "s3://nodestore"; then
  echo "Error: Nodestore bucket not found"
  exit 1
fi

test_file="s3-test-$(date +%s).txt"
$dc exec seaweedfs sh -c "echo 'sentry-test-content' > /tmp/$test_file"
$s3_cmd put "/tmp/$test_file" "s3://nodestore/$test_file" > /dev/null

file_count=$($s3_cmd ls "s3://nodestore/$test_file" | grep -c "$test_file")
if [[ "$file_count" -ne 1 ]]; then
  echo "Error: Test file was not found in the bucket."
  exit 1
fi

# Manual cleanup, otherwise `create-docker-volumes.sh` will fail
$dc down -v --remove-orphans

report_success
