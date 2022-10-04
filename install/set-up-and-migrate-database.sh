echo "${_group}Setting up / migrating database ..."

function setup_and_migrate_database {
  if [[ -n ${CI:-} || ${SKIP_USER_CREATION:-0} == 1 ]]; then
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
}

setup_and_migrate_database

echo "${_endgroup}"
