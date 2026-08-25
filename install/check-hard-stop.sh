# The idea of this file is to prevent users from skipping a hard stop.
# This is done by creating a file in /var/run/sentry-hard-stop (or anything set
# in HARD_STOP_FILE) and checking for its existence before. If the file exists,
# we assume (and trust) that it's the latest version of the self-hosted sentry
# version, and no further check (git tag, values on `.env` ) would be done.
# Otherwise, we assume either this is the first installation, or the first
# time after this file is being written, and write into that file (by reading
# either the Git tag or values on `.env` or `.env.custom`).
#
# If the "reading" part fails anyway, we would skip this process and continue
# with the installation.
#
# If the user skipped a hard stop, we would halt the installation (or maybe,
# cancel it altogether), and ask for confirmation.
#
# This bit is written by a human.

echo "${_group}Checking for hard stop ... "

latest_version_file=${HARD_STOP_FILE:-"/var/run/sentry-hard-stop"}
# This should be a bash array string, and should be equivalent with the list
# on https://develop.sentry.dev/self-hosted/releases/#hard-stops
hard_stops=("9.1.2" "21.5.0" "21.6.3" "23.6.2" "23.11.0" "24.8.0" "25.5.1" "26.5.0" "26.7.0")

_write_latest_version() {
  echo "$1" >"$latest_version_file"
}

# Helper function to parse version components
# BASH_REMATCH requires Bash 3.0+
_parse_version_components() {
  local ver="$1"
  if [[ $ver =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.-]*)?(\+[0-9A-Za-z.-]*)?$ ]]; then
    echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]} ${BASH_REMATCH[4]#-} ${BASH_REMATCH[5]#+}"
  else
    echo ""
  fi
}

# Compare two calver versions
# Usage: compare_calver "1.2.3" "1.2.4"
# Returns: -1 if first < second, 0 if equal, 1 if first > second
#
# This bit is written by Claude Haiku 4.5.
compare_calver() {
  local v1="$1"
  local v2="$2"

  if [[ -z "$v1" ]] || [[ -z "$v2" ]]; then
    echo -e "ERROR: Invalid CalVer format" >&2
    return 2
  fi

  # Remove leading 'v' if present
  v1="${v1#v}"
  v2="${v2#v}"

  # Extract components
  local parsed1=$(_parse_version_components "$v1")
  local parsed2=$(_parse_version_components "$v2")

  if [[ -z "$parsed1" ]] || [[ -z "$parsed2" ]]; then
    echo -e "ERROR: Invalid CalVer format" >&2
    return 2
  fi

  # Compare major.minor.patch
  local arr1=($parsed1)
  local arr2=($parsed2)

  if ((arr1[0] > arr2[0])); then
    return 1
  elif ((arr1[0] < arr2[0])); then
    return -1
  fi

  if ((arr1[1] > arr2[1])); then
    return 1
  elif ((arr1[1] < arr2[1])); then
    return -1
  fi

  if ((arr1[2] > arr2[2])); then
    return 1
  elif ((arr1[2] < arr2[2])); then
    return -1
  fi

  # Compare prerelease versions (versions without prerelease > versions with prerelease)
  local pre1="${arr1[3]}"
  local pre2="${arr2[3]}"

  if [[ -z "$pre1" ]] && [[ -n "$pre2" ]]; then
    return 1 # v1 > v2 (release > prerelease)
  elif [[ -n "$pre1" ]] && [[ -z "$pre2" ]]; then
    return -1 # v1 < v2 (prerelease < release)
  elif [[ -n "$pre1" ]] && [[ -n "$pre2" ]]; then
    if [[ "$pre1" > "$pre2" ]]; then
      return 1
    elif [[ "$pre1" < "$pre2" ]]; then
      return -1
    fi
  fi

  return 0 # Equal
}

# Acquire the new version. This is done by reading `.env` / `.env.custom`
# for Docker image tags; or by reading the Git tag for the current commit
declare new_version
# if `.env.custom` exists, prioritize it over `.env`
if [[ -f ".env.custom" ]]; then
  source .env.custom
  new_version=$(grep -E '^SENTRY_IMAGE=' .env.custom | sed 's/^.*=//' | cut -d: -f2)
fi

if [[ -z "$new_version" ]]; then
  new_version=$(grep -E '^SENTRY_IMAGE=' .env | sed 's/^.*=//' | cut -d: -f2)
fi

if [[ -z "$new_version" ]]; then
  # Check whether `git` exists as a command, and `.git` directory exists
  if [[ -n "$(command -v git)" ]] && [[ -d "../.git" ]]; then
    # Get the latest tag from the repository
    new_version=$(git describe --tags --abbrev=0)
  fi
fi

# If the `new_version` is still empty, we emit a warning that
# they're on their own
if [[ -z "$new_version" ]]; then
  echo "--------------------------------------------------------------------------------"
  echo "WARNING: Could not determine the current version of the self-hosted Sentry"
  echo "to perform a hard stop check. Assuming you know what you're doing. Good luck."
  echo "--------------------------------------------------------------------------------"
  echo "${_endgroup}"
  (exit 0) # Should not exit the entire `install` process.
fi

# If the `new_version` is nightly, we emit a different warning.
# This is for fun.
if [[ "$new_version" == "nightly" ]]; then
  echo "--------------------------------------------------------------------------------"
  echo "WARNING: Hello, dear brave traveler. You are installing the nightly version."
  echo "The hard stop check is skipped for this version. We wish you a safe journey."
  echo "Good luck."
  echo "--------------------------------------------------------------------------------"
  echo "${_endgroup}"
  (exit 0)
fi

# Acquire the current version. Read the file.
declare current_version
if [[ -f "$latest_version_file" ]]; then
  current_version=$(cat "$latest_version_file")
fi

# We perform some checks if the `current_version` is not empty.
if [[ -n "$current_version" ]]; then
  # We iterate over the list of hard stops, and check whether the current
  # version is below any of them.
  for hard_stop in "${hard_stops[@]}"; do
    compare_result=$(compare_calver "$current_version" "$hard_stop")
    if [[ "$compare_result" == 0 ]]; then
      # equal, this is correct, they're visiting a hard stop
      _write_latest_version "$new_version"
      echo "${_endgroup}"
      (exit 0)
    elif [[ "$compare_result" == 1 ]]; then
      # the current version is greater than the current hard stop loop, we continue
      continue
    elif [[ "$compare_result" == 2 ]]; then
      # invalid version, we exit
      echo -e "ERROR: Invalid version in $latest_version_file"
      exit 1
    fi

    # the current version is less than the current hard stop loop
    # we alert the user and provide a confirmation
    echo "--------------------------------------------------------------------------------"
    echo
    echo "WARNING: Your new version ($new_version) will skip a required hard stop of $hard_stop."
    echo "It is recommended to stop the current installation, and go through the hard stop first."
    echo "Otherwise, you may encounter unexpected behaviors, such as migration failures, or data loss."
    echo
    echo "For future reference, please visit https://develop.sentry.dev/self-hosted/releases/#hard-stops"
    echo
    echo "Do you wish to continue? [y/N]"
    read -r confirmation

    if [[ "$confirmation" == "y" ]]; then
      _write_latest_version "$new_version"
      echo "${_endgroup}"
      (exit 0)
    else
      echo "Canceled. 😅"
      exit 1
    fi
  done
else
  # If the `current_version` is empty (or the file does not exists), we assume
  # this is a new installation.
  echo "Self-hosted Sentry version tracking file not found. No hard stop check is needed."
  _write_latest_version "$new_version"
fi

echo "${_endgroup}"
