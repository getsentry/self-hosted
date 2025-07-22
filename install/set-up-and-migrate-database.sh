echo "${_group}Setting up / migrating database ..."

if [[ -z "${SKIP_SENTRY_MIGRATIONS:-}" ]]; then
  # Fixes https://github.com/getsentry/self-hosted/issues/2758, where a migration fails due to indexing issue
  start_service_and_wait_ready postgres

  os=$($dc exec postgres cat /etc/os-release | grep 'ID=debian')
  if [[ -z $os ]]; then
    echo "Postgres image debian check failed, exiting..."
    exit 1
  fi

  if [[ -n "${CI:-}" || "${SKIP_USER_CREATION:-0}" == 1 ]]; then
    $dcr web upgrade --noinput --create-kafka-topics
    echo ""
    echo "Did not prompt for user creation. Run the following command to create one"
    echo "yourself (recommended):"
    echo ""
    echo "  $dc_base run --rm web createuser"
    echo ""
  else
    $dcr web upgrade --create-kafka-topics
  fi
else
  echo "Skipped DB migrations due to SKIP_SENTRY_MIGRATIONS=$SKIP_SENTRY_MIGRATIONS"
fi
echo "${_endgroup}"
