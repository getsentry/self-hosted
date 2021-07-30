#! /usr/bin/env bash
set -e

export COMPOSE_FILE="../docker-compose.yml:./custom-ca-roots/docker-compose.test.yml"

TEST_NGINX_CONF_PATH="./custom-ca-roots/nginx"
CUSTOM_CERTS_PATH="../certificates"

# generate tightly constrained CA
# NB: `-addext` requires LibreSSL 3.1.0+, or OpenSSL (brew install openssl)
openssl req -x509 -new -nodes -newkey rsa:2048 -keyout $TEST_NGINX_CONF_PATH/ca.key \
-sha256 -days 1 -out $TEST_NGINX_CONF_PATH/ca.crt -batch \
-subj "/CN=TEST CA *DO NOT TRUST*" \
-addext "keyUsage = critical, keyCertSign, cRLSign" \
-addext "nameConstraints = critical, permitted;DNS:self.test"

## Lines like the following are debug helpers ...
# openssl x509 -in nginx/ca.crt -text -noout

mkdir -p $CUSTOM_CERTS_PATH
cp $TEST_NGINX_CONF_PATH/ca.crt $CUSTOM_CERTS_PATH/test-custom-ca-roots.crt

# generate server certificate
openssl req -new -nodes -newkey rsa:2048 -keyout $TEST_NGINX_CONF_PATH/self.test.key \
-addext "subjectAltName=DNS:self.test" \
-out $TEST_NGINX_CONF_PATH/self.test.req -batch -subj "/CN=Self Signed with CA Test Server"

# openssl req -in nginx/self.test.req -text -noout

openssl x509 -req -in $TEST_NGINX_CONF_PATH/self.test.req -CA $TEST_NGINX_CONF_PATH/ca.crt -CAkey $TEST_NGINX_CONF_PATH/ca.key \
-extfile <(printf "subjectAltName=DNS:self.test") \
-CAcreateserial -out $TEST_NGINX_CONF_PATH/self.test.crt -days 1 -sha256

# openssl x509 -in nginx/self.test.crt -text -noout

# sanity check that signed certificate passes OpenSSL's validation
openssl verify -CAfile $TEST_NGINX_CONF_PATH/ca.crt $TEST_NGINX_CONF_PATH/self.test.crt

# self signed certificate, for sanity check of not just accepting all certs
openssl req -x509 -newkey rsa:2048 -nodes -days 1 -keyout $TEST_NGINX_CONF_PATH/fake.test.key \
-out $TEST_NGINX_CONF_PATH/fake.test.crt -addext "subjectAltName=DNS:fake.test" -subj "/CN=Self Signed Test Server"

# openssl x509 -in nginx/fake.test.crt -text -noout

cp ./custom-ca-roots/test.py ../sentry/test-custom-ca-roots.py

$dc up -d fixture-custom-ca-roots
