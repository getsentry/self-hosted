#!/usr/bin/env bash

set -euo pipefail
test "${DEBUG:-}" && set -x

function patch_file() {
  target="$1"
  content="$2"
  if [[ -f "$target" ]]; then
    echo "🙈 Patching $target ..."
    patch -p1 <"$content"
  else
    echo "🙊 Skipping $target ..."
  fi
}

