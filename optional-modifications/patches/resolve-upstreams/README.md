# resolve-upstreams

nginx caches the addresses of `relay` and `web` until it restarts.
A recreated container can return on a different address.
nginx keeps using the old one and answers every request with 502.
Ingest breaks silently, because `relay` serves `/api/store/`, `/api/<id>/` and `/api/0/relays/`.
This patch makes nginx re-resolve both names.

## Apply

Run these from the repository root, keeping the order and the `&&`.
Then run `./install.sh`.

```bash
patch -p0 < optional-modifications/patches/resolve-upstreams/docker-compose.yml.patch && \
patch -p0 < optional-modifications/patches/resolve-upstreams/nginx-resolver.conf.template.patch && \
patch -p0 < optional-modifications/patches/resolve-upstreams/nginx.conf.patch
```

A rejected hunk stops the sequence before anything depends on it.

## Notes

- `valid=10s` sets the recovery time.
  It costs 6 DNS queries per minute per upstream.
  Worker count and traffic do not affect that.
- An unresolvable upstream no longer stops nginx from starting.
  nginx serves 502s instead.
  The healthcheck misses this, because it requests `/` and `curl` without `-f` exits 0 on a 502.
- nginx refuses to start if its `/etc/resolv.conf` lists no `nameserver`.
  An unpatched install also breaks in that case, with a different message.
- Do not bind-mount over `/etc/nginx/conf.d`.
  The entrypoint renders the resolver snippet there.
- Tested on Docker.
  The patch reads the resolver address from the container, so it should suit Podman, but nobody has
  tested that.

## Background

- https://github.com/getsentry/self-hosted/issues/3894
- https://github.com/getsentry/self-hosted/pull/4492
