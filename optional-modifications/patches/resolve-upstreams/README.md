# resolve-upstreams

Make nginx re-resolve the `relay` and `web` container addresses instead of caching them for the
life of a worker process.

## The problem

nginx resolves the names in an `upstream` block once, at startup, and keeps the result forever. If
a container is recreated and comes back on a different address, nginx keeps sending traffic to the
old one. Every request fails until nginx itself is restarted.

The UI failing is obvious. Ingest failing is not: `relay` serves the `/api/store/`, `/api/<id>/`
and `/api/0/relays/` routes, so events are dropped while the UI keeps working normally and nothing
in the stack reports an error.

`docker compose restart relay` alone does not trigger this — the address is usually reused. It
takes a recreate (`docker compose up -d --force-recreate`, an image upgrade, a host reboot with a
different container start order, or anything else that lets another container claim the old
address) for the addresses to actually move.

## What the patch changes

- Adds `resolve` to both `upstream` servers, so nginx re-resolves the name on a timer.
- Adds `zone <name> 512k`, which `resolve` requires — it needs the upstream group in shared memory.
- Adds a `resolver` directive pointing at the container engine's own DNS, rendered at container
  start from `nginx-resolver.conf.template` by the nginx image entrypoint
  (`NGINX_ENTRYPOINT_LOCAL_RESOLVERS=1`). The address differs per engine: `127.0.0.11` on Docker,
  the network gateway on Podman. Reading it from the container's `/etc/resolv.conf` keeps the patch
  engine-agnostic.

`nginx.conf` stays mounted at `/etc/nginx/nginx.conf`, exactly where it is without the patch. The
generated snippet lands in `conf.d/` and is pulled in with an `include`, so a custom `nginx.conf`
is neither overwritten nor made unwritable.

## How to apply

From the repository root, then run `./install.sh`:

```bash
patch -p0 < optional-modifications/patches/resolve-upstreams/nginx-resolver.conf.template.patch
patch -p0 < optional-modifications/patches/resolve-upstreams/nginx.conf.patch
patch -p0 < optional-modifications/patches/resolve-upstreams/docker-compose.yml.patch
```

The first patch creates a new file. All three belong together: `nginx.conf` will not start without
the rendered snippet, and the snippet is only rendered if the `docker-compose.yml` changes
(the environment variable and the template bind mount) are in place.

## Cost

Measured on Docker 28.5.2, `nginx:1.31.4-alpine`, 32 worker processes, with a logging DNS server
in front of the engine resolver, over 70 seconds:

```
7 query[A] web
7 query[A] relay
```

14 queries, no AAAA. That is ~6 per minute per upstream — one per `valid=10s` window, and only one
query regardless of how many workers exist or how much traffic flows, because the shared zone means
a single worker performs the lookup. `ipv6=off` keeps nginx from also asking for AAAA records that
a default Compose network cannot route.

`valid=10s` is the recovery time. Raise it to cut the (already small) query volume further; the
cost is a correspondingly longer outage after an address change.

## Verified behaviour

Recovery, with a filler container claiming the old address so it cannot be reused:

```
web 172.31.7.2 -> 172.31.7.4
patched:    t2s=502 t4s=502 t6s=502 t8s=200 t10s=200 t12s=200
unpatched:  t5s=502 t10s=502 t15s=502 t20s=502 t25s=502 t30s=502   (never recovers)
```

## Tradeoffs

**A missing upstream no longer stops nginx from starting.** Without the patch, a name that does not
resolve is fatal and loud:

```
nginx: [emerg] host not found in upstream "relay:3000" in /etc/nginx/nginx.conf:69
```

With `resolve`, nginx starts, logs an error, and serves 502s until the name resolves. That is the
point — it is what lets nginx come up before `relay` and recover on its own — but it also means a
typo in an upstream name, or a resolver that is unreachable, produces a healthy-looking container
serving errors instead of a container that visibly refuses to start. The nginx healthcheck does not
catch this: it requests `/`, and `curl` without `-f` exits 0 on a 502.

**The resolver address must be discoverable.** If the nginx container's `/etc/resolv.conf` has no
`nameserver` line, the rendered directive has no address and nginx refuses to start
(`[emerg] no name servers defined`). Note that an unpatched install is also broken in that
situation — the static upstreams fail with `host not found in upstream` — so this is a different
error message rather than a newly broken case.

**Do not bind-mount over `/etc/nginx/conf.d`.** The entrypoint renders the snippet there; if that
directory is read-only, it aborts before nginx starts.

## Engines

Verified on Docker. The Podman path is engine-agnostic by construction (the address comes from
`/etc/resolv.conf` rather than being hardcoded) but has not been tested — if you run Podman,
confirm the rendered `/etc/nginx/conf.d/nginx-resolver.conf` names your aardvark resolver:

```bash
docker compose exec nginx cat /etc/nginx/conf.d/nginx-resolver.conf
```

## Background

- https://github.com/getsentry/self-hosted/issues/3894
- https://github.com/getsentry/self-hosted/pull/4492
