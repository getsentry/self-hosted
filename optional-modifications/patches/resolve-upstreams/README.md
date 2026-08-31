# resolve-upstreams

nginx caches the addresses of `relay` and `web` until it restarts.
A recreated container can return on a different address.
nginx keeps using the old one and answers every request with 502.
Ingest breaks silently, because `relay` serves `/api/store/`, `/api/<id>/` and `/api/0/relays/`.
This patch makes nginx re-resolve both names.

`restart: true` on nginx's `depends_on` already restarts nginx after a Compose operation recreates `web` or `relay`.
Apply this patch only if you also need to survive address changes that no Compose operation causes, such as a crash restart or a Docker daemon restart.

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

- [Report of nginx routing to a stale relay address](https://github.com/getsentry/self-hosted/issues/3894)
- [The `depends_on` policy that covers Compose operations](https://github.com/getsentry/self-hosted/pull/3914)
- [First attempt at re-resolution, with the discussion that led to this patch](https://github.com/getsentry/self-hosted/pull/4295)
- [Second attempt, which changed the default configuration](https://github.com/getsentry/self-hosted/pull/4492)
