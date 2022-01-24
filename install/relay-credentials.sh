echo "${_group}Generating Relay credentials ..."

RELAY_CONFIG_YML="../relay/config.yml"
RELAY_CREDENTIALS_JSON="../relay/credentials.json"
RELAY_DIRECTORY="../relay"

ensure_file_from_example $RELAY_CONFIG_YML

if [[ ! -f "$RELAY_CREDENTIALS_JSON" ]]; then

  # We need the ugly hack below as `relay generate credentials` tries to read
  # the config and the credentials even with the `--stdout` and `--overwrite`
  # flags and then errors out when the credentials file exists but not valid
  # JSON. We hit this case as we redirect output to the same config folder,
  # creating an empty credentials file before relay runs.

  $dcr \
    --no-deps \
    --volume "$(pwd)/$RELAY_DIRECTORY:/tmp/relay" \
    --entrypoint \"/bin/bash\" relay -c \
    "chown -R 10001 /tmp/relay"

  ls -l $RELAY_DIRECTORY

  $dcr \
    --no-deps -T \
    --volume "$(pwd)/$RELAY_DIRECTORY:/tmp/relay" \
    relay --config /tmp/relay credentials generate

  $dcr \
    --no-deps \
    --volume "$(pwd)/$RELAY_DIRECTORY:/tmp/relay" \
    --entrypoint \"/bin/bash\" relay -c \
    "chown -R $UID /tmp/relay"

  tr -d '[:space:]' < "$RELAY_CREDENTIALS_JSON" > "$RELAY_CREDENTIALS_JSON"-temp && mv "$RELAY_CREDENTIALS_JSON"-temp "$RELAY_CREDENTIALS_JSON"
  ls -l $RELAY_DIRECTORY
  more $RELAY_DIRECTORY/* | cat

  echo "Relay credentials written to $RELAY_CREDENTIALS_JSON"
fi

echo "${_endgroup}"
