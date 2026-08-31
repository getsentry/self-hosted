# resolve-upstreams

Make nginx re-resolve `relay` and `web` instead of caching their addresses until it restarts.
Without this, a recreated container that comes back on a different address 502s every request —
silently for ingest, since `relay` serves `/api/store/`, `/api/<id>/` and `/api/0/relays/`.

## Apply

From the repository root, keeping the order and the `&&`, then run `./install.sh`:

```bash
patch -p0 < optional-modifications/patches/resolve-upstreams/docker-compose.yml.patch && \
patch -p0 < optional-modifications/patches/resolve-upstreams/nginx-resolver.conf.template.patch && \
patch -p0 < optional-modifications/patches/resolve-upstreams/nginx.conf.patch
```

A rejected hunk stops the sequence before anything depends on it.

## Notes

- `valid=10s` is the recovery time. Cost: 6 DNS queries per minute per upstream, regardless of
  worker count and traffic.
- An unresolvable upstream no longer stops nginx from starting; it serves 502s instead. The
  healthcheck does not catch this — it requests `/`, and `curl` without `-f` exits 0 on a 502.
- nginx will not start if its `/etc/resolv.conf` has no `nameserver`. An unpatched install is also
  broken in that case, with a different message.
- Do not bind-mount over `/etc/nginx/conf.d`; the resolver snippet is rendered there.
- Verified on Docker. The Podman path is engine-agnostic by construction but untested.

## Background

- https://github.com/getsentry/self-hosted/issues/3894
- https://github.com/getsentry/self-hosted/pull/4492
