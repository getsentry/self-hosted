#!/bin/bash
set -e

if [[ -s /etc/sentry/requirements.txt ]] && grep -qv '^\s*$\|^\s*\#' /etc/sentry/requirements.txt; then
    echo "Installing additional dependencies..."
    pip install --user -r /etc/sentry/requirements.txt
    echo ""
fi

source /docker-entrypoint.sh
