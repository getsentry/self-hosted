echo "${_group}Ensuring sentry-data volume ownership ..."

# Sentry containers run as the non-root `sentry` user (uid 999). Older sentry
# images fixed /data ownership at every container start while running as root;
# do it once here instead. This uses python3 rather than shell tools so it keeps
# working on images without a shell.
$dcr --no-deps --user 0 --entrypoint python3 web -c '
import os

SENTRY_UID = 999


def fail(error):
    raise error


os.makedirs("/data/files", exist_ok=True)
if any(os.stat(p).st_uid != SENTRY_UID for p in ("/data", "/data/files")):
    for root, dirs, files in os.walk("/data", topdown=False, onerror=fail):
        for path in (*(os.path.join(root, name) for name in dirs + files), root):
            if os.lstat(path).st_uid != SENTRY_UID:
                os.lchown(path, SENTRY_UID, -1)
'

echo "${_endgroup}"
