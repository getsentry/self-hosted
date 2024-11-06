#!/usr/bin/env bash

export REPORT_SELF_HOSTED_ISSUES=0 # will be over-ridden in the relevant test

FORCE_CLEAN=1 "./scripts/reset.sh"
fail=0
for test_file in _unit-test/*-test.sh; do
  if [ "$1" -a "$1" != "$test_file" ]; then
    echo "🙊 Skipping $test_file ..."
    continue
  fi
  echo "🙈 Running $test_file ..."
  $test_file
  exit_code=$?
  if [ $exit_code != 0 ]; then
    echo fail 👎 with exit code $exit_code
    fail=1
  fi
done

exit $fail
