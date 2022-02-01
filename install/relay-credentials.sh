echo "${_group}Generating Relay credentials ..."

RELAY_CONFIG_YML="../relay/config.yml"
RELAY_CREDENTIALS_JSON="../relay/credentials.json"

ensure_file_from_example $RELAY_CONFIG_YML

if [[ -f "$RELAY_CREDENTIALS_JSON" ]]; then
  echo "$RELAY_CREDENTIALS_JSON already exists, skipped creation."
else
  $dcr relay credentials generate
  if [[ -f "$RELAY_CREDENTIALS_JSON" ]]; then
    echo "Relay credentials written to $RELAY_CREDENTIALS_JSON."
  else
    echo "Failed to write relay credentials to $RELAY_CREDENTIALS_JSON."
    exit 2
  fi
fi

echo "${_endgroup}"
