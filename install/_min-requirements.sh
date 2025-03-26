# Don't forget to update the README and other docs when you change these!
MIN_DOCKER_VERSION='19.03.6'
MIN_COMPOSE_VERSION='2.32.2'

# 16 GB minimum host RAM, but there'll be some overhead outside of what
# can be allotted to docker
if [[ "$COMPOSE_PROFILES" == "errors-only" ]]; then
  MIN_RAM_HARD=7000 # MB
  MIN_CPU_HARD=2
else
  MIN_RAM_HARD=14000 # MB
  MIN_CPU_HARD=4
fi
