#! /usr/bin/env bash
set -e

# remove old test certs
rm -f test/nginx/self.test.* test/ca.* ../certificates/ca.crt || true
cp test/cert-test.py sentry/
mkdir -p certificates/

# generate tighly contrained CA
openssl req -x509 -new -nodes -newkey rsa:2048 -keyout test/ca.key \
-sha256 -days 1 -out test/ca.crt -batch \
-subj "/CN=TEST CA *DO NOT TRUST*" \
-addext "keyUsage = critical, keyCertSign, cRLSign" \
-addext "nameConstraints = critical, permitted;DNS:self.test"

# openssl x509 -in test/ca.crt -text -noout
cp test/ca.crt certificates/

# generate server certificate
openssl req -new -nodes -newkey rsa:2048 -keyout test/nginx/self.test.key \
-addext "subjectAltName=DNS:self.test" \
-out test/nginx/self.test.req -batch -subj "/CN=Self Signed with CA Test Server"

# openssl req -in test/nginx/self.test.req -text -noout

openssl x509 -req -in test/nginx/self.test.req -CA test/ca.crt -CAkey test/ca.key \
-extfile <(printf "subjectAltName=DNS:self.test") \
-CAcreateserial -out test/nginx/self.test.crt -days 1 -sha256 

# openssl x509 -in test/nginx/self.test.crt -text -noout

# sanity check that signed certificate passes OpenSSL's validation
openssl verify -CAfile test/ca.crt test/nginx/self.test.crt

# self signed certificate, for sanity check of not just accepting all certs
openssl req -x509 -newkey rsa:2048 -nodes -days 1 -keyout test/nginx/fake.test.key \
-out test/nginx/fake.test.crt -addext "subjectAltName=DNS:fake.test" -subj "/CN=Self Signed Test Server"

# openssl x509 -in test/nginx/fake.test.crt -text -noout
