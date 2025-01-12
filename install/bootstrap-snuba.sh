echo "${_group}Bootstrapping and migrating Snuba ..."

if [[ -z "${SKIP_DB_MIGRATIONS:-}" ]]; then
  $dcr snuba-api bootstrap --force
else
  echo "Skipped DB migrations due to SKIP_DB_MIGRATIONS=$SKIP_DB_MIGRATIONS"
fi

echo "${_endgroup}"
