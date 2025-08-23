# Guard this file behind SETUP_PGBOUNCER_MIGRATION
if [ "$SETUP_PGBOUNCER_MIGRATION" == "1" ]; then
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

  # Found this from https://stackoverflow.com/a/2686705/3153224
  if pcregrep -M '^DATABASES[[:space:]]*=[[:space:]]*{\n[[:space:]]*"default"[[:space:]]*:[[:space:]]*{\n[[:space:]]*"ENGINE"[[:space:]]*:[[:space:]]*"sentry.db.postgres",\n[[:space:]]*"NAME"[[:space:]]*:[[:space:]]*"postgres",\n[[:space:]]*"USER"[[:space:]]*:[[:space:]]*"postgres",\n[[:space:]]*"PASSWORD"[[:space:]]*:[[:space:]]*"",\n[[:space:]]*"HOST"[[:space:]]*:[[:space:]]*"postgres",\n[[:space:]]*"PORT"[[:space:]]*:[[:space:]]*"",\n[[:space:]]*}\n[[:space:]]*}' "$SENTRY_CONFIG_PY"; then
    echo "Migrating $SENTRY_CONFIG_PY to use PGBouncer"
    sed -i 's/"HOST": "postgres"/"HOST": "pgbouncer"/' "$SENTRY_CONFIG_PY"
    echo "Migrated $SENTRY_CONFIG_PY to use PGBouncer"
  # See if we already have pgbouncer set. If it is, then we just say "ok you're good".
  elif pcregrep -M '^DATABASES[[:space:]]*=[[:space:]]*{\n[[:space:]]*"default"[[:space:]]*:[[:space:]]*{\n[[:space:]]*"ENGINE"[[:space:]]*:[[:space:]]*"sentry.db.postgres",\n[[:space:]]*"NAME"[[:space:]]*:[[:space:]]*"postgres",\n[[:space:]]*"USER"[[:space:]]*:[[:space:]]*"postgres",\n[[:space:]]*"PASSWORD"[[:space:]]*:[[:space:]]*"",\n[[:space:]]*"HOST"[[:space:]]*:[[:space:]]*"pgbouncer",\n[[:space:]]*"PORT"[[:space:]]*:[[:space:]]*"",\n[[:space:]]*}\n[[:space:]]*}' "$SENTRY_CONFIG_PY"; then
    echo "Found pgbouncer in $SENTRY_CONFIG_PY, I'm assuming you're good! :)"
  else
    echo "⚠️ You don't have standard configuration for Postgres in $SENTRY_CONFIG_PY, skipping pgbouncer migration. I'm assuming you know what you're doing."
  fi

  echo "${_endgroup}"
fi
