#!/usr/bin/env bash

if [[ ! -f 'install.sh' ]]; then echo 'Where are you?'; exit 1; fi
echo "A"
source ./install/docker-aliases.sh
echo "B"
if echo "C" && $dcr --no-deps --entrypoint python web --version | grep -q 'Python 2'; then
echo "D";
  WARNING_TEXT="
 _  _   ____      ____  _       _______     ____  _____  _____  ____  _____   ______   _  _
| || | |_  _|    |_  _|/ \     |_   __ \   |_   \|_   _||_   _||_   \|_   _|.' ___  | | || |
| || |   \ \  /\  / / / _ \      | |__) |    |   \ | |    | |    |   \ | | / .'   \_| | || |
| || |    \ \/  \/ / / ___ \     |  __ /     | |\ \| |    | |    | |\ \| | | |   ____ | || |
|_||_|     \  /\  /_/ /   \ \_  _| |  \ \_  _| |_\   |_  _| |_  _| |_\   |_\ \`.___]  ||_||_|
(_)(_)      \/  \/|____| |____||____| |___||_____|\____||_____||_____|\____|\`._____.' (_)(_)

"
echo "E"
  echo "$WARNING_TEXT"
echo "F"
  echo '-----------------------------------------------------------'
  echo 'You are using Sentry with Python 2, which is deprecated.'
  echo 'Sentry 21.1 will be the last version with Python 2 support.'
fi
