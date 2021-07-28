#!/usr/bin/env bash
$dc rm -s -f -v fixture-custom-ca-roots
rm -f ../certificates/test-custom-ca-roots.crt ../sentry/test-custom-ca-roots.py
unset COMPOSE_FILE
