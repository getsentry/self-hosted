#!/usr/bin/env bash
set -e

# This file runs in https://github.com/getsentry/sentry/blob/fe4795f5eae9e0d7c33e0ecb736c9d1369535eca/docker/cloudbuild.yaml#L59

./_integration-test/run.sh
