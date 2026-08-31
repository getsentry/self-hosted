# resolve-upstreams

nginx resolves the names in an `upstream` block once, at startup, and keeps the result for the life
of a worker. When a container is recreated onto a different address, nginx keeps using the old one
and every request fails until nginx is restarted.

The UI failing is obvious; ingest failing is not. `relay` serves `/api/store/`, `/api/<id>/` and
`/api/0/relays/`, so events are dropped while the UI keeps answering and nothing reports an error.

This patch adds `resolve` to both upstreams, the `zone` that `resolve` requires, and a `resolver`
directive rendered at container start from the container's own `/etc/resolv.conf` — the engine DNS
address is `127.0.0.11` on Docker but the network gateway on Podman, so it is not hardcoded.

## Apply

From the repository root, then run `./install.sh`:

```bash
patch -p0 < optional-modifications/patches/resolve-upstreams/nginx-resolver.conf.template.patch
patch -p0 < optional-modifications/patches/resolve-upstreams/nginx.conf.patch
patch -p0 < optional-modifications/patches/resolve-upstreams/docker-compose.yml.patch
```

All three belong together: `nginx.conf` will not start without the rendered snippet, and the snippet
is only rendered with the `docker-compose.yml` changes in place.

## Tradeoffs

`valid=10s` is the recovery time. Measured cost with 32 workers: 6 queries per minute per upstream,
independent of worker count and traffic, because the shared zone means one worker does the lookup.

An unresolvable upstream no longer stops nginx from starting. That is what lets nginx come up before
`relay`, but a typo in an upstream name or an unreachable resolver now yields a running container
serving 502s instead of `[emerg] host not found in upstream`. The healthcheck does not catch it —
it requests `/`, and `curl` without `-f` exits 0 on a 502.

If the nginx container's `/etc/resolv.conf` has no `nameserver`, nginx refuses to start. An
unpatched install is also broken in that case, with a different message.

Do not bind-mount over `/etc/nginx/conf.d`; the snippet is rendered there.

Verified on Docker. The Podman path is engine-agnostic by construction but untested.

## Background

- https://github.com/getsentry/self-hosted/issues/3894
- https://github.com/getsentry/self-hosted/pull/4492
