echo "${_group}Ensuring Relay credentials ..."

RELAY_CONFIG_YML="../relay/config.yml"
RELAY_CREDENTIALS_JSON="../relay/credentials.json"

ensure_file_from_example $RELAY_CONFIG_YML

if [[ -f "$RELAY_CREDENTIALS_JSON" ]]; then
  echo "$RELAY_CREDENTIALS_JSON already exists, skipped creation."
else

  # There are a couple gotchas here:
  #
  # 1. We need to use a tmp file because if we redirect output directly to
  #    credentials.json, then the shell will create an empty file that relay
  #    will then try to read from (regardless of options such as --stdout or
  #    --overwrite) and fail because it is empty.
  #
  # 2. We pull relay:nightly before invoking `run relay credentials generate`
  #    because an implicit pull under the run causes extra stdout that results
  #    in a garbage credentials.json.
  #
  # 3. We need to use -T to ensure that we receive output on Docker Compose
  #    1.x and 2.2.3+ (funny story about that ... ;). Note that the long opt
  #    --no-tty doesn't exist in Docker Compose 1.

  $dc pull relay
  creds="$dcr --no-deps -T relay credentials"
  $creds generate --stdout > "$RELAY_CREDENTIALS_JSON".tmp
  mv "$RELAY_CREDENTIALS_JSON".tmp "$RELAY_CREDENTIALS_JSON"
  if ! grep -q Credentials <($creds show); then
    # Let's fail early if creds failed, to make debugging easier.
    echo "Failed to create relay credentials in $RELAY_CREDENTIALS_JSON."
    echo "--- credentials.json v ---------------------------------------"
    cat -v "$RELAY_CREDENTIALS_JSON" || true
    echo "--- credentials.json ^ ---------------------------------------"
    exit 1
  fi
  echo "Relay credentials written to $RELAY_CREDENTIALS_JSON."
fi

echo "${_endgroup}"
