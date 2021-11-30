echo "${_group}Setting up / migrating database ..."

if [[ -n "${CI:-}" || "${SKIP_USER_PROMPT:-0}" == 1 ]]; then
  $dcr web upgrade --noinput
  echo ""
  echo "Did not prompt for user creation due to non-interactive shell."
  echo "Run the following command to create one yourself (recommended):"
  echo ""
  echo "  docker compose run --rm web createuser"
  echo ""
else
  $dcr web upgrade
fi

echo "${_endgroup}"
