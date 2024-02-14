echo "${_group}Setting up / migrating database ..."

# Fixes https://github.com/getsentry/self-hosted/issues/2758, where a migration fails due to indexing issue
$dc up -d postgres
# Wait for postgres
RETRIES=5
until $dc exec postgres psql -U postgres -c "select 1" >/dev/null 2>&1 || [ $RETRIES -eq 0 ]; do
  echo "Waiting for postgres server, $((RETRIES--)) remaining attempts..."
  sleep 1
done
$dc exec postgres psql -qAt -U postgres -c "ALTER TABLE IF EXISTS sentry_groupedmessage DROP CONSTRAINT IF EXISTS sentry_groupedmessage_project_id_id_515aaa7e_uniq;"
$dc exec postgres psql -qAt -U postgres -c "DROP INDEX IF EXISTS sentry_groupedmessage_project_id_id_515aaa7e_uniq;"

if [[ -n "${CI:-}" || "${SKIP_USER_CREATION:-0}" == 1 ]]; then
  $dcr web upgrade --noinput
  echo ""
  echo "Did not prompt for user creation. Run the following command to create one"
  echo "yourself (recommended):"
  echo ""
  echo "  $dc_base run --rm web createuser"
  echo ""
else
  $dcr web upgrade
fi

echo "${_endgroup}"
