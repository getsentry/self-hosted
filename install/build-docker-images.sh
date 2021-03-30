echo "${_group}Building and tagging Docker images ..."

echo ""
$dc build --force-rm
echo ""
echo "Docker images built."

echo "${_endgroup}"
