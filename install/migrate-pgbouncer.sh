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
  echo "Migrating $SENTRY_CONFIG_PY to use PGBouncer"
  sed -i 's/"HOST": "postgres"/"HOST": "pgbouncer"/' "$SENTRY_CONFIG_PY"
  echo "Migrated $SENTRY_CONFIG_PY to use PGBouncer"
elif sed -n '/^DATABASES = {$/,/^}$/p' "$SENTRY_CONFIG_PY" | grep -q '"HOST": "pgbouncer"'; then
  echo "Found pgbouncer in $SENTRY_CONFIG_PY, I'm assuming you're good! :)"
else
  echo "⚠️ You don't have standard configuration for Postgres in $SENTRY_CONFIG_PY, skipping pgbouncer migration. I'm assuming you know what you're doing."
fi

echo "${_endgroup}"
