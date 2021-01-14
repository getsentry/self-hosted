#!/usr/bin/env bash

if [ ! -f 'install.sh' ]; then echo 'Where are you?'; exit 1; fi

source ./install/docker-aliases.sh

py2_warning() {
    $dcr --no-deps --entrypoint python web --version | grep -q 'Python 2'
    if [[ $? -eq 0 ]]; then
    cat <<"EOW"
 _  _   ____      ____  _       _______     ____  _____  _____  ____  _____   ______   _  _
| || | |_  _|    |_  _|/ \     |_   __ \   |_   \|_   _||_   _||_   \|_   _|.' ___  | | || |
| || |   \ \  /\  / / / _ \      | |__) |    |   \ | |    | |    |   \ | | / .'   \_| | || |
| || |    \ \/  \/ / / ___ \     |  __ /     | |\ \| |    | |    | |\ \| | | |   ____ | || |
|_||_|     \  /\  /_/ /   \ \_  _| |  \ \_  _| |_\   |_  _| |_  _| |_\   |_\ `.___]  ||_||_|
(_)(_)      \/  \/|____| |____||____| |___||_____|\____||_____||_____|\____|`._____.' (_)(_)

EOW
        echo 'You are using Sentry with Python 2, which is deprecated.'
        echo 'Sentry 21.1 will be the last version with Python 2 support.'
    fi
}

py2_warning
# Run a simple command that would exit with code 0 so the calling script won't think
# there was a failure in this script. (otherwise it fails when Python 2 is *NOT* detected)
# as the exit code for the `grep` call will be `-1` indicating no match found.
echo ''
