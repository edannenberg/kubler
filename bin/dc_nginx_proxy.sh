#!/bin/bash
set -a

# If you want to override variables defined in run.conf, while stile providing
# POSIX parameter expansion, override before sourcing the wrapper script.

# docker-compose project name, essentially the container name prefix. no white space!
DC_PROJECT_NAME="${DC_PROJECT_NAME:-proxy}"

# source generic wrapper script and defaults from run.conf
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/../inc/dc-wrapper.sh" || exit 1

# docker-compose file location
DC_FILE="${DC_DIR}/nginx_proxy.yml"

# services config
PROXY_CERT_PATH="${PROCY_CERT_PATH:-${DC_DATA_ROOT}/${DC_PROJECT_NAME}/certs/}"

dc-wrapper "$@"
