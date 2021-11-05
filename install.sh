#!/usr/bin/env bash
set -e
exec &> >(tee -a "foo.log")
docker compose --ansi never run --rm web upgrade
