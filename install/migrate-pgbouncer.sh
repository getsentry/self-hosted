echo "${_group}Migrating Postgres config to PGBouncer..."
# If users has this EXACT configuration on their `sentry.conf.py` file:
# ```python
# DATABASES = {
#     "default": {
#         "ENGINE": "sentry.db.postgres",
#         "NAME": "postgres",
#         "USER": "postgres",
#         "PASSWORD": "",
#         "HOST": "postgres",
#         "PORT": "",
#     }
# }
# ```
# We need to migrate it to this configuration:
# ```python
# DATABASES = {
#     "default": {
#         "ENGINE": "sentry.db.postgres",
#         "NAME": "postgres",
#         "USER": "postgres",
#         "PASSWORD": "",
#         "HOST": "pgbouncer",
#         "PORT": "",
#     }
# }
# ```

if sed -n '/^DATABASES = {$/,/^}$/p' "$SENTRY_CONFIG_PY" | grep -q '"HOST": "postgres"'; then
  apply_config_changes_pgbouncer=0
  if [[ -z "${APPLY_AUTOMATIC_CONFIG_UPDATES:-}" ]]; then
    echo
    echo "We added PGBouncer to the default Compose stack, and to use that"
    echo "you will need to modify your sentry.conf.py file contents."
    echo "Do you want us to make this change automatically for you?"
    echo

    yn=""
    until [ ! -z "$yn" ]; do
      read -p "y or n? " yn
      case $yn in
      y | yes | 1)
        export apply_config_changes_pgbouncer=1
        echo
        echo -n "Thank you."
        ;;
      n | no | 0)
        export apply_config_changes_pgbouncer=0
        echo
        echo -n "Alright, you will need to update your sentry.conf.py file manually before running 'docker compose up' or remove the $(pgbouncer) service if you don't want to use that."
        ;;
      *) yn="" ;;
      esac
    done

    echo
    echo "To avoid this prompt in the future, use one of these flags:"
    echo
    echo "  --apply-automatic-config-updates"
    echo "  --no-apply-automatic-config-updates"
    echo
    echo "or set the APPLY_AUTOMATIC_CONFIG_UPDATES environment variable:"
    echo
    echo "  APPLY_AUTOMATIC_CONFIG_UPDATES=1 to apply automatic updates"
    echo "  APPLY_AUTOMATIC_CONFIG_UPDATES=0 to not apply automatic updates"
    echo
    sleep 5
  fi

  if [[ "$APPLY_AUTOMATIC_CONFIG_UPDATES" == 1 || "$apply_config_changes_pgbouncer" == 1 ]]; then
    echo "Migrating $SENTRY_CONFIG_PY to use PGBouncer"
    sed -i 's/"HOST": "postgres"/"HOST": "pgbouncer"/' "$SENTRY_CONFIG_PY"
    echo "Migrated $SENTRY_CONFIG_PY to use PGBouncer"
  fi
elif sed -n '/^DATABASES = {$/,/^}$/p' "$SENTRY_CONFIG_PY" | grep -q '"HOST": "pgbouncer"'; then
  echo "Found pgbouncer in $SENTRY_CONFIG_PY, I'm assuming you're good! :)"
else
  echo "⚠️ You don't have standard configuration for Postgres in $SENTRY_CONFIG_PY, skipping pgbouncer migration. I'm assuming you know what you're doing."
  echo "   For more information about PGBouncer, refer to https://github.com/getsentry/self-hosted/pull/3884"
fi

echo "${_endgroup}"
