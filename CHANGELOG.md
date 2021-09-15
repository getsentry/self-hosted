# Changelog

## 21.9.0

- fix(healthcheck): Increase retries to 5 (#1072)
- fix(requirements): Make compose version check bw-compatible (#1068)
- ci: Test with the required minimum docker-compose (#1066)
  Run tests using docker-compose `1.28.0` instead of latest
- fix(clickhouse): Use correct HTTP port for healthcheck (#1069)
  Fixes the regular `Unexpected packet` errors in Clickhouse

## 21.8.0

- feat: Support custom CA roots ([#27062](https://github.com/getsentry/sentry/pull/27062)), see the [docs](https://develop.sentry.dev/self-hosted/custom-ca-roots/) for more details.
- fix: Fix `curl` image to version 7.77.0
- upgrade: docker-compose version to 1.29.2
- feat: Leverage health checks for depends_on

## 21.7.0

- No documented changes.

## 21.6.3

- No documented changes.

## 21.6.2

- BREAKING CHANGE: The frontend bundle will be loaded asynchronously (via [#25744](https://github.com/getsentry/sentry/pull/25744)). This is a breaking change that can affect custom plugins that access certain globals in the django template. Please see https://forum.sentry.io/t/breaking-frontend-changes-for-custom-plugins/14184 for more information.

## 21.6.1

- No documented changes.

## 21.6.0

- feat: Add healthchecks for redis, memcached and postgres (#975)
