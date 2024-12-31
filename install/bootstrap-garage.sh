echo "${_group}Bootstrapping garage (node store)..."

$dc up --wait garage
if [[ $($dc exec garage /garage bucket list | tail -1 | awk '{print $1}' != 'nodestore' )]]; then
  node_id = $(exec garage /garage status | tail -1 | awk '{print $1}')
  $dc exec garage /garage layout assign -z dc1 -c 100G "$node_id"
  $dc exec garage /garage layout apply --version 1

  $dc exec garage /garage bucket create nodestore
  key_info=$($dc exec garage /garage key create nodestore-key | head -3 | tail -2)
  key_id=$(echo "$key_info" | head -1 | awk '{print $1}')
  key_secret=$(echo "$key_info" | tail -1 | awk '{print $1}')

  $dc exec garage /garage bucket allow --read --write --owner nodestore --key nodestore-key

  sed -i -e "s/<GARAGE_KEY_ID>/$key_info/" $SENTRY_CONFIG_PY
  sed -i -e "s/<GARAGE_SECRET_KEY>/$key_secret/" $SENTRY_CONFIG_PY
  echo "Set Garage keys for SENTRY_NODESTORE_OPTIONS in $SENTRY_CONFIG_PY"
else
  echo "Node store already exists, skipping..."
fi

echo "${_endgroup}"
