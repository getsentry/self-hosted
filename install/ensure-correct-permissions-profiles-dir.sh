#!/bin/bash

$dc up --wait vroom
$dc exec vroom chown -R 1000:1000 /var/lib/sentry-profiles
$dc down vroom
