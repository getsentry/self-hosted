#!/usr/bin/env bash
fail=0
# -perm +111 finds files with the executable bit set
test_files=$(find ./_unit-test/ -type f -perm +111)
for test_file in $test_files; do
    $test_file
    if [ $? != 0 ]; then
        fail=1
    fi
done

exit $fail
