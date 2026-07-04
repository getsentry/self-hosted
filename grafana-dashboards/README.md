# Sentry Self-Hosted Grafana Dashboards

A starting set of Grafana dashboards for monitoring Sentry self-hosted installations via the StatsD metrics emitted by Sentry services (compatible with Prometheus, VictoriaMetrics, or Graphite with query rewrites).

## Dashboards

| File | Purpose |
|---|---|
| `sentry-overview.json` | High-level system health: API volume, Snuba queries, emails, webhooks, workflow engine, nodestore, and ClickHouse connections. |
| `sentry-ingestion.json` | Event ingestion flow: accepted/rejected events, Relay health, event pipeline latency, Symbolicator, project config, and Relay/Redis. |
| `sentry-background-processing.json` | Workers, task brokers, Arroyo consumers/producers: task throughput, execution duration, RPC latency, Kafka queue health, and backpressure. |
| `sentry-errors-and-failures.json` | Failure signals: rejected events, dropped messages, task RPC errors, and Snuba query health. |

## Metric name version

These dashboards are written against the dot-separated StatsD metric names emitted by Sentry self-hosted, for example:

- `stats.counters.sentry.relay.event.accepted.count`
- `stats.timers.sentry.events.since_received.median`
- `stats.counters.sentry.taskworker.worker.execute_task.count`

If you are using a statsd-to-prometheus exporter that converts dots to underscores, update the queries accordingly.

### Why `stats.<type>.*`?

The `stats.counters.*`, `stats.timers.*`, and `stats.gauges.*` prefixes come from the default StatsD naming convention, not from Sentry itself. Sentry emits metric names like `sentry.relay.event.accepted`; the StatsD server then stores them as `stats.counters.sentry.relay.event.accepted.count`. This is the expected behavior when using the default StatsD settings.

## Importing

1. Open Grafana → **Dashboards** → **Import**.
2. Upload one of the JSON files from this directory.
3. Select your VictoriaMetrics/Prometheus data source.
4. The `host` variable will populate automatically from the `host` label.

## Notes

- Dashboards default to the last hour with a 30-second refresh.
- Several panels group by labels documented in Sentry's monitoring guide (e.g. `url_name`, `method`, `taskname`, `stage`). If your installation does not yet emit those tags, the panels will aggregate to a single series until the tags are present.
