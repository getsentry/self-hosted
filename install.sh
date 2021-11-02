#!/usr/bin/env bash
set -e
if [[ -n "$MSYSTEM" ]]; then
  echo "Seems like you are using an MSYS2-based system (such as Git Bash) which is not supported. Please use WSL instead.";
  exit 1
fi

source "$(dirname $0)/install/_lib.sh"  # does a `cd .../install/`, among other things

source parse-cli.sh
source error-handling.sh
source set-up-and-migrate-database.sh
