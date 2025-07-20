echo "${_group}Bootstrapping blob-storage (node store)..."

$dc up --wait blob-storage postgres
s3_cli="$dcr minio-cli mc"

# XXX(aldy505): I'm stuck here. I don't think this would work.
if [[ $($s3_cli ls BLOB/ | tail -1 | awk '{print $1}') != 'nodestore' ]]; then
  # Only touch if no existing nodestore config is found
  if ! grep -q "SENTRY_NODESTORE" $SENTRY_CONFIG_PY; then
    nodestore_config=$(sed -n '/SENTRY_NODESTORE/,/[}]/{p}' sentry/sentry.conf.example.py)
    if [[ $($dc exec postgres psql -qAt -U postgres -c "select exists (select * from nodestore_node limit 1)") = "f" ]]; then
      nodestore_config=$(echo -e "$nodestore_config" | sed '$s/\}/    "read_through": True,\n    "delete_through": True,\n\}/')
    fi
    echo "$nodestore_config" >>$SENTRY_CONFIG_PY
  fi

  $s3_cli mb BLOB/nodestore
  $s3_cli ilm rule add --expire-all-object-versions --expire-days ${SENTRY_EVENT_RETENTION_DAYS:-90} BLOB/nodestore
else
  echo "Node store already exists, skipping..."
fi

echo "${_endgroup}"
