echo "${_group}Bootstrapping garage (node store)..."

$dc up --wait garage
garage="$dc exec garage /garage"

if [[ $($garage bucket list | tail -1 | awk '{print $1}') != 'nodestore' ]]; then
  node_id=$($garage status | tail -1 | awk '{print $1}')
  $garage layout assign -z local -c $GARAGE_STORAGE_SIZE "$node_id"
  $garage layout apply --version 1

  $garage bucket create nodestore
  key_info=$($garage key create nodestore-key | head -3 | tail -2)
  echo "$key_info"
  key_id=$(echo "$key_info" | head -1 | awk '{print $3}')
  key_secret=$(echo "$key_info" | tail -1 | awk '{print $3}')

  $garage bucket allow --read --write --owner nodestore --key nodestore-key

  sed -i -e "s/<GARAGE_KEY_ID>/$key_id/" $SENTRY_CONFIG_PY
  sed -i -e "s/<GARAGE_SECRET_KEY>/$key_secret/" $SENTRY_CONFIG_PY

  echo "Set Garage keys for SENTRY_NODESTORE_OPTIONS in $SENTRY_CONFIG_PY"
else
  echo "Node store already exists, skipping..."
fi

echo "${_endgroup}"
