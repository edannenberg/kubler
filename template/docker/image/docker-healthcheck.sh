#!/usr/bin/env sh

# Note: pipefail is not supported in POSIX shell and will be silently ignored, unless bash is used
set -eo pipefail

# Do some tests and exit with either 0 for healthy or 1 for unhealthy
echo "Fix me or this docker-healthcheck.sh will never succeed!"
false || exit 1

exit 0
