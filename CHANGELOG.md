# Changelog

## 22.10.0

### Various fixes & improvements

- Split post process forwarders (#1759) by @chadwhitacre
- Revert "Enforce error reporting for self-hosted" (#1755) by @hubertdeng123
- Enforce error reporting for self-hosted (#1753) by @hubertdeng123
- ref: Remove unused scripts and code (#1710) by @BYK
- Check to see if docker compose exists, else error out (#1733) by @hubertdeng123
- Fix minimum version requirements for docker and docker compose (#1732) by @hubertdeng123
- Factor out clean and use it in unit-test (#1731) by @chadwhitacre
- Reorganize unit test layout (#1729) by @hubertdeng123
- Request event ID in issue template (#1723) by @ethanhs
- Tag releases with sentry-cli (#1718) by @hubertdeng123
- Send full logs as an attachment to our dogfood instance (#1715) by @hubertdeng123

## 22.9.0

### Various fixes & improvements

- Fix traceback hash for error monitoring (#1700) by @hubertdeng123
- Add section about error monitoring to the README (#1699) by @ethanhs
- Switch from .reporterrors file to flag + envvar (#1697) by @chadwhitacre
- Rename flag to --skip-user-creation (#1696) by @chadwhitacre
- Default to not sending data to Sentry for now (#1695) by @chadwhitacre
- fix(e2e tests): Pull branch that initially triggers gcp build for PRs (#1694) by @hubertdeng123
- fix(e2e tests): Add .reporterrors file for GCP run of e2e tests (#1691) by @hubertdeng123
- Error monitoring of the self-hosted installer (#1679) by @ethanhs
- added docker commands in the description (#1673) by @victorelec14
- Use docker-compose 2.7.0 instead of 2.2.3 in CI (#1591) by @aminvakil

## 22.8.0

- No documented changes.

## 22.7.0

### Various fixes & improvements

- ref: use sort -V to check minimum versions (#1553) by @ethanhs
- Get more data from users in issue templates (#1497) by @aminvakil
- Add ARM support (#1538) by @chadwhitacre
- do not use gosu for snuba-transactions-cleanup and snuba-cleanup (#1564) by @goganchic
- ref: Replace regex with --short flag to get compose version (#1551) by @ethanhs
- Improve installation through proxy (#1543) by @goganchic
- Cleanup .env{,.custom} handling (#1539) by @chadwhitacre
- Bump nginx:1.22.0-alpine (#1506) by @aminvakil
- Run release a new version job only on getsentry (#1529) by @aminvakil

## 22.6.0

### Various fixes & improvements

- fix "services.web.healthcheck.retries must be a number" (#1482) by @yuval1986
- Add volume for nginx cache (#1511) by @glensc
- snuba: New subscriptions infrastucture rollout (#1507) by @lynnagara
- Ease modification of base image (#1479) by @spawnia

## 22.5.0

### Various fixes & improvements

- ref: reset user to root for installation (#1469) by @asottile-sentry
- Document From email display name (#1446) by @chadwhitacre
- Bring in CLA Lite (#1439) by @chadwhitacre
- fix: replace git.io links with redirect targets (#1430) by @asottile-sentry

## 22.4.0

### Various fixes & improvements

- Use better API key when available (#1408) by @chadwhitacre
- Use a custom action (#1407) by @chadwhitacre
- Add some debug logging (#1340) by @chadwhitacre
- meta(gha): Deploy workflow enforce-license-compliance.yml (#1388) by @chadwhitacre
- Turn off containers under old name as well (#1384) by @chadwhitacre

## 22.3.0

### Various fixes & improvements

- Run CI every night (#1334) by @aminvakil
- Docker-Compose: Avoid setting hostname to '' (#1365) by @glensc
- meta(gha): Deploy workflow enforce-license-compliance.yml (#1375) by @chadwhitacre
- ci: Change stale GitHub workflow to run once a day (#1371) by @kamilogorek
- ci: Temporary fix for interactive prompt on createuser (#1370) by @BYK
- meta(gha): Deploy workflow enforce-license-compliance.yml (#1347) by @chadwhitacre
- Add SaaS nudge to README (#1327) by @chadwhitacre

## 22.2.0

### Various fixes & improvements

- fix: unbound variable _group in reset/dc-detect-version script (#1283) (#1284) by @lovetodream
- Remove routing helper (#1323) by @chadwhitacre
- Bump nginx:1.21.6-alpine (#1319) by @aminvakil
- Add a cloudbuild.yaml for GCB (#1315) by @chadwhitacre
- Update set-up-and-migrate-database.sh (#1308) by @drmrbrewer
- Pull relay explicitly to avoid garbage in creds (#1301) by @chadwhitacre
- Improve logging of docker versions and relay creds (#1298) by @chadwhitacre
- Remove file again (#1299) by @chadwhitacre
- Clean up relay credentials generation (#1289) by @chadwhitacre
- Add CI compose version 1.29.2 / 2.0.1 / 2.2.3 (#1290) by @chadwhitacre
- Revert "Add CI compose version 1.29.2 / 2.0.1 / 2.2.3 (#1251)" (#1272) by @chadwhitacre
- Add CI compose version 1.29.2 / 2.0.1 / 2.2.3 (#1251) by @aminvakil

## 22.1.0

### Various fixes & improvements

- Make healthcheck variables configurable in .env (#1248) by @aminvakil
- Take some actions to avoid unhealthy containers (#1241) by @chadwhitacre
- Install: setup umask (#1222) by @glensc
- Deprecated /docker-entrypoint.sh call (#1218) by @marcinroman
- Bump nginx:1.21.5-alpine (#1230) by @aminvakil
- Fix reset.sh docker-compose call (#1215) by @aminvakil
- Set worker_processes to auto (#1207) by @aminvakil

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
