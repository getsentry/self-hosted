#!/usr/bin/env bash

source _unit-test/_test_setup.sh
source install/dc-detect-version.sh
$dcb --force-rm web

export SETUP_JS_SDK_ASSETS=1

source install/setup-js-sdk-assets.sh

sdk_files=$(docker compose run --no-deps --rm -v "sentry-nginx-www:/var/www" nginx ls -lah /var/www/js-sdk/)
sdk_tree=$(docker compose run --no-deps --rm -v "sentry-nginx-www:/var/www" nginx tree /var/www/js-sdk/ | tail -n 1)

# `sdk_files` should contains 2 lines, `7.*` and `8.*`
echo $sdk_files
total_directories=$(echo "$sdk_files" | grep -c '[78]\.[0-9]*\.[0-9]*$')
echo $total_directories
test "2" == "$total_directories"
echo "Pass"

# `sdk_tree` should outputs "2 directories, 10 files"
echo "$sdk_tree"
test "2 directories, 10 files" == "$(echo "$sdk_tree")"
echo "Pass"

report_success
