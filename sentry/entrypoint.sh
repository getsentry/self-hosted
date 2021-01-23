#!/bin/bash
set -e

req_file="/etc/sentry/requirements.txt"
checksum_file="/data/custom-packages/.checksum"

if [[ -s "$req_file" ]] && [[ ! -f "$checksum_file" ]] || ! cat "$req_file" | grep '^[^#[:space:]]' | shasum -s -c "$checksum_file" 2>/dev/null; then
    echo "Installing additional dependencies..."
    pip install --user -r /etc/sentry/requirements.txt
    cat "$req_file" | grep '^[^#[:space:]]' | shasum > "$checksum_file"
    echo ""
fi

source /docker-entrypoint.sh
