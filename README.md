# Sentry 10 On-Premise BETA [![Build Status][build-status-image]][build-status-url]

Official bootstrap for running your own [Sentry](https://sentry.io/) with [Docker](https://www.docker.com/).

**NOTE:** If you are not installing Sentry from scratch, our recommendation is to visit [On-Premise Stable for Sentry 9.1.2](https://github.com/getsentry/onpremise/tree/stable) as this version may not be fully backward compatible. If you still want to try it out make sure you are on 9.1.2 first, back up your old Docker volumes just in case, and remember that if you haven't set up Redis persistency yourself some of your data (like your stats) may be lost during the upgrade.

## Requirements

 * Docker 17.05.0+
 * Compose 1.19.0+

## Minimum Hardware Requirements:

 * You need at least 2400MB RAM

## Setup

To get started with all the defaults, simply clone the repo and run `./install.sh` in your local check-out.

There may need to be modifications to the included example config files (`sentry/config.example.yml` and `sentry/sentry.conf.example.py`) to accommodate your needs or your environment (such as adding GitHub credentials). If you want to perform these, do them before you run the install script and copy them without the `.example` extensions in the name (such as `sentry/sentry.conf.py`) before running the `install.sh` script.

The recommended way to customize your configuration is using the files below, in that order:

 * `config.yml`
 * `sentry.conf.py`
 * `.env` w/ environment variables

We currently support a very minimal set of environment variables to promote other means of configuration.

If you have any issues or questions, our [Community Forum](https://forum.sentry.io/c/on-premise) is at your service!

## Event Retention

Sentry comes with a cleanup cron job that prunes events older than `90 days` by default. If you want to change that, you can change the `SENTRY_EVENT_RETENTION_DAYS` environment variable in `.env` or simply override it in your environment. If you do not want the cleanup cron, you can remove the `sentry-cleanup` service from the `docker-compose.yml`file.

## Securing Sentry with SSL/TLS

If you'd like to protect your Sentry install with SSL/TLS, there are
fantastic SSL/TLS proxies like [HAProxy](http://www.haproxy.org/)
and [Nginx](http://nginx.org/). You'll likely want to add this service to your `docker-compose.yml` file.

## Updating Sentry

Updating Sentry using Compose is relatively simple. Just use the following steps to update. Make sure that you have the latest version set in your Dockerfile. Or use the latest version of this repository.

Use the following steps after updating this repository or your Dockerfile:
```sh
docker-compose build --pull # Build the services again after updating, and make sure we're up to date on patch version
docker-compose run --rm web upgrade # Run new migrations
docker-compose up -d # Recreate the services
```

## Resources

 * [Documentation](https://docs.sentry.io/server/installation/docker/)
 * [Bug Tracker](https://github.com/getsentry/onpremise/issues)
 * [Forums](https://forum.sentry.io/c/on-premise)
 * [IRC](irc://chat.freenode.net/sentry) (chat.freenode.net, #sentry)


[build-status-image]: https://api.travis-ci.com/getsentry/onpremise.svg?branch=master
[build-status-url]: https://travis-ci.com/getsentry/onpremise
