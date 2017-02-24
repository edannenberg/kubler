#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${SCRIPT_DIR}/../run.conf" || exit 1

DC_DIR="$(realpath ${SCRIPT_DIR}/../docker-compose)"
DC_DATA_ROOT="$(realpath ${DC_DATA_ROOT})"

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
docker-compose file:\t ${DC_FILE}\n \
container-prefix:\t ${DC_PROJECT_NAME}\n \
restart-policy:\t ${DC_RESTART_POLICY}\n \
"

    # display msg first if not in detached mode..
    if [[ "$1" == "up" ]] && [[ "$2" != "-d" ]]; then
        echo -e "${STARTUP_MSG}\n"
    fi

    docker-compose -f "${DC_FILE}" -p "${DC_PROJECT_NAME}" "$@"

    # ..else display it after docker-compose
    if [[ "$1" == "up" ]] && [[ "$2" == "-d" ]] || [[ "$1" == "start" ]]; then
        echo -e "\n${STARTUP_MSG}\n"
    fi
}
