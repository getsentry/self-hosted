echo "${_group}Bootstrapping seaweedfs (node store)..."

$dc up --wait seaweedfs postgres
$dc exec seaweedfs apk add --no-cache s3cmd
s3cmd="$dc exec seaweedfs s3cmd"

bucket_list=$($s3cmd --access_key=sentry --secret_key=sentry --no-ssl --region=us-east-1 --host=localhost:8333 --host-bucket='localhost:8333/%(bucket)' ls)

if [[ $($bucket_list | tail -1 | awk '{print $3}') != 's3://nodestore' ]]; then
  # Only touch if no existing nodestore config is found
  if ! grep -q "SENTRY_NODESTORE" $SENTRY_CONFIG_PY; then
    nodestore_config=$(sed -n '/SENTRY_NODESTORE/,/[}]/{p}' sentry/sentry.conf.example.py)
    if [[ $($dc exec postgres psql -qAt -U postgres -c "select exists (select * from nodestore_node limit 1)") = "f" ]]; then
      nodestore_config=$(echo -e "$nodestore_config" | sed '$s/\}/    "read_through": True,\n    "delete_through": True,\n\}/')
    fi
    echo "$nodestore_config" >>$SENTRY_CONFIG_PY
  fi

  $s3cmd --access_key=foo --secret_key=bar --no-ssl --region=us-east-1 --host=localhost:8333 --host-bucket='localhost:8333/%(bucket)' mb s3://nodestore
else
  echo "Node store already exists, skipping..."
fi

echo "${_endgroup}"
