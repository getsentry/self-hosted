#!/usr/bin/env bash
set -e

export MINIMIZE_DOWNTIME=0
export REPORT_SELF_HOSTED_ISSUES=1

# This file runs in https://github.com/getsentry/sentry/blob/fe4795f5eae9e0d7c33e0ecb736c9d1369535eca/docker/cloudbuild.yaml#L59
source install/_lib.sh
source install/detect-platform.sh
source install/dc-detect-version.sh
source install/error-handling.sh
source _integration-test/run.sh
