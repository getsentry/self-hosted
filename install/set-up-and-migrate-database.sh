echo "${_group}Setting up / migrating database ..."

if [[ -z "${SKIP_SENTRY_MIGRATIONS:-}" ]]; then
  # Fixes https://github.com/getsentry/self-hosted/issues/2758, where a migration fails due to indexing issue
  $dc up --wait postgres

  os=$($dc exec postgres cat /etc/os-release | grep 'ID=debian')
  if [[ -z $os ]]; then
    echo "Postgres image debian check failed, exiting..."
    exit 1
  fi

  # Using django ORM to provide broader support for users with external databases
  $dcr web shell -c "
from django.db import connection

with connection.cursor() as cursor:
  cursor.execute('ALTER TABLE IF EXISTS sentry_groupedmessage DROP CONSTRAINT IF EXISTS sentry_groupedmessage_project_id_id_515aaa7e_uniq;')
  cursor.execute('DROP INDEX IF EXISTS sentry_groupedmessage_project_id_id_515aaa7e_uniq;')
"

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
