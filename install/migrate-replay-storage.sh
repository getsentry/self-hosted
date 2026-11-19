echo "${_group}Migrating Session Replay recordings storage ..."

# Session Replay recordings used to go to the default filestore (`/data/files`) because
# `replay.storage.backend` was not set. Sentry writes them straight to storage, without
# `File` rows, so `sentry cleanup` never deletes them and they piled up forever.
#
# They now live in `/data/replays`, which the `sentry-cleanup` container prunes after
# `SENTRY_EVENT_RETENTION_DAYS`. On upgrade, this points `replay.storage.*` there and moves
# existing recordings over so they keep playing back and expire like new ones.

move_replay_recordings=0
if ! grep -q "replay.storage.backend" $SENTRY_CONFIG_YML; then
  apply_config_changes_replays=0
  if [[ -z "$APPLY_AUTOMATIC_CONFIG_UPDATES" ]]; then
    echo
    echo "Session Replay recordings are moving from '/data/files' to '/data/replays',"
    echo "so they are deleted automatically once they pass the retention period."
    echo "To complete this, your sentry/config.yml file needs to be modified and existing"
    echo "recordings need to be moved to the new directory."
    echo "Would you like us to perform this modification automatically?"
    echo

    yn=""
    until [ ! -z "$yn" ]; do
      read -p "y or n? " yn
      case $yn in
      y | yes | 1)
        export apply_config_changes_replays=1
        echo
        echo -n "Thank you."
        ;;
      n | no | 0)
        export apply_config_changes_replays=0
        echo
        echo -n "Alright, replay recordings will keep going to '/data/files' and will not be deleted automatically."
        ;;
      *) yn="" ;;
      esac
    done

    echo
    echo "To avoid this prompt in the future, use one of these flags:"
    echo
    echo "  --apply-automatic-config-updates"
    echo "  --no-apply-automatic-config-updates"
    echo
    echo "or set the APPLY_AUTOMATIC_CONFIG_UPDATES environment variable:"
    echo
    echo "  APPLY_AUTOMATIC_CONFIG_UPDATES=1 to apply automatic updates"
    echo "  APPLY_AUTOMATIC_CONFIG_UPDATES=0 to not apply automatic updates"
    echo
    sleep 5
  fi

  if [[ "$APPLY_AUTOMATIC_CONFIG_UPDATES" == 1 || "$apply_config_changes_replays" == 1 ]]; then
    replays_config=$(sed -n "/^replay.storage.backend/,/location: '\/data\/replays'/{p}" sentry/config.example.yml)
    echo "$replays_config" >>$SENTRY_CONFIG_YML
    move_replay_recordings=1
  fi
fi

# Recordings in `/data/files` are stored as <retention_days>/<project_id>/<replay_id>/<segment_id>.
# Regular file blobs are stored as <2 hex>/<4 hex>/<26 hex> files, so they never match a
# <replay_id> directory at the third level and are left alone.
$dcr --no-deps -e MOVE_REPLAY_RECORDINGS=$move_replay_recordings --entrypoint python3 web -c '
import os
import re
import shutil

SOURCE = "/data/files"
TARGET = "/data/replays"
NUMBER = re.compile(r"[0-9]+")
REPLAY_ID = re.compile(r"[0-9a-f]{32}")


def subdirs(path, pattern):
    return [e for e in os.scandir(path) if e.is_dir() and pattern.fullmatch(e.name)]


os.makedirs(TARGET, exist_ok=True)

if os.environ["MOVE_REPLAY_RECORDINGS"] == "1" and os.path.isdir(SOURCE):
    moved = 0
    for retention in subdirs(SOURCE, NUMBER):
        for project in subdirs(retention.path, NUMBER):
            for replay in subdirs(project.path, REPLAY_ID):
                destination = os.path.join(TARGET, retention.name, project.name, replay.name)
                if os.path.exists(destination):
                    continue
                os.makedirs(os.path.dirname(destination), exist_ok=True)
                shutil.move(replay.path, destination)
                moved += 1
            try:
                os.rmdir(project.path)
            except OSError:
                pass
    print(f"Moved {moved} replay recordings from {SOURCE} to {TARGET}.")
'

echo "${_endgroup}"
