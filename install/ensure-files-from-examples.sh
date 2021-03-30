echo "${_group}Ensuring files from examples ..."

ensure_file_from_example $SENTRY_CONFIG_PY
ensure_file_from_example $SENTRY_CONFIG_YML
ensure_file_from_example '../symbolicator/config.yml'
ensure_file_from_example '../sentry/requirements.txt'

echo "${_endgroup}"
