# Changelog

## 21.12.0

### Support Docker Compose v2 (ongoing)

Self-hosted Sentry mostly works with Docker Compose v2 (in addition to v1 >= 1.28.0). There is [one more bug](https://github.com/getsentry/self-hosted/issues/1133) we are trying to squash.

By: @chadwhitacre (#1179)

### Prevent Component Drift

When a user runs the `install.sh` script, they get the latest version of the Sentry, Snuba, Relay and Symbolicator projects. However there is no guarantee they have pulled the latest `self-hosted` version first, and running an old one may cause problems. To mitigate this, we now perform a check during installation that the user is on the latest commit if they are on the `master` branch. You can disable this check with `--skip-commit-check`.

By: @chadwhitacre (#1191), @aminvakil (#1186)

### React to log4shell

Self-hosted Sentry is [not vulnerable](https://github.com/getsentry/self-hosted/issues/1196) to the [log4shell](https://log4shell.com/) vulnerability.

By: @chadwhitacre (#1203)

### Forum → Issues

In the interest of reducing sources of truth, providing better support, and restarting the fire of the self-hosted Sentry community, we [deprecated the Discourse forum in favor of GitHub Issues](https://github.com/getsentry/self-hosted/issues/1151).

By: @chadwhitacre (#1167, #1160, #1159)

### Rename onpremise to self-hosted (ongoing)

In the beginning we used the term "on-premise" and over time we introduced the term "self-hosted." In an effort to regain some consistency for both branding and developer mental overhead purposes, we are standardizing on the term "self-hosted." This release includes a fair portion of the work towards this across multiple repos, hopefully a future release will include the remainder. Some orphaned containers / volumes / networks are [expected](https://github.com/getsentry/self-hosted/pull/1169&#35;discussion_r756401917). You may clean them up with `docker-compose down --remove-orphans`.

By: @chadwhitacre (#1169)

### Add support for custom DotEnv file

There are several ways to [configure self-hosted Sentry](https://develop.sentry.dev/self-hosted/&#35;configuration) and one of them is the `.env` file. In this release we add support for a `.env.custom` file that is git-ignored to make it easier for you to override keys configured this way with custom values. Thanks to @Sebi94nbg for the contribution!

By: @Sebi94nbg (#1113)

### Various fixes & improvements

- Revert "Rename onpremise to self-hosted" (5495fe2e) by @chadwhitacre
- Rename onpremise to self-hosted (9ad05d87) by @chadwhitacre

## 21.11.0

### Various fixes & improvements

- Fix #1079 - bug in reset.sh (#1134) by @chadwhitacre
- ci: Enable parallel tests again, increase timeouts (#1125) by @BYK
- fix: Hide compose errors during version check (#1124) by @BYK
- build: Omit nightly bump commit from changelog (#1120) by @BYK
- build: Set master version to nightly (d3e77857)

## 21.10.0

### Support for Docker Compose v2 (ongoing)

You asked for it and you did it! Sentry self-hosted now can work with Docker Compose v2 thanks to our community's contributions.

PRs: #1116

### Various fixes & improvements

- docs: simplify Linux `sudo` instructions in README (#1096)
- build: Set master version to nightly (58874cf9)

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
