#!/usr/bin/env sh

# Note: pipefail is not supported in POSIX shell and will be silently ignored, unless bash is used
set -eo pipefail
#set -x

# Do some tests and exit with either 0 for success or 1 for error
echo "Fix me or this built-test.sh will never succeed!"
false || exit 1

exit 0
