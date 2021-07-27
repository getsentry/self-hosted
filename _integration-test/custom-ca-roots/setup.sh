#! /usr/bin/env bash
set -e

cd $(dirname "$0")
./teardown.sh

# generate tightly constrained CA
# NB: `-addext` requires LibreSSL 3.1.0+, or OpenSSL (brew install openssl)
openssl req -x509 -new -nodes -newkey rsa:2048 -keyout nginx/ca.key \
-sha256 -days 1 -out nginx/ca.crt -batch \
-subj "/CN=TEST CA *DO NOT TRUST*" \
-addext "keyUsage = critical, keyCertSign, cRLSign" \
-addext "nameConstraints = critical, permitted;DNS:self.test"

## Lines like the following are debug helpers ...
# openssl x509 -in nginx/ca.crt -text -noout

mkdir -p ../../certificates/
cp nginx/ca.crt ../../certificates/test-custom-ca-roots.crt

# generate server certificate
openssl req -new -nodes -newkey rsa:2048 -keyout nginx/self.test.key \
-addext "subjectAltName=DNS:self.test" \
-out nginx/self.test.req -batch -subj "/CN=Self Signed with CA Test Server"

# openssl req -in nginx/self.test.req -text -noout

openssl x509 -req -in nginx/self.test.req -CA nginx/ca.crt -CAkey nginx/ca.key \
-extfile <(printf "subjectAltName=DNS:self.test") \
-CAcreateserial -out nginx/self.test.crt -days 1 -sha256

# openssl x509 -in nginx/self.test.crt -text -noout

# sanity check that signed certificate passes OpenSSL's validation
openssl verify -CAfile nginx/ca.crt nginx/self.test.crt

# self signed certificate, for sanity check of not just accepting all certs
openssl req -x509 -newkey rsa:2048 -nodes -days 1 -keyout nginx/fake.test.key \
-out nginx/fake.test.crt -addext "subjectAltName=DNS:fake.test" -subj "/CN=Self Signed Test Server"

# openssl x509 -in nginx/fake.test.crt -text -noout

cp test.py ../../sentry/test-custom-ca-roots.py
