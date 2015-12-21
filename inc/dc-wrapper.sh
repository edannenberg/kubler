#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DC_DIR="${SCRIPT_DIR}/../docker-compose"

source "${SCRIPT_DIR}/../run.conf" || exit 1

die()
{
    echo -e "$1"
    exit 1
}

# docker-compose wrapper, passes all arguments 
dc-wrapper()
{
    [ -z "${DC_FILE}" ] && die "error DC_FILE is not defined"
    echo -e "\n \
docker-compose file: ${DC_FILE}\n \
container-prefix: ${DC_PROJECT_NAME}\n \
restart-policy: ${DC_RESTART_POLICY}\n \
"
    docker-compose -f "${DC_FILE}" -p "${DC_PROJECT_NAME}" "$@"
}
