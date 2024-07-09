#!/bin/bash

# Set the script directory as working directory.
cd $(dirname $0)

# Detect docker and platform state.
source install/dc-detect-version.sh
source install/detect-platform.sh

# Define the Docker volume mapping.
VOLUME_MAPPING="${SENTRY_DOCKER_IO_DIR:-$HOME/.sentry/sentry-admin}:/sentry-admin"

# Custom help text paragraphs
HELP_TEXT_SUFFIX="
All file paths are relative to the 'web' docker container, not the host environment. To pass files
to/from the host system for commands that require it ('execfile', 'export', 'import', etc), you may
specify a 'SENTRY_DOCKER_IO_DIR' environment variable to mount a volume for file IO operations into
the host filesystem. The default value of 'SENTRY_DOCKER_IO_DIR' points to '~/.sentry/sentry-admin'
on the host filesystem. Commands that write files should write them to the '/sentry-admin' in the
'web' container (ex: './sentry-admin.sh export global /sentry-admin/my-export.json').
"

# Actual invocation that runs the command in the container.
invocation() {
  output=$($dc run -v "$VOLUME_MAPPING" --rm -T -e SENTRY_LOG_LEVEL=CRITICAL web "$@" 2>&1)
  echo "$output"
}

# Function to modify lines starting with `Usage: sentry` to say `Usage: ./sentry-admin.sh` instead.
rename_sentry_bin_in_help_output() {
  local output="$1"
  local help_prefix="$2"
  local usage_seen=false

  output=$(invocation "$@")

  echo -e "\n\n"

  while IFS= read -r line; do
    if [[ $line == "Usage: sentry"* ]] && [ "$usage_seen" = false ]; then
      echo -e "\n\n"
      echo "${line/sentry/./sentry-admin.sh}"
      echo "$help_prefix"
      usage_seen=true
    else
      if [[ $line == "Options:"* ]] && [ -n "$1" ]; then
        echo "$help_prefix"
      fi
      echo "$line"
    fi
  done <<<"$output"
}

# Check for the user passing ONLY the '--help' argument - we'll add a special prefix to the output.
if { [ "$1" = "help" ] || [ "$1" = "--help" ]; } && [ "$#" -eq 1 ]; then
  rename_sentry_bin_in_help_output "$(invocation "$@")" "$HELP_TEXT_SUFFIX"
  exit 0
fi

# Check for '--help' in other contexts.
for arg in "$@"; do
  if [ "$arg" = "--help" ]; then
    rename_sentry_bin_in_help_output "$(invocation "$@")"
    exit 0
  fi
done

# Help has not been requested - go ahead and execute the command.
echo -e "\n\n"
invocation "$@"
