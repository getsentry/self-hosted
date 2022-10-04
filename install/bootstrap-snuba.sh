echo "${_group}Bootstrapping and migrating Snuba ..."

function bootstrap_snuba {
  $dcr snuba-api bootstrap --no-migrate --force
  $dcr snuba-api migrations migrate --force
}

bootstrap_snuba

echo "${_endgroup}"
