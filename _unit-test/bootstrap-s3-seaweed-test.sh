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

report_success
