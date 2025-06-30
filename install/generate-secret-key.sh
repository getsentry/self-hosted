echo "${_group}Generating secret key ..."

# Since June 2026, we moved the `system.secret-key` location to the `.env` file
# to provide a better secret management for users. The use case is they commit
# the `sentry/config.yml` file on a Git repository for backing up their settings
# or to have a IaC approach.
#
# We'll check if they have this on the `sentry/sentry.conf.py` file:
# ```py
# SENTRY_OPTIONS["system.secret-key"] = env("SENTRY_SYSTEM_SECRET_KEY", "!!changeme!!")
# ```
# If they do, we'll generate SENTRY_SYSTEM_SECRET_KEY on the `.env.custom` file.
# Creating the file if they don't have it.
#
# If they don't have it, we'll check on the `sentry/config.yml` file:
# ```yaml
# system.secret-key: '!!changeme!!'
# ```
if [ -f "$SENTRY_CONFIG_PY" ]; then
  if grep -xq "SENTRY_OPTIONS\[\"system.secret-key\"\] = env\(\"SENTRY_SYSTEM_SECRET_KEY\"\, \"!!changeme!!\"\)" $SENTRY_CONFIG_PY; then
    # Does `.env.custom` exist?
    if [ ! -f ".env.custom" ]; then
      echo "Creating .env.custom ..."
      touch ".env.custom"
    fi

    # Does SENTRY_SYSTEM_SECRET_KEY not exist on `.env.custom`?
    if ! grep -q "SENTRY_SYSTEM_SECRET_KEY=" ".env.custom"; then
      # Generate a new secret key
      SECRET_KEY=$(
        export LC_ALL=C
        head /dev/urandom | tr -dc "a-z0-9@#%^&*(-_=+)" | head -c 50 | sed -e 's/[\/&]/\\&/g'
      )
      echo "SENTRY_SYSTEM_SECRET_KEY=\"$SECRET_KEY\"" >>".env.custom"
      echo "Secret key written to .env.custom"
    fi
  fi
elif grep -xq "system.secret-key: '!!changeme!!'" $SENTRY_CONFIG_YML; then
  # This is to escape the secret key to be used in sed below
  # Note the need to set LC_ALL=C due to BSD tr and sed always trying to decode
  # whatever is passed to them. Kudos to https://stackoverflow.com/a/23584470/90297
  SECRET_KEY=$(
    export LC_ALL=C
    head /dev/urandom | tr -dc "a-z0-9@#%^&*(-_=+)" | head -c 50 | sed -e 's/[\/&]/\\&/g'
  )
  sed -i -e 's/^system.secret-key:.*$/system.secret-key: '"'$SECRET_KEY'"'/' $SENTRY_CONFIG_YML
  echo "Secret key written to $SENTRY_CONFIG_YML"
fi

echo "${_endgroup}"
