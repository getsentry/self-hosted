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

# This should be a bash array string, and should be equivalent with the list
# on https://develop.sentry.dev/self-hosted/releases/#hard-stops
mapfile -t hard_stops < <(cat hard-stop.json | $jq -r '.hard_stops[]')

# Acquire the new version. This is done by reading `.env` / `.env.custom`
# for Docker image tags; or by reading the Git tag for the current commit
declare new_version=""
# if `.env.custom` exists, prioritize it over `.env`
if [[ -f ".env.custom" ]]; then
  new_version=$(grep -E '^SENTRY_IMAGE=' .env.custom | sed 's/^.*=//' | cut -d: -f2 || true)
fi

if [[ -z "$new_version" ]]; then
  new_version=$(grep -E '^SENTRY_IMAGE=' .env | sed 's/^.*=//' | cut -d: -f2 || true)
fi

if [[ -z "$new_version" ]]; then
  # Check whether `git` exists as a command, and `.git` directory exists
  if [[ -n "$(command -v git)" ]] && [[ -d "../.git" || -d "./.git" ]]; then
    # Get the latest tag from the repository
    new_version=$(git describe --tags --abbrev=0)
  fi
fi

# If the `new_version` is still empty, we emit a warning that
# they're on their own
if [[ -z "$new_version" ]]; then
  echo "--------------------------------------------------------------------------------"
  echo
  echo "WARNING: Could not determine the new version of the self-hosted Sentry"
  echo "to perform a hard stop check. Assuming you know what you're doing. Good luck."
  echo
  echo "--------------------------------------------------------------------------------"
fi

# If the `new_version` is empty, we cannot perform any hard stop check.
# This means the version detection failed across all methods. We already
# warned the user above, so we skip the check and continue with the installation.
if [[ -z "$new_version" ]]; then
  echo "Skipping hard stop check: unable to determine the new version."
elif [[ "$new_version" == "nightly" ]]; then
  # If the `new_version` is nightly, we emit a different warning.
  # This is for fun.
  echo "--------------------------------------------------------------------------------"
  echo
  echo "WARNING: Hello, dear brave traveler. You are installing the nightly version."
  echo "The hard stop check is skipped for this version. We wish you a safe journey."
  echo "Good luck."
  echo
  echo "--------------------------------------------------------------------------------"
elif [[ "${#new_version}" -gt 7 ]]; then
  # Invalid CalVer format. This might be an e2e test, or a user-provided version.
  echo "--------------------------------------------------------------------------------"
  echo
  echo "WARNING: Could not determine the new version of the self-hosted Sentry"
  echo "to perform a hard stop check due to invalid CalVer format."
  echo "Assuming you know what you're doing. Good luck."
  echo
  echo "--------------------------------------------------------------------------------"
else
  # We use snuba image because we don't rebuild the image, and it preserves
  current_version=$($dc images --format json | $jq -r 'first(.[] | select(.Repository == "ghcr.io/getsentry/snuba")) | .Tag')

  for hard_stop in "${hard_stops[@]}"; do
    # Let's say we have 3 variables in play here:
    #   current_version: 24.8.0
    #   new_version: 26.8.0
    #   hard_stop: 25.5.1
    # We don't want to allow the installation to continue if the hard stop is
    # greater than the new version. So the comparison logic here is:
    #
    #   if hard_stop > current_version:
    #     Check if new_version > hard_stop
    #     if new_version > hard_stop:
    #       User is NOT on the right track, they're skipping a hard stop.
    #       We should give them the warning prompt.
    #     else:
    #       User is on the right track.
    #       continue

    # the version in the image tag.
    # We also need to handle if those 3 variables are the same, because we
    # don't want to skip the hard stop if the new version is the same as the
    # hard stop.
    if [[ "$current_version" == "$new_version" ]]; then
      break
    elif vergte "$hard_stop" "$current_version"; then
      if vergte "$new_version" "$hard_stop"; then
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

        if [[ "$confirmation" != "y" ]]; then
          echo "Canceled. 😅"
          exit 1
        fi
    fi

    # NO BREAK HERE — keep looping to check remaining hard stops
  done
fi

echo "${_endgroup}"
