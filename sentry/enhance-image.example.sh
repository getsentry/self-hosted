#!/bin/bash
set -euo pipefail

# Enhance the base $SENTRY_IMAGE with additional dependencies, plugins - see https://develop.sentry.dev/self-hosted/#enhance-sentry-image
# For example:
# apt-get update
# apt-get install -y gcc libsasl2-dev libldap2-dev libssl-dev
# pip install python-ldap
