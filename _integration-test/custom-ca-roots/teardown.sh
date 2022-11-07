$dc rm -s -f -v fixture-custom-ca-roots
rm -f "$PROJECT_ROOT/certificates/test-custom-ca-roots.crt" "$PROJECT_ROOT/sentry/test-custom-ca-roots.py"
unset COMPOSE_FILE
