echo "${_group}Generating secret key ..."

# if grep -xq "system.secret-key: '!!changeme!!'" $SENTRY_CONFIG_YML; then
#   # This is to escape the secret key to be used in sed below
#   # Note the need to set LC_ALL=C due to BSD tr and sed always trying to decode
#   # whatever is passed to them. Kudos to https://stackoverflow.com/a/23584470/90297
#   SECRET_KEY=$(
#     export LC_ALL=C
#     head /dev/urandom | tr -dc "a-z0-9@#%^&*(-_=+)" | head -c 50 | sed -e 's/[\/&]/\\&/g'
#   )
#   sed -i -e 's/^system.secret-key:.*$/system.secret-key: '"'$SECRET_KEY'"'/' $SENTRY_CONFIG_YML
#   echo "Secret key written to $SENTRY_CONFIG_YML"
# fi
sed -i -e 's,^system.secret-key:.*$,system.secret-key: '"'$SECRET_KEY'"',' sentry/config.yml
sed -i -e 's,^auth-google.client-id:.*$,auth-google.client-id: '"'$GOOGLE_CLIENT_ID'"',' sentry/config.yml
sed -i -e 's,^auth-google.client-secret:.*$,auth-google.client-secret: '"'$GOOGLE_CLIENT_SECRET'"',' sentry/config.yml
sed -i -e 's,^slack.client-id:.*$,slack.client-id: '"'$SLACK_CLIENT_ID'"',' sentry/config.yml
sed -i -e 's,^slack.client-secret:.*$,slack.client-secret: '"'$SLACK_CLIENT_SECRET'"',' sentry/config.yml
sed -i -e 's,^slack.signing-secret:.*$,slack.signing-secret: '"'$SLACK_SIGNING_SECRET'"',' sentry/config.yml

echo "Secret key written to $SENTRY_CONFIG_YML"

echo "${_endgroup}"
