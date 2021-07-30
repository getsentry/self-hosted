#!/bin/bash
set -e

if [ "$(ls -A /usr/local/share/ca-certificates/)" ]; then
  update-ca-certificates
fi

req_file="/etc/sentry/requirements.txt"
plugins_dir="/data/custom-packages"
checksum_file="$plugins_dir/.checksum"

if [[ -s "$req_file" ]] && ! cat "$req_file" | grep '^[^#[:space:]]' | shasum -s -c "$checksum_file" 2>/dev/null; then
    echo "Installing additional dependencies..."
    mkdir -p "$plugins_dir"
    pip install --user -r "$req_file"
    cat "$req_file" | grep '^[^#[:space:]]' | shasum > "$checksum_file"
    echo ""
fi

source /docker-entrypoint.sh
