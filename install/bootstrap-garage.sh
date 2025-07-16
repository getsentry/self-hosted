echo "${_group}Bootstrapping garage (node store)..."

$dc up --wait garage postgres
garage="$dc exec garage /garage"

if [[ $($garage bucket list | tail -1 | awk '{print $1}') != 'nodestore' ]]; then
  node_id=$($garage status | tail -1 | awk '{print $1}')
  $garage layout assign -z local -c $GARAGE_STORAGE_SIZE "$node_id"
  $garage layout apply --version 1

  # Only touch if no existing nodestore config is found
  if ! grep -q "SENTRY_NODESTORE" $SENTRY_CONFIG_PY; then
    nodestore_config=$(sed -n '/SENTRY_NODESTORE/,/[}]/{p}' sentry/sentry.conf.example.py)
    if [[ $($dc exec postgres psql -qAt -U postgres -c "select exists (select * from nodestore_node limit 1)") = "f" ]]; then
      nodestore_config=$(echo -e "$nodestore_config" | sed '$s/\}/    "read_through": True,\n    "delete_through": True,\n\}/')
    fi
    echo "$nodestore_config" >>$SENTRY_CONFIG_PY
  fi

  $garage bucket create nodestore
  key_info=$($garage key create nodestore-key | head -3 | tail -2)
  echo "$key_info"
  key_id=$(echo "$key_info" | head -1 | awk '{print $3}')
  key_secret=$(echo "$key_info" | tail -1 | awk '{print $3}')

  $garage bucket allow --read --write --owner nodestore --key nodestore-key

  if grep -q "<GARAGE_KEY_ID>" $SENTRY_CONFIG_PY; then
    sed -i -e "s/<GARAGE_KEY_ID>/$key_id/" $SENTRY_CONFIG_PY
    sed -i -e "s/<GARAGE_SECRET_KEY>/$key_secret/" $SENTRY_CONFIG_PY
    echo "Set Garage keys for SENTRY_NODESTORE_OPTIONS in $SENTRY_CONFIG_PY"
  fi
else
  echo "Node store already exists, skipping..."
fi

echo "${_endgroup}"
