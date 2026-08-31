# resolve-upstreams

nginx caches the addresses of `relay` and `web` until it restarts.
A recreated container can come back on a different address.
Every request then fails with 502.
Ingest fails silently, because `relay` serves `/api/store/`, `/api/<id>/` and `/api/0/relays/`.
This patch makes nginx re-resolve both names instead.

## Apply

Run from the repository root.
Keep the order and the `&&`.
Then run `./install.sh`.

```bash
patch -p0 < optional-modifications/patches/resolve-upstreams/docker-compose.yml.patch && \
patch -p0 < optional-modifications/patches/resolve-upstreams/nginx-resolver.conf.template.patch && \
patch -p0 < optional-modifications/patches/resolve-upstreams/nginx.conf.patch
```

A rejected hunk stops the sequence before anything depends on it.

## Notes

- `valid=10s` is the recovery time.
  It costs 6 DNS queries per minute per upstream.
  Worker count and traffic do not change that.
- An unresolvable upstream no longer stops nginx from starting.
  It serves 502s instead.
  The healthcheck does not catch this.
  It requests `/`, and `curl` without `-f` exits 0 on a 502.
- nginx will not start if its `/etc/resolv.conf` has no `nameserver`.
  An unpatched install is also broken in that case, with a different message.
- Do not bind-mount over `/etc/nginx/conf.d`.
  The resolver snippet is rendered there.
- Verified on Docker.
  The Podman path is engine-agnostic by construction, but untested.

## Background

- https://github.com/getsentry/self-hosted/issues/3894
- https://github.com/getsentry/self-hosted/pull/4492
