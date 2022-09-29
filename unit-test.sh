#!/usr/bin/env bash
fail=0
for test_file in ./_unit-test/*-test.sh; do
    echo "🙈 Running $test_file ..."
    $test_file
    if [ $? != 0 ]; then
        echo fail 👎
        fail=1
    fi
done

exit $fail
