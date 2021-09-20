#!/bin/sh
set -e

echo "$CLEAN_SCHEDULE /cleanup-registry.sh" > /tmp/crontab

exec "$@"
