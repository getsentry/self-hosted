echo "${_group}Bootstrapping seaweedfs (node store)..."

$dc up --wait seaweedfs postgres
$dc exec -e "http_proxy=${http_proxy:-}" -e "https_proxy=${https_proxy:-}" -e "no_proxy=${no_proxy:-}" seaweedfs apk add --no-cache s3cmd
$dc exec seaweedfs mkdir -p /data/idx/
s3cmd="$dc exec seaweedfs s3cmd"

bucket_list=$($s3cmd --access_key=sentry --secret_key=sentry --no-ssl --region=us-east-1 --host=localhost:8333 --host-bucket='localhost:8333/%(bucket)' ls)

if [[ $(echo "$bucket_list" | tail -1 | awk '{print $3}') != 's3://nodestore' ]]; then
  apply_config_changes_nodestore=0
  # Only touch if no existing nodestore config is found
  if ! grep -q "SENTRY_NODESTORE" $SENTRY_CONFIG_PY; then
    if [[ -z "${APPLY_AUTOMATIC_CONFIG_UPDATES:-}" ]]; then
      echo
      echo "We want to migrate Nodestore backend from Postgres to S3 which will"
      echo "help reducing Postgres storage issues. In order to do that, we need"
      echo "to modify your sentry.conf.py file contents."
      echo "Do you want us to do it automatically for you?"
      echo

      yn=""
      until [ ! -z "$yn" ]; do
        read -p "y or n? " yn
        case $yn in
        y | yes | 1)
          export apply_config_changes_nodestore=1
          echo
          echo -n "Thank you."
          ;;
        n | no | 0)
          export apply_config_changes_nodestore=0
          echo
          echo -n "Alright, you will need to update your sentry.conf.py file manually before running 'docker compose up'."
          ;;
        *) yn="" ;;
        esac
      done

      echo
      echo "To avoid this prompt in the future, use one of these flags:"
      echo
      echo "  --apply-automatic-config-updates"
      echo "  --no-apply-automatic-config-updates"
      echo
      echo "or set the APPLY_AUTOMATIC_CONFIG_UPDATES environment variable:"
      echo
      echo "  APPLY_AUTOMATIC_CONFIG_UPDATES=1 to apply automatic updates"
      echo "  APPLY_AUTOMATIC_CONFIG_UPDATES=0 to not apply automatic updates"
      echo
      sleep 5
    fi

    if [[ "$APPLY_AUTOMATIC_CONFIG_UPDATES" == 1 || "$apply_config_changes_nodestore" == 1 ]]; then
      nodestore_config=$(sed -n '/SENTRY_NODESTORE/,/[}]/{p}' sentry/sentry.conf.example.py)
      if [[ $($dc exec postgres psql -qAt -U postgres -c "select exists (select * from nodestore_node limit 1)") = "f" ]]; then
        nodestore_config=$(echo -e "$nodestore_config" | sed '$s/\}/    "read_through": True,\n    "delete_through": True,\n\}/')
      fi
      echo "$nodestore_config" >>$SENTRY_CONFIG_PY
    fi
  fi

  $dc exec seaweedfs mkdir -p /data/idx/
  $s3cmd --access_key=sentry --secret_key=sentry --no-ssl --region=us-east-1 --host=localhost:8333 --host-bucket='localhost:8333/%(bucket)' mb s3://nodestore

  # XXX(aldy505): Should we refactor this?
  lifecycle_policy=$(
    cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<LifecycleConfiguration>
    <Rule>
        <ID>Sentry-Nodestore-Rule</ID>
        <Status>Enabled</Status>
        <Filter></Filter>
        <Expiration>
            <Days>$SENTRY_EVENT_RETENTION_DAYS</Days>
        </Expiration>
    </Rule>
</LifecycleConfiguration>
EOF
  )
  $dc exec seaweedfs sh -c "printf '%s' '$lifecycle_policy' > /tmp/nodestore-lifecycle-policy.xml"
  $s3cmd --access_key=sentry --secret_key=sentry --no-ssl --region=us-east-1 --host=localhost:8333 --host-bucket='localhost:8333/%(bucket)' setlifecycle /tmp/nodestore-lifecycle-policy.xml s3://nodestore

  echo "Making sure the bucket lifecycle policy is all set up correctly..."
  $s3cmd --access_key=sentry --secret_key=sentry --no-ssl --region=us-east-1 --host=localhost:8333 --host-bucket='localhost:8333/%(bucket)' getlifecycle s3://nodestore
else
  echo "Node store already exists, skipping..."
fi

echo "${_endgroup}"
