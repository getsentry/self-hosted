#!/usr/bin/env bash
fail=0
for test_file in ./install/*-test.sh; do
    $test_file
    if [ $? != 0 ]; then
        fail=1
    fi
done

exit $fail
