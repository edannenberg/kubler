#!/bin/bash

if [ -z $1 ]; then
    echo "usage: bob-interactive-sh <namespace/image>"
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT=$(realpath -s $SCRIPT_DIR/../)
REPO=${1}
REPO_DIR=$(realpath -s $SCRIPT_DIR/../dock/${REPO/\//\/images\/})
[ ! -d $REPO_DIR ] && echo "error: can't find ${REPO_DIR}" && exit 1

[ ! -f "${PROJECT_ROOT}/inc/core.sh" ] && echo "error: failed to read ${PROJECT_ROOT}/inc/core.sh" && exit 1
source "${PROJECT_ROOT}/inc/core.sh"

[[ ! -f "${PROJECT_ROOT}/build.conf" ]] && die "error: failed to read build.conf"
source "${PROJECT_ROOT}/build.conf"

DATE_ROOT="${DATE?Error \$DATE is not defined.}"

cd ${PROJECT_ROOT}/${REPO_PATH}
source_namespace_conf ${REPO}
validate_engine

BUILDER=$(get_build_container ${REPO} ${IMAGE_PATH})
[[ $? == 1 ]] && die "error while executing get_image_builder(): ${BUILDER}"

image_exists "${BUILDER}" "${IMAGE_PATH}" || die "error could not find image ${BUILDER}"

# pass variables starting with BOB_ to build container as ENV
for bob_var in ${!BOB_*}; do
    CONTAINER_ENV+=("${bob_var}=${!bob_var}")
done

CONTAINER_MOUNTS=(
"$(realpath -s $SCRIPT_DIR/../tmp/distfiles):/distfiles"
"$(realpath -s $SCRIPT_DIR/../tmp/packages):/packages"
"${REPO_DIR}:/config"
)

CONTAINER_CMD=("/bin/bash")

msg "using: ${CONTAINER_ENGINE} / builder: ${BUILDER}"
echo -e "\nrunning interactive build container with ${REPO_DIR} mounted as /config\nartifacts from previous builds: /backup-rootfs\n"
echo -e "to start the build: $ build-root ${REPO}"
echo -e "*** if you plan to run emerge manually, source /etc/profile first ***\n"

run_image "${BUILDER}" "${BUILDER}" "true"
