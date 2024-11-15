#!/usr/bin/env bash

source _unit-test/_test_setup.sh
source install/dc-detect-version.sh
$dcb --force-rm web

export SETUP_JS_SDK_ASSETS=1

source install/setup-js-sdk-assets.sh

sdk_files=$(docker compose run --no-deps --rm -v "sentry-nginx-www:/var/www" nginx ls -lah /var/www/js-sdk/)
sdk_tree=$(docker compose run --no-deps --rm -v "sentry-nginx-www:/var/www" nginx tree /var/www/js-sdk/ | tail -n 1)
non_empty_file_count=$(docker compose run --no-deps --rm -v "sentry-nginx-www:/var/www" nginx find /var/www/js-sdk/ -type f -size +1k | wc -l)

# `sdk_files` should contains 5 lines, '4.*', '5.*', '6.*', `7.*` and `8.*`
echo $sdk_files
total_directories=$(echo "$sdk_files" | grep -c '[45678]\.[0-9]*\.[0-9]*$')
echo $total_directories
test "5" == "$total_directories"
echo "Pass"

# `sdk_tree` should output "5 directories, 17 files"
echo "$sdk_tree"
test "5 directories, 17 files" == "$(echo "$sdk_tree")"
echo "Pass"

# Files should all be >1k (ensure they are not empty)
echo "Testing file sizes"
test "17" == "$non_empty_file_count"
echo "Pass"

report_success
