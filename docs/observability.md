# Stack Observability

How to observe the self-hosted stack itself: enabling statsd metrics, changing
service log levels, and keeping container logs bounded on disk.

Product-side surfaces (on-demand logs, APM, tracing, profiling) and CI APM
telemetry are out of scope here — they are already enabled and tested, and
product defects are routed upstream per this repository's `AGENTS.md` policy.

## Metrics (statsd)

Set `STATSD_ADDR` once in `.env` to enable statsd metrics for the whole stack:

```bash
STATSD_ADDR=127.0.0.1:8125
```

Compose fans that single value out to every service that consumes it:

| Service | Compose environment variable | Default |
|---------|------------------------------|---------|
| sentry | `SENTRY_STATSD_ADDR` | *(empty — disabled)* |
| snuba | `SNUBA_STATSD_ADDR` | *(empty — disabled)* |
| relay | `RELAY_STATSD_ADDR` | `127.0.0.1:8125` |
| symbolicator + symbolicator-cleanup | `SYMBOLICATOR_STATSD_ADDR` | `127.0.0.1:8125` |
| taskbroker | `TASKBROKER_STATSD_ADDR` | `127.0.0.1:8125` |
| uptime-checker | `UPTIME_CHECKER_STATSD_ADDR` | `127.0.0.1:8125` |

### Why the defaults differ (intentional)

The split is deliberate, not an oversight:

- **sentry and snuba** default to empty. `sentry/sentry.conf.example.py` only
  configures the backend when the value is truthy, so empty means *disabled*.
- **relay, symbolicator, taskbroker, uptime-checker** require a resolvable
  address: they fail fast (error, panic, or hard `Err` on startup) when the
  value is empty. An empty default would therefore *crash* them, so packaging
  gives them a localhost default instead.
- The split was introduced on purpose in
  [#4031](https://github.com/getsentry/self-hosted/pull/4031) (and completed in
  [#4042](https://github.com/getsentry/self-hosted/pull/4042)).

Unifying every default to "empty = disabled" is **not possible within this
repository**: it needs upstream changes in symbolicator, taskbroker, and
uptime-checker first. Until then, leave the defaults alone and set
`STATSD_ADDR` when you have somewhere to send metrics to.

For the keys worth emitting, see the upstream notable statsd keys guide
([getsentry/sentry-docs#15487](https://github.com/getsentry/sentry-docs/pull/15487)).

## Known noise without a listener

With no statsd listener reachable at the default `127.0.0.1:8125`, **symbolicator
repeatedly logs connection-refused metric errors** (taskbroker and uptime-checker
can log the same). This is expected: the localhost default points at a socket
that is not there.

Do not "fix" this by editing packaging defaults. Prefer either pointing
`STATSD_ADDR` at a real endpoint, or filing an upstream follow-up asking those
services to treat an empty/absent statsd address as *disabled*.

## Log levels

| Service | Where the level lives | How to change it |
|---------|-----------------------|------------------|
| relay | `relay/config.yml` → `logging.level` (env-driven) | set `RELAY_LOG_LEVEL` in `.env`, then `docker compose up -d relay` |
| symbolicator | `symbolicator/config.yml` → `logging.level` (env-driven) | set `SYMBOLICATOR_LOG_LEVEL` in `.env`, then `docker compose up -d symbolicator` |
| sentry | no persistent knob (documented only) | one-off `-e SENTRY_LOG_LEVEL=…`, or the override file below |
| kafka | `KAFKA_LOG4J_*` in `docker-compose.yml` (inside the external-kafka patch) | `docker-compose.override.yml` snippet below |
| clickhouse | `clickhouse/config.xml` → `<logger><level>warning</level>` | local edit (see the tradeoff) |

Compose supplies the relay/symbolicator defaults (`WARN` and `warn`), so the
knobs are optional; with nothing set, verbosity is exactly what it was before.

### Sentry — one-off or override file

The proven patterns are the ones already used in this repo
(`sentry-admin.sh`, `scripts/_lib.sh`):

```bash
docker compose run --rm -e SENTRY_LOG_LEVEL=DEBUG web <command>
```

For a persistent value, use `docker-compose.override.yml`:

```yaml
services:
  web:
    environment:
      SENTRY_LOG_LEVEL: DEBUG
```

### Kafka — update *both* log4j keys

`KAFKA_LOG4J_LOGGERS` is an explicit per-logger list; raising only
`KAFKA_LOG4J_ROOT_LOGLEVEL` to `DEBUG` is masked by the `WARN` entries. Both
keys must move together:

```yaml
# docker-compose.override.yml
services:
  kafka:
    environment:
      KAFKA_LOG4J_ROOT_LOGLEVEL: "DEBUG"
      KAFKA_LOG4J_LOGGERS: "kafka.cluster=DEBUG,kafka.controller=DEBUG,kafka.coordinator=DEBUG,kafka.log=DEBUG,kafka.server=DEBUG,state.change.logger=DEBUG"
```

The override file is the right home: editing `docker-compose.yml` directly
would fall inside the external-kafka patch and churn it on every upgrade.

### ClickHouse — location note

`clickhouse/config.xml` sets `<level>warning</level>` in `<logger>`. The file
is tracked, so a local edit works but **will conflict on upgrade** — re-apply
it after pulling, or revert it before pulling. Server-side query logging is
already disabled in the same file.

## Log rotation (Docker json-file driver)

Container logs are unbounded by default. Rotation is a **host Docker daemon
setting**, not a per-service Compose option — this repo deliberately does not
add `logging:` blocks. On the host, edit `/etc/docker/daemon.json`:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

Then restart the Docker daemon (`sudo systemctl restart docker`). Log options
bind at container **create** time, so existing containers also need a recreate:

```bash
docker compose up -d --force-recreate
```

## Retention context (already tuned in-repo)

- **Kafka**: `KAFKA_LOG_RETENTION_HOURS=3` in `docker-compose.yml`.
- **ClickHouse**: system log tables are removed in `clickhouse/config.xml`
  (`<query_log remove="remove"/>` and friends), so they never accumulate.
- **Sentry**: `SENTRY_EVENT_RETENTION_DAYS=90` in `.env`.

## Where full logs already land

- **Install**: `install/_logging.sh` tees the whole install to
  `sentry_install_log-<timestamp>.txt` in the repository root.
- **CI**: the `Inspect failure` step in `action.yaml` runs
  `docker compose logs` (plus `docker compose ps` and `docker stats`) whenever
  a workflow job fails.
- **Issues**: attach those logs when filing through
  `.github/ISSUE_TEMPLATE/problem-report.yml`.

## Fresh install vs upgrade

`ensure_file_from_example` (in `install/_lib.sh`) copies an example config only
when the live file is missing. Consequences:

- **Fresh install**: `relay/config.yml` and `symbolicator/config.yml` are
  created from the updated examples and pick up the env-driven `logging.level`.
- **Upgrade**: existing live configs are **not** regenerated. Either merge the
  `logging.level` change manually into `relay/config.yml` /
  `symbolicator/config.yml`, or delete the live file and re-run `./install.sh`
  to recreate it from the example.
