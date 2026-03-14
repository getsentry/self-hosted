ARG BASE_IMAGE

FROM debian:bookworm AS certs
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Put your custom certs here as *.crt (PEM). You can keep your repo folder name.
COPY ./certificates/* /usr/local/share/ca-certificates/

RUN update-ca-certificates

FROM ${BASE_IMAGE}

COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

COPY --from=certs /etc/ssl/certs /etc/ssl/certs
