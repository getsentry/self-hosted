# Sentry On-Premise

Official bootstrap for running your own [Sentry](https://getsentry.com/) with [Docker](https://www.docker.com/).

## Requirements

 * Docker 1.10.0+
 * Compose 1.6.0+ _(optional)_

## Usage

```bash
# generate secret key
$ docker-compose run --rm web config generate-secret-key
$ export SENTRY_SECRET_KEY='your-secret-key'

# init or upgrade
$ docker-compose run --rm web upgrade

# run in the background
$ docker-compose up -d
```

## Resources

 * [Documentation](https://docs.getsentry.com/on-premise/server/installation/docker/)
 * [Bug Tracker](https://github.com/getsentry/onpremise)
 * [IRC](irc://chat.freenode.net/sentry) (chat.freenode.net, #sentry)
