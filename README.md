# Sentry On-Premise

Official bootstrap for running your own [Sentry](https://getsentry.com/) with [Docker](https://www.docker.com/).

## Requirements

 * Docker 1.10.0+
 * Compose 1.6.0+ _(optional)_

## Up and Running

The following steps will get you up and running in no time!

1. `docker-compose run web sentry config generate-secret-key` - Generate a
   secret key unique to your deployment.
2. Edit `docker-compose.yml` inserting the key via `SENTRY_SECRET_KEY`
3. `docker-compose run web upgrade` Prime the Database!
4. `docker-compose up -d` Launch!

## Resources

 * [Documentation](https://docs.getsentry.com/on-premise/server/installation/docker/)
 * [Bug Tracker](https://github.com/getsentry/onpremise)
 * [IRC](irc://chat.freenode.net/sentry) (chat.freenode.net, #sentry)
