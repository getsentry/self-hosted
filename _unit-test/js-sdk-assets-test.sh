#!/usr/bin/env bash

source _unit-test/_test_setup.sh
source install/dc-detect-version.sh
$dcb --force-rm web
$dc pull nginx

export SETUP_JS_SDK_ASSETS=1

source install/setup-js-sdk-assets.sh

sdk_files=$($dcr --no-deps nginx ls -lah /var/www/js-sdk/)
sdk_tree=$($dcr --no-deps nginx tree /var/www/js-sdk/ | tail -n 1)
non_empty_file_count=$($dcr --no-deps nginx find /var/www/js-sdk/ -type f -size +1k | wc -l)

# `sdk_files` should contains 7 lines, '4.*', '5.*', '6.*', `7.*`, `8.*`, `9.*`, and `10.*`
echo $sdk_files
total_directories=$(echo "$sdk_files" | grep -c '[4-9|10]\.[0-9]*\.[0-9]*$')
echo $total_directories
test "7" == "$total_directories"
echo "Pass"

# `sdk_tree` should output "7 directories, 29 files"
echo "$sdk_tree"
test "7 directories, 29 files" == "$(echo "$sdk_tree")"
echo "Pass"

# Files should all be >1k (ensure they are not empty)
echo "Testing file sizes"
test "29" == "$non_empty_file_count"
echo "Pass"

# Files should be owned by the root user
echo "Testing file ownership"
directory_owners=$(echo "$sdk_files" | awk '$3=="root" { print $0 }' | wc -l)
echo "$directory_owners"
test "$directory_owners" == "9"
echo "Pass"

report_success
