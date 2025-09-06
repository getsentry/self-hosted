#!/usr/bin/env bash

source _unit-test/_test_setup.sh
source install/dc-detect-version.sh

source install/ensure-files-from-examples.sh
cp $SENTRY_CONFIG_PY /tmp/sentry_conf_py
# Set the flag to apply automatic updates
export APPLY_AUTOMATIC_CONFIG_UPDATES=1

# Declare expected content
expected_db_config=$(
  cat <<'EOF'
DATABASES = {
    "default": {
        "ENGINE": "sentry.db.postgres",
        "NAME": "postgres",
        "USER": "postgres",
        "PASSWORD": "",
        "HOST": "pgbouncer",
        "PORT": "",
    }
}
EOF
)

echo "Test 1 (pre 25.9.0 release)"
# Modify the `DATABASES = {` to the next `}` line, with:
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

# Create the replacement text in a temp file
cat >/tmp/sentry_conf_py_db_config <<'EOF'
DATABASES = {
    "default": {
        "ENGINE": "sentry.db.postgres",
        "NAME": "postgres",
        "USER": "postgres",
        "PASSWORD": "",
        "HOST": "postgres",
        "PORT": "",
    }
}
EOF

# Replace the block
sed -i '/^DATABASES = {$/,/^}$/{
  /^DATABASES = {$/r /tmp/sentry_conf_py_db_config
  d
}' $SENTRY_CONFIG_PY

# Clean up
rm /tmp/sentry_conf_py_db_config

source install/migrate-pgbouncer.sh

# Extract actual content
actual_db_config=$(sed -n '/^DATABASES = {$/,/^}$/p' $SENTRY_CONFIG_PY)

# Compare
if [ "$actual_db_config" = "$expected_db_config" ]; then
  echo "DATABASES section is correct"
else
  echo "DATABASES section does not match"
  echo "Expected:"
  echo "$expected_db_config"
  echo "Actual:"
  echo "$actual_db_config"
  exit 1
fi

# Reset the file
rm $SENTRY_CONFIG_PY
cp /tmp/sentry_conf_py $SENTRY_CONFIG_PY

echo "Test 2 (post 25.9.0 release)"
# Modify the `DATABASES = {` to the next `}` line, with:
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

# Create the replacement text in a temp file
cat >/tmp/sentry_conf_py_db_config <<'EOF'
DATABASES = {
    "default": {
        "ENGINE": "sentry.db.postgres",
        "NAME": "postgres",
        "USER": "postgres",
        "PASSWORD": "",
        "HOST": "pgbouncer",
        "PORT": "",
    }
}
EOF

# Replace the block
sed -i '/^DATABASES = {$/,/^}$/{
  /^DATABASES = {$/r /tmp/sentry_conf_py_db_config
  d
}' $SENTRY_CONFIG_PY

# Clean up
rm /tmp/sentry_conf_py_db_config

source install/migrate-pgbouncer.sh

# Extract actual content
actual_db_config=$(sed -n '/^DATABASES = {$/,/^}$/p' $SENTRY_CONFIG_PY)

# Compare
if [ "$actual_db_config" = "$expected_db_config" ]; then
  echo "DATABASES section is correct"
else
  echo "DATABASES section does not match"
  echo "Expected:"
  echo "$expected_db_config"
  echo "Actual:"
  echo "$actual_db_config"
  exit 1
fi

# Reset the file
rm $SENTRY_CONFIG_PY
cp /tmp/sentry_conf_py $SENTRY_CONFIG_PY

echo "Test 3 (custom postgres config)"
# Modify the `DATABASES = {` to the next `}` line, with:
# DATABASES = {
#     "default": {
#         "ENGINE": "sentry.db.postgres",
#         "NAME": "postgres",
#         "USER": "sentry",
#         "PASSWORD": "sentry",
#         "HOST": "postgres.internal",
#         "PORT": "5432",
#     }
# }

# Create the replacement text in a temp file
cat >/tmp/sentry_conf_py_db_config <<'EOF'
DATABASES = {
    "default": {
        "ENGINE": "sentry.db.postgres",
        "NAME": "postgres",
        "USER": "sentry",
        "PASSWORD": "sentry",
        "HOST": "postgres.internal",
        "PORT": "5432",
    }
}
EOF

# Replace the block
sed -i '/^DATABASES = {$/,/^}$/{
  /^DATABASES = {$/r /tmp/sentry_conf_py_db_config
  d
}' $SENTRY_CONFIG_PY

# Clean up
rm /tmp/sentry_conf_py_db_config

source install/migrate-pgbouncer.sh

# Extract actual content
actual_db_config=$(sed -n '/^DATABASES = {$/,/^}$/p' $SENTRY_CONFIG_PY)

# THe file should NOT be modified
if [ "$actual_db_config" = "$expected_db_config" ]; then
  echo "DATABASES section SHOULD NOT be modified"
  echo "Expected:"
  echo "$expected_db_config"
  echo "Actual:"
  echo "$actual_db_config"
  exit 1
else
  echo "DATABASES section is correct"
fi

# Remove the file
rm $SENTRY_CONFIG_PY /tmp/sentry_conf_py

report_success
