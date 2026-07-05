# Sentry Self-Hosted Grafana Dashboards

A set of Grafana dashboards for monitoring Sentry self-hosted installations via the StatsD metrics emitted by Sentry services (compatible with Prometheus, VictoriaMetrics, or Graphite with query rewrites).

Each dashboard is organized around an observability question — **what is this subsystem doing, and is it healthy?** — rather than around raw metrics.

## Dashboards

| File | Title | Purpose |
|---|---|---|
| `sentry-overview.json` | **Self-Hosted Sentry: Overview** | The only dashboard you *need* to install. One summary row per subsystem so you can tell at a glance where to drill down. |
| `sentry-ui-api.json` | **Self-Hosted Sentry: UI & API** | Sentry API traffic, response codes, login attempts, rate limits, Snuba API queries, and backing-store health (Postgres, Memcached, Redis, ClickHouse). |
| `sentry-ingestion.json` | **Self-Hosted Sentry: Ingestion** | Relay event intake, project-config fetching, Kafka producer health, ingest consumers, and spans buffer. |
| `sentry-event-processing.json` | **Self-Hosted Sentry: Event Processing** | Pipeline latency, event normalization, Symbolicator, Snuba consumer inserts, and Arroyo backpressure. |
| `sentry-background-workflows.json` | **Self-Hosted Sentry: Background Workflows** | Workflow engine, alerts, email, weekly reports, outbound integrations/webhooks, and monitors. |
| `sentry-tasks-manager.json` | **Self-Hosted Sentry: Tasks Manager** | Taskbroker queue state and taskworker execution, RPC, and scheduling health. |
| `sentry-foundational-storage.json` | **Self-Hosted Sentry: Foundational Storage** | Nodestore, filestore, caches (Memcached, Redis), and Postgres query counters. |

## Metric name version

These dashboards are written against the dot-separated StatsD metric names emitted by Sentry self-hosted, for example:

- `stats.counters.sentry.relay.event.accepted.count`
- `stats.timers.sentry.events.since_received.median`
- `stats.counters.sentry.taskworker.worker.execute_task.count`
- `stats.counters.sentry.login.attempt.count`
- `stats.timers.sentry.relay.config.get_project_config.duration.median`
- `stats.counters.sentry.weekly_report.send_email.success.count`

If you are using a statsd-to-prometheus exporter that converts dots to underscores, update the queries accordingly.

### Why `stats.<type>.*`?

The `stats.counters.*`, `stats.timers.*`, and `stats.gauges.*` prefixes come from the default StatsD naming convention, not from Sentry itself. Sentry emits metric names like `sentry.relay.event.accepted`; the StatsD server then stores them as `stats.counters.sentry.relay.event.accepted.count`. This is the expected behavior when using the default StatsD settings.

## Importing

1. Open Grafana → **Dashboards** → **Import**.
2. Upload `sentry-overview.json` (and any subsystem dashboards you want).
3. Select your VictoriaMetrics/Prometheus data source.
4. The `host` variable will populate automatically from the `host` label.

## Notes

- Dashboards default to the last hour with a 30-second refresh.
- Several panels group by labels documented in Sentry's monitoring guide (e.g. `url_name`, `method`, `taskname`, `stage`). If your installation does not yet emit those tags, the panels will aggregate to a single series until the tags are present.
- Some metrics are feature-specific (e.g. Postgres queries only appear where Sentry emits them). Missing series simply produce empty panels until the corresponding feature is exercised.
