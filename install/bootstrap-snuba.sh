echo "${_group}Bootstrapping and migrating Snuba ..."

$dcr snuba-api bootstrap --no-migrate --force
$dcr snuba-api migrations migrate --force

echo "${_endgroup}"
