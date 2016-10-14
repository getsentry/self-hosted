# Sentry On-Premise

Official bootstrap for running your own [Sentry](https://sentry.io/) with [Docker](https://www.docker.com/).

## Requirements

 * Docker 1.10.0+
 * Compose 1.6.0+ _(optional)_

## Up and Running

Assuming you've just cloned this repository, the following steps 
will get you up and running in no time!

1. `mkdir -p data/{sentry,postgres}` - Make our local database and sentry config directories.
    This directory is bind-mounted with postgres so you don't lose state!
2. `docker-compose run web config generate-secret-key` - Generate a secret key.
    Add it to `docker-compose.yml` in `base` as `SENTRY_SECRET_KEY`.
3. `docker-compose run web upgrade` - Build the database.
    Use the interactive prompts to create a user account.
4. `docker-compose up -d` - Lift all services (detached/background mode).
5. Access your instance at `localhost:9000`!

Note that as long as you have your database bind-mounted, you should
be fine stopping and removing the containers without worry.

## Backing up postgres

Following with the trend of containers, you could even add something like
[this](https://github.com/InAnimaTe/docker-postgres-s3-archive) to 
backup postgres to an AWS S3 bucket:

```
  postgresqlbackup:
    image: inanimate/postgres-s3-archive:9.5
    restart: always
    links:
        - postgres:postgres 
    environment:
        - "AWS_ACCESS_KEY_ID=PUTACCESSIDHERE"
        - "AWS_SECRET_ACCESS_KEY=PUTSECRETKEYHERE"
        - "BUCKET=s3://awesomebackupsbucket/sentry"
        - "SYMMETRIC_PASSPHRASE=hahacanthaxme"
        - "NAME_PREFIX=sentry-database-backup"
        - "PGHOST=postgres"
        - "PGPORT=5432"
```

This container runs `pgdump` to take snapshots of your database on a
certain time frame. You could also use other backup facilities on the 
host which you're running the containers.

## Reverse Proxying (SSL/TLS)

The absolute easiest way to get SSL/TLS protecting your Sentry server is
to use [Caddy](https://caddyserver.com/). Caddy will handle automatic
SSL certificate obtainment and renewal from
[Let's Encrypt](https://letsencrypt.org/) for you.

Here is an example `Caddyfile` configuration:

```
sentry.example.net {
    proxy / web:9000 {
        transparent
    }
    tls {
        max_certs 1
    }
}
```

The above would work with a caddy entry in `docker-compose.yml` like:

```
caddy:
    image: abiosoft/caddy:0.9.3
    restart: always
    volumes:
        - ./Caddyfile:/etc/Caddyfile
        - ./caddydata:/root/.caddy
    ports:
        - "80:80"
        - "443:443"
    links:
        - web

```

## Resources

 * [Documentation](https://docs.sentry.io/server/installation/docker/)
 * [Bug Tracker](https://github.com/getsentry/onpremise)
 * [Forums](https://forum.sentry.io/c/on-premise)
 * [IRC](irc://chat.freenode.net/sentry) (chat.freenode.net, #sentry)
