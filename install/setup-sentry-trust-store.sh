echo "${_group}Setting up the CA trust store for Sentry ..."

# Sentry containers mount this directory read-only at /etc/ssl/certs. It holds
# the image's own CA certificates plus every certificates/*.crt, so changes to
# custom CAs take effect on the next ./install.sh.
trust_store="certificates/.generated/sentry/etc/ssl/certs"
rm -rf "$trust_store"
mkdir -p "$trust_store"

container=$($CONTAINER_ENGINE create sentry-self-hosted-local)
$CONTAINER_ENGINE cp "$container:/etc/ssl/certs/." "$trust_store/"
$CONTAINER_ENGINE rm "$container" >/dev/null

for cert in certificates/*.crt; do
  [[ -f "$cert" ]] || continue
  name=$(basename "$cert" .crt)
  cp "$cert" "$trust_store/$name.pem"
  cat "$cert" >>"$trust_store/ca-certificates.crt"
  echo >>"$trust_store/ca-certificates.crt"
  # Hash link for libraries that look certificates up by directory.
  if command -v openssl &>/dev/null; then
    hash=$(openssl x509 -hash -noout -in "$cert")
    n=0
    while [[ -e "$trust_store/$hash.$n" || -L "$trust_store/$hash.$n" ]]; do n=$((n + 1)); done
    ln -s "$name.pem" "$trust_store/$hash.$n"
  fi
  echo "Added $cert"
done

echo "${_endgroup}"
