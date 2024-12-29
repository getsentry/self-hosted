echo "${_group}Bootstrapping and migrating Snuba ..."

$dcr snuba-api bootstrap --force

echo "${_endgroup}"
