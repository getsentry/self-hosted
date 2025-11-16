echo "${_group}Bootstrapping and migrating Snuba ..."

if [[ -z "${SKIP_SNUBA_MIGRATIONS:-}" ]]; then
  $dcr snuba-api bootstrap --force
else
  echo "Skipped DB migrations due to SKIP_SNUBA_MIGRATIONS=$SKIP_SNUBA_MIGRATIONS"
fi

echo "${_endgroup}"
