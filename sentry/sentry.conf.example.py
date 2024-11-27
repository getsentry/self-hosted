# This file is just Python, with a touch of Django which means
# you can inherit and tweak settings to your hearts content.

from sentry.conf.server import *  # NOQA

BYTE_MULTIPLIER = 1024
UNITS = ("K", "M", "G")


def unit_text_to_bytes(text):
    unit = text[-1].upper()
    power = UNITS.index(unit) + 1
    return float(text[:-1]) * (BYTE_MULTIPLIER**power)


# Generously adapted from pynetlinux: https://github.com/rlisagor/pynetlinux/blob/e3f16978855c6649685f0c43d4c3fcf768427ae5/pynetlinux/ifconfig.py#L197-L223
def get_internal_network():
    import ctypes
    import fcntl
    import math
    import socket
    import struct

    iface = b"eth0"
    sockfd = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    ifreq = struct.pack(b"16sH14s", iface, socket.AF_INET, b"\x00" * 14)

    try:
        ip = struct.unpack(
            b"!I", struct.unpack(b"16sH2x4s8x", fcntl.ioctl(sockfd, 0x8915, ifreq))[2]
        )[0]
        netmask = socket.ntohl(
            struct.unpack(b"16sH2xI8x", fcntl.ioctl(sockfd, 0x891B, ifreq))[2]
        )
    except IOError:
        return ()
    base = socket.inet_ntoa(struct.pack(b"!I", ip & netmask))
    netmask_bits = 32 - int(round(math.log(ctypes.c_uint32(~netmask).value + 1, 2), 1))
    return "{0:s}/{1:d}".format(base, netmask_bits)


INTERNAL_SYSTEM_IPS = (get_internal_network(),)


DATABASES = {
    "default": {
        "ENGINE": "sentry.db.postgres",
        "NAME": "postgres",
        "USER": "postgres",
        "PASSWORD": "",
        "HOST": "postgres",
        "PORT": "",
    }
}

# You should not change this setting after your database has been created
# unless you have altered all schemas first
SENTRY_USE_BIG_INTS = True

# If you're expecting any kind of real traffic on Sentry, we highly recommend
# configuring the CACHES and Redis settings

###########
# General #
###########

# Instruct Sentry that this install intends to be run by a single organization
# and thus various UI optimizations should be enabled.
SENTRY_SINGLE_ORGANIZATION = True

SENTRY_OPTIONS["system.event-retention-days"] = int(
    env("SENTRY_EVENT_RETENTION_DAYS", "90")
)

#########
# Redis #
#########

# Generic Redis configuration used as defaults for various things including:
# Buffers, Quotas, TSDB

SENTRY_OPTIONS["redis.clusters"] = {
    "default": {
        "hosts": {0: {"host": "redis", "password": "", "port": "6379", "db": "0"}}
    }
}

#########
# Queue #
#########

# See https://develop.sentry.dev/services/queue/ for more
# information on configuring your queue broker and workers. Sentry relies
# on a Python framework called Celery to manage queues.

rabbitmq_host = None
if rabbitmq_host:
    BROKER_URL = "amqp://{username}:{password}@{host}/{vhost}".format(
        username="guest", password="guest", host=rabbitmq_host, vhost="/"
    )
else:
    BROKER_URL = "redis://:{password}@{host}:{port}/{db}".format(
        **SENTRY_OPTIONS["redis.clusters"]["default"]["hosts"][0]
    )


#########
# Cache #
#########

# Sentry currently utilizes two separate mechanisms. While CACHES is not a
# requirement, it will optimize several high throughput patterns.

CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.memcached.PyMemcacheCache",
        "LOCATION": ["memcached:11211"],
        "TIMEOUT": 3600,
        "OPTIONS": {"ignore_exc": True},
    }
}

# A primary cache is required for things such as processing events
SENTRY_CACHE = "sentry.cache.redis.RedisCache"

DEFAULT_KAFKA_OPTIONS = {
    "bootstrap.servers": "kafka:9092",
    "message.max.bytes": 50000000,
    "socket.timeout.ms": 1000,
}

SENTRY_EVENTSTREAM = "sentry.eventstream.kafka.KafkaEventStream"
SENTRY_EVENTSTREAM_OPTIONS = {"producer_configuration": DEFAULT_KAFKA_OPTIONS}

KAFKA_CLUSTERS["default"] = DEFAULT_KAFKA_OPTIONS

###############
# Rate Limits #
###############

# Rate limits apply to notification handlers and are enforced per-project
# automatically.

SENTRY_RATELIMITER = "sentry.ratelimits.redis.RedisRateLimiter"

##################
# Update Buffers #
##################

# Buffers (combined with queueing) act as an intermediate layer between the
# database and the storage API. They will greatly improve efficiency on large
# numbers of the same events being sent to the API in a short amount of time.
# (read: if you send any kind of real data to Sentry, you should enable buffers)

SENTRY_BUFFER = "sentry.buffer.redis.RedisBuffer"

##########
# Quotas #
##########

# Quotas allow you to rate limit individual projects or the Sentry install as
# a whole.

SENTRY_QUOTAS = "sentry.quotas.redis.RedisQuota"

########
# TSDB #
########

# The TSDB is used for building charts as well as making things like per-rate
# alerts possible.

SENTRY_TSDB = "sentry.tsdb.redissnuba.RedisSnubaTSDB"

#########
# SNUBA #
#########

SENTRY_SEARCH = "sentry.search.snuba.EventsDatasetSnubaSearchBackend"
SENTRY_SEARCH_OPTIONS = {}
SENTRY_TAGSTORE_OPTIONS = {}

###########
# Digests #
###########

# The digest backend powers notification summaries.

SENTRY_DIGESTS = "sentry.digests.backends.redis.RedisBackend"

###################
# Metrics Backend #
###################

SENTRY_RELEASE_HEALTH = "sentry.release_health.metrics.MetricsReleaseHealthBackend"
SENTRY_RELEASE_MONITOR = (
    "sentry.release_health.release_monitor.metrics.MetricReleaseMonitorBackend"
)

##############
# Web Server #
##############

SENTRY_WEB_HOST = "0.0.0.0"
SENTRY_WEB_PORT = 9000
SENTRY_WEB_OPTIONS = {
    "http": "%s:%s" % (SENTRY_WEB_HOST, SENTRY_WEB_PORT),
    "protocol": "uwsgi",
    # This is needed in order to prevent https://github.com/getsentry/sentry/blob/c6f9660e37fcd9c1bbda8ff4af1dcfd0442f5155/src/sentry/services/http.py#L70
    "uwsgi-socket": None,
    "so-keepalive": True,
    # Keep this between 15s-75s as that's what Relay supports
    "http-keepalive": 15,
    "http-chunked-input": True,
    # the number of web workers
    "workers": 3,
    "threads": 4,
    "memory-report": False,
    # Some stuff so uwsgi will cycle workers sensibly
    "max-requests": 100000,
    "max-requests-delta": 500,
    "max-worker-lifetime": 86400,
    # Duplicate options from sentry default just so we don't get
    # bit by sentry changing a default value that we depend on.
    "thunder-lock": True,
    "log-x-forwarded-for": False,
    "buffer-size": 32768,
    "limit-post": 209715200,
    "disable-logging": True,
    "reload-on-rss": 600,
    "ignore-sigpipe": True,
    "ignore-write-errors": True,
    "disable-write-exception": True,
}

###########
# SSL/TLS #
###########

# If you're using a reverse SSL proxy, you should enable the X-Forwarded-Proto
# header and enable the settings below

# SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
# USE_X_FORWARDED_HOST = True
# SESSION_COOKIE_SECURE = True
# CSRF_COOKIE_SECURE = True
# SOCIAL_AUTH_REDIRECT_IS_HTTPS = True

# End of SSL/TLS settings

########
# Mail #
########

SENTRY_OPTIONS["mail.list-namespace"] = env("SENTRY_MAIL_HOST", "localhost")
SENTRY_OPTIONS["mail.from"] = f"sentry@{SENTRY_OPTIONS['mail.list-namespace']}"

############
# Features #
############

SENTRY_FEATURES["projects:sample-events"] = False
SENTRY_FEATURES.update(
    {
        feature: True
        for feature in (
            "organizations:discover",
            "organizations:events",
            "organizations:global-views",
            "organizations:incidents",
            "organizations:integrations-issue-basic",
            "organizations:integrations-issue-sync",
            "organizations:invite-members",
            "organizations:metric-alert-builder-aggregate",
            "organizations:sso-basic",
            "organizations:sso-rippling",
            "organizations:sso-saml2",
            "organizations:performance-view",
            "organizations:advanced-search",
            "organizations:session-replay",
            "organizations:issue-platform",
            "organizations:profiling",
            "organizations:monitors",
            "organizations:dashboards-mep",
            "organizations:mep-rollout-flag",
            "organizations:dashboards-rh-widget",
            "organizations:metrics-extraction",
            "organizations:transaction-metrics-extraction",
            "projects:custom-inbound-filters",
            "projects:data-forwarding",
            "projects:discard-groups",
            "projects:plugins",
            "projects:rate-limits",
            "projects:servicehooks",
        )
        # Starfish related flags
        + (
            "organizations:deprecate-fid-from-performance-score",
            "organizations:indexed-spans-extraction",
            "organizations:insights-entry-points",
            "organizations:insights-initial-modules",
            "organizations:insights-addon-modules",
            "organizations:mobile-ttid-ttfd-contribution",
            "organizations:performance-calculate-score-relay",
            "organizations:standalone-span-ingestion",
            "organizations:starfish-browser-resource-module-image-view",
            "organizations:starfish-browser-resource-module-ui",
            "organizations:starfish-browser-webvitals",
            "organizations:starfish-browser-webvitals-pageoverview-v2",
            "organizations:starfish-browser-webvitals-replace-fid-with-inp",
            "organizations:starfish-browser-webvitals-use-backend-scores",
            "organizations:starfish-mobile-appstart",
            "projects:span-metrics-extraction",
            "projects:span-metrics-extraction-addons",
        )
        # User Feedback related flags
        + (
            "organizations:user-feedback-ingest",
            "organizations:user-feedback-replay-clip",
            "organizations:user-feedback-ui",
        )
    }
)

#######################
# MaxMind Integration #
#######################

GEOIP_PATH_MMDB = "/geoip/GeoLite2-City.mmdb"

#########################
# Bitbucket Integration #
#########################

# BITBUCKET_CONSUMER_KEY = 'YOUR_BITBUCKET_CONSUMER_KEY'
# BITBUCKET_CONSUMER_SECRET = 'YOUR_BITBUCKET_CONSUMER_SECRET'

##############################################
# Content Security Policy settings
##############################################

# CSP_REPORT_URI = "https://{your-sentry-installation}/api/{csp-project}/security/?sentry_key={sentry-key}"
CSP_REPORT_ONLY = True

# optional extra permissions
# https://django-csp.readthedocs.io/en/latest/configuration.html
# CSP_SCRIPT_SRC += ["example.com"]

#################
# CSRF Settings #
#################

# Since version 24.1.0, Sentry migrated to Django 4 which contains stricter CSRF protection.
# If you are accessing Sentry from multiple domains behind a reverse proxy, you should set
# this to match your IPs/domains. Ports should be included if you are using custom ports.
# https://docs.djangoproject.com/en/4.2/ref/settings/#std-setting-CSRF_TRUSTED_ORIGINS

# CSRF_TRUSTED_ORIGINS = ["https://example.com", "http://127.0.0.1:9000"]

#################
# JS SDK Loader #
#################

# Configure Sentry JS SDK bundle URL template for Loader Scripts.
# Learn more about the Loader Scripts: https://docs.sentry.io/platforms/javascript/install/loader/
# If you wish to host your own JS SDK bundles, set `SETUP_JS_SDK_ASSETS` environment variable to `1`
# on your `.env` or `.env.custom` file. Then, replace the value below with your own public URL.
# For example: "https://sentry.example.com/js-sdk/%s/bundle%s.min.js"
#
# By default, the previous JS SDK assets version will be pruned during upgrades, if you wish
# to keep the old assets, set `SETUP_JS_SDK_KEEP_OLD_ASSETS` environment variable to any value on
# your `.env` or `.env.custom` file. The files should only be a few KBs, and this might be useful
# if you're using it directly like a CDN instead of using the loader script.
JS_SDK_LOADER_DEFAULT_SDK_URL = "https://browser.sentry-cdn.com/%s/bundle%s.min.js"


# If you would like to use self-hosted Sentry with only errors enabled, please set this
SENTRY_SELF_HOSTED_ERRORS_ONLY = env("COMPOSE_PROFILES") != "feature-complete"

#####################
# Insights Settings #
#####################

# Since version 24.3.0, Insights features are available on self-hosted. For Requests module,
# there are scrubbing logic done on Relay to prevent high cardinality of stored HTTP hosts.
# However in self-hosted scenario, the amount of stored HTTP hosts might be consistent,
# and you may have allow list of hosts that you want to keep. Uncomment the following line
# to allow specific hosts. It might be IP addresses or domain names (without `http://` or `https://`).

# SENTRY_OPTIONS["relay.span-normalization.allowed_hosts"] = ["example.com", "192.168.10.1"]
