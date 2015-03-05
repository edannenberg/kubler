#!/bin/bash
#
# Copyright (C) 2014-2015 Erik Dannenberg <erik.dannenberg@bbe-consulting.de>
#
# Push images to repository, auth credentials are read from dock/<namespace>/push.conf
#
# Docker specific: 
#    If -h param is omitted docker.io is assumed as repository
#    vars for push.conf: DOCKER_LOGIN, DOCKER_PW, DOCKER_EMAIL
#
# Usage: ./push.sh -h my-repository.org:5000 [namespace/image] or [namespace] ...

show_help() {
    echo -e "usage: ./push.sh -h my-repository.org:5000 [namespace/image] or [namespace] ...\n"
    exit 0
}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT=$(realpath -s $SCRIPT_DIR)

[ ! -f "${PROJECT_ROOT}/inc/core.sh" ] && echo "error: failed to read ${PROJECT_ROOT}/inc/core.sh" && exit 1
source "${PROJECT_ROOT}/inc/core.sh"

[[ ! -f "${PROJECT_ROOT}/build.conf" ]] && die "error: failed to read build.conf"
source "${PROJECT_ROOT}/build.conf"

DATE_ROOT="${DATE?Error \$DATE is not defined.}"

REPOSITORY_URL=""
while getopts "h:" opt; do
  case $opt in
    h)
      REPOSITORY_URL=${OPTARG}
      ;;
  esac
done
shift $(( $OPTIND -1 ))

[ "$1" = "--" ] && shift

[ -z "${1}" ] && show_help

REPO_ARGS="${@:-"*"}"

cd "${REPO_PATH}"
REPOS=$(expand_requested_repos "${REPO_ARGS}") || die "error expanding repos: ${REPO_ARGS}"

for REPO in $REPOS; do
    NAMESPACE=${REPO%%/*}
    REPO_EXPANDED=${REPO/\//\/${IMAGE_PATH}}
    source_namespace_conf "$REPO_EXPANDED"
    source_push_conf "${REPO}"

    if ! image_exists $REPO; then
        echo "skipping ${REPO}:${DATE}, image is not build yet"
        continue
    fi

    if [[ "${LAST_PUSH_AUTH_NS}" != ${NAMESPACE} ]]; then
        push_auth "${NAMESPACE}" "${REPOSITORY_URL}" || die "error while logging into repository"
        LAST_PUSH_AUTH_NS=${NAMESPACE}
    fi

    push_image "${REPO}" "${REPOSITORY_URL}"
done
