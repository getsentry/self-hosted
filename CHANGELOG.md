# Changelog

## Unreleased

- BREAKING CHANGE: The frontend bundle will be loaded asynchronously. This is a breaking change that can affect custom plugins that access certain globals in the django template. Please see https://forum.sentry.io/t/breaking-frontend-changes-for-custom-plugins/14184 for more information.

## 21.6.1

- No documented changes.

## 21.6.0

- feat: Add healthchecks for redis, memcached and postgres (#975)

