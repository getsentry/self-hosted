#!/usr/bin/env bash

source _unit-test/_test_setup.sh
source install/dc-detect-version.sh
$dcb --force-rm web

export SETUP_JS_SDK_ASSETS=1
export SETUP_JS_SDK_KEEP_OLD_ASSETS=1

source install/setup-js-sdk-assets.sh

sdk_files=$(docker compose run --no-deps --rm -v "sentry-nginx-www:/var/www/js-sdk" nginx ls \-lah /var/www/js-sdk)
sdk_tree=$(docker compose run --no-deps --rm -v "sentry-nginx-www:/var/www/js-sdk" nginx tree /var/www/js-sdk | tail -n 1)

# `sdk_files` should contains 2 lines, `7.*` and `8.*`
test "2" == "$(echo "$sdk_files" | grep '[0-9]+$' | wc -l)"

# `sdk_tree` should outputs "3 directories, 10 files"
test "3 directories, 10 files" == "$(echo "$sdk_tree")"

report_success
