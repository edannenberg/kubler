#!/bin/bash
#
# Push all images in $REPO_PATH to docker.io or a private registry, if no argument is passed docker.io is assumed
#
# To avoid login prompts for docker.io put the credentials into push.conf alongside push.sh. DOCKER_LOGIN, DOCKER_PW, DOCKER_EMAIL
#
# Usage: ./push.sh [my-registry.org:5000]

NAMESPACE="${NAMESPACE:-gentoobb}"
DATE="${DATE:-20141204}"
REPO_PATH="${REPO_PATH:-bb-dock}"

DOCKER_IO=$(command -v docker.io)
DOCKER="${DOCKER:-${DOCKER_IO:-docker}}"

if [ -f push.conf ]; then
    source push.conf
fi

REGISTRY="${1}"
if [[ -z "${REGISTRY}" ]]; then
    DOCKER_LOGIN="${DOCKER_LOGIN:-${NAMESPACE}}"
    echo "pushing to docker.io/u/${DOCKER_LOGIN}"
    LOGIN_ARGS="-u ${DOCKER_LOGIN}"
    if [ ! -z ${DOCKER_PW} ]; then
        LOGIN_ARGS+=" -p ${DOCKER_PW}"
    fi
    if [ ! -z ${DOCKER_EMAIL} ]; then
        LOGIN_ARGS+=" -e ${DOCKER_EMAIL}"
    fi
    ${DOCKER} login $LOGIN_ARGS || exit 1
else
    echo "pushing to ${REGISTRY}"
fi

image_exists()
{
    REPO="${1}"
    IMAGES=$("${DOCKER}" images "${NAMESPACE}/${REPO}")
    MATCHES=$(echo "${IMAGES}" | grep "${DATE}")
    if [ -z "${MATCHES}" ]; then
        return 1
    fi
    return 0
}

cd $REPO_PATH
for REPO in *; do
    if ! image_exists $REPO; then
        echo "skipping ${NAMESPACE}/${REPO}:${DATE}"
        continue
    fi
    PUSH_ARGS="${NAMESPACE}/${REPO}"
    if [[ ! -z "${REGISTRY}" ]]; then
        IMAGE_ID=$("${DOCKER}" images "${NAMESPACE}/${REPO}" | grep "${DATE}" | awk '{print $3}')
        PUSH_ARGS="${REGISTRY}/${NAMESPACE}/${REPO}"
        echo "${DOCKER}" tag -f "${IMAGE_ID}" ${PUSH_ARGS}
        "${DOCKER}" tag -f "${IMAGE_ID}" "${PUSH_ARGS}" || exit 1
    fi
    echo "pushing ${PUSH_ARGS}"
    "${DOCKER}" push "${PUSH_ARGS}" || exit 1
done
