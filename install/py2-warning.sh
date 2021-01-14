#!/usr/bin/env bash

if [ ! -f 'install.sh' ]; then echo 'Where are you?'; exit 1; fi

source ./install/docker-aliases.sh

py2_warning() {
  local IS_PYTHON2=$($dcr --no-deps --entrypoint python web --version | grep 'Python 2')
  if [[ -n "$IS_PYTHON2" ]]; then
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
