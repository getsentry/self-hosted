echo "${_group}Bootstrapping seaweedfs (node store)..."

$dc up --wait seaweedfs postgres
$dc exec seaweedfs apk add --no-cache s3cmd
$dc exec seaweedfs mkdir -p /data/idx/
s3cmd="$dc exec seaweedfs s3cmd"

bucket_list=$($s3cmd --access_key=sentry --secret_key=sentry --no-ssl --region=us-east-1 --host=localhost:8333 --host-bucket='localhost:8333/%(bucket)' ls)

if [[ $($bucket_list | tail -1 | awk '{print $3}') != 's3://nodestore' ]]; then
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
          export APPLY_AUTOMATIC_CONFIG_UPDATES=1
          echo
          echo -n "Thank you."
          ;;
        n | no | 0)
          export APPLY_AUTOMATIC_CONFIG_UPDATES=0
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

    if [[ "$APPLY_AUTOMATIC_CONFIG_UPDATES" == 1 ]]; then
      nodestore_config=$(sed -n '/SENTRY_NODESTORE/,/[}]/{p}' sentry/sentry.conf.example.py)
      if [[ $($dc exec postgres psql -qAt -U postgres -c "select exists (select * from nodestore_node limit 1)") = "f" ]]; then
        nodestore_config=$(echo -e "$nodestore_config" | sed '$s/\}/    "read_through": True,\n    "delete_through": True,\n\}/')
      fi
      echo "$nodestore_config" >>$SENTRY_CONFIG_PY
    fi
  fi

  $dc exec seaweedfs mkdir -p /data/idx/
  $s3cmd --access_key=sentry --secret_key=sentry --no-ssl --region=us-east-1 --host=localhost:8333 --host-bucket='localhost:8333/%(bucket)' mb s3://nodestore
else
  echo "Node store already exists, skipping..."
fi

echo "${_endgroup}"
