#!/usr/bin/env bash

# take care of some boiler plate for interactive build containers

# setup portage
# shellcheck disable=SC1091
source /etc/profile

# shellcheck disable=SC1091
source /config/build.sh
# shellcheck disable=SC1091
source /usr/local/bin/kubler-build-root --source-mode
