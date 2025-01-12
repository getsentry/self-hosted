#!/usr/bin/env bash

# Kafka plays a very significant role on Sentry's infrastructure, from ingesting
# to processing events until they end up on ClickHouse or filesystem for permanent
# storage. Since Kafka may require a significant amount of resources on the server
# it may make sense to split it from the main Sentry installation. This can be
# particularly appealing if you already have a managed Kafka cluster set up.
#
# Sentry (the company) itself uses a Kafka cluster on production with a very
# tailored setup, especially for authentication. Some Kafka configuration options
# (such as `SASL_SSL` security protocol) might not be available for some services,
# but since everything is open source, you are encouraged to contribute to
# implement those missing things.
#
# If you are using authentication, make sure that the user is able to create
# new topics. As of now, there is no support for prefixed topic name.
#
# PLEASE NOTE: This patch will only modify the existing configuration files.
# You will have to run `./install.sh` again to apply the changes.

source patches/_lib.sh

# If `sentry/sentry.conf.py` exists, we'll modify it.
# Otherwise, we'll use `sentry/sentry.conf.example.py`.
# This kind of conditional logic will be used with other files.
SENTRY_CONFIG_PY="sentry/sentry.conf.py"
if [[ ! -f "$SENTRY_CONFIG_PY" ]]; then
  SENTRY_CONFIG_PY="sentry/sentry.conf.example.py"
fi

ENV_FILE=".env.custom"
if [[ ! -f "$ENV_FILE" ]]; then
  ENV_FILE=".env"
fi

RELAY_CONFIG_YML="relay/config.yml"
if [[ ! -f "$RELAY_CONFIG_YML" ]]; then
  RELAY_CONFIG_YML="relay/config.example.yml"
fi

## XXX(aldy505): Create the diff by running `diff -u sentry/sentry.conf.py sentry/sentry.conf.example.py`.
##               But you'll need to have your own `sentry/sentry.conf.py` file with the changes already set.
patch -p1 $SENTRY_CONFIG_PY <<"EOF"
@@ -136,9 +136,17 @@
 SENTRY_CACHE = "sentry.cache.redis.RedisCache"

 DEFAULT_KAFKA_OPTIONS = {
-    "bootstrap.servers": "kafka:9092",
+    "bootstrap.servers": env("KAFKA_BOOTSTRAP_SERVERS", "kafka:9092"),
     "message.max.bytes": 50000000,
     "socket.timeout.ms": 1000,
+    "security.protocol": env("KAFKA_SECURITY_PROTOCOL", "PLAINTEXT"), # Valid options are PLAINTEXT, SSL, SASL_PLAINTEXT, SASL_SSL
+    # If you don't use any of these options below, you can remove them or set them to `None`.
+    "sasl.mechanism": env("KAFKA_SASL_MECHANISM", None), # Valid options are PLAIN, SCRAM-SHA-256, SCRAM-SHA-512. Other mechanism might be unavailable.
+    "sasl.username": env("KAFKA_SASL_USERNAME", None),
+    "sasl.password": env("KAFKA_SASL_PASSWORD", None),
+    "ssl.ca.location": env("KAFKA_SSL_CA_LOCATION", None), # Remove this line if SSL is not used.
+    "ssl.certificate.location": env("KAFKA_SSL_CERTIFICATE_LOCATION", None), # Remove this line if SSL is not used.
+    "ssl.key.location": env("KAFKA_SSL_KEY_LOCATION", None), # Remove this line if SSL is not used.
 }

 SENTRY_EVENTSTREAM = "sentry.eventstream.kafka.KafkaEventStream"
EOF

# Add additional Kafka options to the ENV_FILE
# Only patch this when "KAFKA_BOOTSTRAP_SERVERS" is not set.
if [[ grep -q "KAFKA_BOOTSTRAP_SERVERS" "${ENV_FILE}" ]]; then
  echo "🚨 Skipping patching of ${ENV_FILE}"
else
  cat <<EOF >>"$ENV_FILE"

################################################################################
## Additional External Kafka options
################################################################################
KAFKA_BOOTSTRAP_SERVERS=kafka-node1:9092,kafka-node2:9092,kafka-node3:9092
# Valid options are PLAINTEXT, SSL, SASL_PLAINTEXT, SASL_SSL
KAFKA_SECURITY_PROTOCOL=PLAINTEXT
# Valid options are PLAIN, SCRAM-SHA-256, SCRAM-SHA-512. Other mechanism might be unavailable.
# KAFKA_SASL_MECHANISM=PLAIN
# KAFKA_SASL_USERNAME=username
# KAFKA_SASL_PASSWORD=password
# Put your certificates on the \`certificates/kafka\` directory.
# The certificates will be mounted as read-only volumes.
# KAFKA_SSL_CA_LOCATION=/kafka-certificates/ca.pem
# KAFKA_SSL_CERTIFICATE_LOCATION=/kafka-certificates/client.pem
# KAFKA_SSL_KEY_LOCATION=/kafka-certificates/client.key
EOF
fi

patch -p1 $RELAY_CONFIG_YML <<"EOF"
@@ -7,8 +7,15 @@
 processing:
   enabled: true
   kafka_config:
-    - {name: "bootstrap.servers", value: "kafka:9092"}
+    - {name: "bootstrap.servers", value: "kafka-node1:9092,kafka-node2:9092,kafka-node3:9092"}
     - {name: "message.max.bytes", value: 50000000} # 50MB
+    - {name: "security.protocol", value: "PLAINTEXT"}
+    - {name: "sasl.mechanism", value: "PLAIN"} # Remove or comment this line if SASL is not used.
+    - {name: "sasl.username", value: "username"} # Remove or comment this line if SASL is not used.
+    - {name: "sasl.password", value: "password"} # Remove or comment this line if SASL is not used.
+    - {name: "ssl.ca.location", value: "/kafka-certificates/ca.pem"} # Remove or comment this line if SSL is not used.
+    - {name: "ssl.certificate.location", value: "/kafka-certificates/client.pem"} # Remove or comment this line if SSL is not used.
+    - {name: "ssl.key.location", value: "/kafka-certificates/client.key"} # Remove or comment this line if SSL is not used.
   redis: redis://redis:6379
   geoip_path: "/geoip/GeoLite2-City.mmdb"
EOF

COMPOSE_OVERRIDE_CONTENT=$(
  cat <<-EOF
x-snuba-defaults: &snuba_defaults
  environment:
    DEFAULT_BROKERS: \${KAFKA_BOOTSTRAP_SERVERS:-kafka:9092}
    KAFKA_SECURITY_PROTOCOL: \${KAFKA_SECURITY_PROTOCOL:-PLAINTEXT}
    KAFKA_SSL_CA_PATH: \${KAFKA_SSL_CA_LOCATION:-}
    KAFKA_SSL_CERT_PATH: \${KAFKA_SSL_CERTIFICATE_LOCATION:-}
    KAFKA_SSL_KEY_PATH: \${KAFKA_SSL_KEY_LOCATION:-}
    KAFKA_SASL_MECHANISM: \${KAFKA_SASL_MECHANISM:-}
    KAFKA_SASL_USERNAME: \${KAFKA_SASL_USERNAME:-}
    KAFKA_SASL_PASSWORD: \${KAFKA_SASL_PASSWORD:-}
  volumes:
    - ./certificates/kafka:/kafka-certificates:ro
x-sentry-defaults: &sentry_defaults
  environment:
    KAFKA_BOOTSTRAP_SERVERS: \${KAFKA_BOOTSTRAP_SERVERS:-kafka:9092}
    KAFKA_SECURITY_PROTOCOL: \${KAFKA_SECURITY_PROTOCOL:-PLAINTEXT}
    KAFKA_SSL_CA_LOCATION: \${KAFKA_SSL_CA_LOCATION:-}
    KAFKA_SSL_CERTIFICATE_LOCATION: \${KAFKA_SSL_CERTIFICATE_LOCATION:-}
    KAFKA_SSL_KEY_LOCATION: \${KAFKA_SSL_KEY_LOCATION:-}
    KAFKA_SASL_MECHANISM: \${KAFKA_SASL_MECHANISM:-}
    KAFKA_SASL_USERNAME: \${KAFKA_SASL_USERNAME:-}
    KAFKA_SASL_PASSWORD: \${KAFKA_SASL_PASSWORD:-}
  volumes:
    - ./certificates/kafka:/kafka-certificates:ro

services:
  kafka: !reset null
  vroom:
    environment:
      SENTRY_KAFKA_BROKERS_PROFILING: \${KAFKA_BOOTSTRAP_SERVERS:-kafka:9092}
      SENTRY_KAFKA_BROKERS_OCCURRENCES: \${KAFKA_BOOTSTRAP_SERVERS:-kafka:9092}
      SENTRY_KAFKA_BROKERS_SPANS: \${KAFKA_BOOTSTRAP_SERVERS:-kafka:9092}
      SENTRY_KAFKA_SECURITY_PROTOCOL: \${KAFKA_SECURITY_PROTOCOL:-PLAINTEXT}
      SENTRY_KAFKA_SSL_CA_PATH: \${KAFKA_SSL_CA_LOCATION:-}
      SENTRY_KAFKA_SSL_CERT_PATH: \${KAFKA_SSL_CERTIFICATE_LOCATION:-}
      SENTRY_KAFKA_SSL_KEY_PATH: \${KAFKA_SSL_KEY_LOCATION:-}
      SENTRY_KAFKA_SASL_MECHANISM: \${KAFKA_SASL_MECHANISM:-}
      SENTRY_KAFKA_SASL_USERNAME: \${KAFKA_SASL_USERNAME:-}
      SENTRY_KAFKA_SASL_PASSWORD: \${KAFKA_SASL_PASSWORD:-}
    volumes:
      - ./certificates/kafka:/kafka-certificates:ro
  relay:
    volumes:
      - ./certificates/kafka:/kafka-certificates:ro
  snuba-api:
    <<: *snuba_defaults
  snuba-errors-consumer:
    <<: *snuba_defaults
  snuba-outcomes-consumer:
    <<: *snuba_defaults
  snuba-outcomes-billing-consumer:
    <<: *snuba_defaults
  snuba-group-attributes-consumer:
    <<: *snuba_defaults
  snuba-replacer:
    <<: *snuba_defaults
  snuba-subscription-consumer-events:
    <<: *snuba_defaults
  snuba-transactions-consumer:
    <<: *snuba_defaults
  snuba-replays-consumer:
    <<: *snuba_defaults
  snuba-issue-occurrence-consumer:
    <<: *snuba_defaults
  snuba-metrics-consumer:
    <<: *snuba_defaults
  snuba-subscription-consumer-transactions:
    <<: *snuba_defaults
  snuba-subscription-consumer-metrics:
    <<: *snuba_defaults
  snuba-generic-metrics-distributions-consumer:
    <<: *snuba_defaults
  snuba-generic-metrics-sets-consumer:
    <<: *snuba_defaults
  snuba-generic-metrics-counters-consumer:
    <<: *snuba_defaults
  snuba-generic-metrics-gauges-consumer:
    <<: *snuba_defaults
  snuba-profiling-profiles-consumer:
    <<: *snuba_defaults
  snuba-profiling-functions-consumer:
    <<: *snuba_defaults
  snuba-spans-consumer:
    <<: *snuba_defaults
  web:
    <<: *sentry_defaults
  cron:
    <<: *sentry_defaults
  worker:
    <<: *sentry_defaults
  events-consumer:
    <<: *sentry_defaults
  attachments-consumer:
    <<: *sentry_defaults
  post-process-forwarder-errors:
    <<: *sentry_defaults
  subscription-consumer-events:
    <<: *sentry_defaults
  transactions-consumer:
    <<: *sentry_defaults
  metrics-consumer:
    <<: *sentry_defaults
  generic-metrics-consumer:
    <<: *sentry_defaults
  billing-metrics-consumer:
    <<: *sentry_defaults
  ingest-replay-recordings:
    <<: *sentry_defaults
  ingest-occurrences:
    <<: *sentry_defaults
  ingest-profiles:
    <<: *sentry_defaults
  ingest-monitors:
    <<: *sentry_defaults
  ingest-feedback-events:
    <<: *sentry_defaults
  monitors-clock-tick:
    <<: *sentry_defaults
  monitors-clock-tasks:
    <<: *sentry_defaults
  post-process-forwarder-transactions:
    <<: *sentry_defaults
  post-process-forwarder-issue-platform:
    <<: *sentry_defaults
  subscription-consumer-transactions:
    <<: *sentry_defaults
  subscription-consumer-metrics:
    <<: *sentry_defaults
  subscription-consumer-generic-metrics:
    <<: *sentry_defaults
EOF
)
if [[ -f "docker-compose.override.yml" ]]; then
  echo "🚨 docker-compose.override.yml already exists. You will need to modify it manually:"
  echo "$COMPOSE_OVERRIDE_CONTENT"
else
  echo "🚨 docker-compose.override.yml  does not exist. Creating it now."
  echo "$COMPOSE_OVERRIDE_CONTENT" >docker-compose.override.yml
fi

echo ""
echo ""
echo "------------------------------------------------------------------------"
echo "-   Finished patching external-kafka.sh. Some things you'll need to do:"
echo "-   1. Modify the Kafka credentials on your $ENV_FILE file."
echo "-   2. Modify the Kafka credentials on your $RELAY_CONFIG_YML file."
echo "-   3. Run ./install.sh"
echo "-"
echo "-   NOTE: Remove or comment the corresponding line if you don't use it."
echo "------------------------------------------------------------------------"
