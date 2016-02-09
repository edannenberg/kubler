#!/bin/bash
#
# Copyright (C) 2014-2015 Erik Dannenberg <erik.dannenberg@bbe-consulting.de>
#
# Based on https://github.com/wking/dockerfile/blob/master/build.sh
#
# --- original license and (C):
#
# Copyright (C) 2013-2014 W. Trevor King <wking@tremily.us>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

REALPATH="${REALPATH:-$(command -v realpath)}"
if [ -z "${REALPATH}" ]; then
    READLINK="${READLINK:-$(command -v readlink)}"
    if [ -n "${READLINK}" ]; then
        REALPATH="${READLINK} -f"
    else
        die "need realpath or readlink to canonicalize paths"
    fi
fi

PROJECT_ROOT=$(dirname $(realpath -s $0))
DL_PATH="${DL_PATH:-${PROJECT_ROOT}/tmp/downloads}"

# read global build.conf
[[ ! -f "${PROJECT_ROOT}/build.conf" ]] && echo "error: could not find ${PROJECT_ROOT}//build.conf" && exit 1
source ./build.conf

DATE_ROOT="${DATE?Error \$DATE is not defined.}"
NAMESPACE_ROOT="${NAMESPACE:-gentoobb}"

BUILD_OPTS="${BUILD_OPTS:-}"

SKIP_GPG="${SKIP_GPG:-false}"
EXCLUDE="${EXCLUDE:-}"

REQUIRED_BINARIES="awk bzip2 grep sha512sum wget"
[ "${SKIP_GPG}" != "false" ] && REQUIRED_BINARIES+=" gpg"

[ ! -f "${PROJECT_ROOT}/inc/core.sh" ] && echo "error: Could not find ${PROJECT_ROOT}/inc/core.sh" && exit 1
source "${PROJECT_ROOT}/inc/core.sh"

# Populate BUILD_ORDER by checking image dependencies
#
# Arguments:
#
# 1: REPOS
generate_build_order()
{
    # generate image build order
    REQUIRED_BUILDER=""
    REQUIRED_ENGINES=""
    for REPO in $1; do
        check_image_dependencies ${REPO}
        if [ -z "$BUILD_ORDER" ]; then
            BUILD_ORDER="${REPO}"
        else
            ! string_has_word "${BUILD_ORDER}" ${REPO} && BUILD_ORDER+=" ${REPO}"
        fi
    done
    # generate builder build order
    BUILD_ORDER_BUILDER=""
    for BUILDER in $REQUIRED_BUILDER; do
        check_builder_dependencies ${BUILDER}
        if [ -z "$BUILD_ORDER_BUILDER" ]; then
            BUILD_ORDER_BUILDER="${BUILDER}"
        else
            ! string_has_word "${BUILD_ORDER_BUILDER}" ${BUILDER} && BUILD_ORDER_BUILDER+=" ${BUILDER}"
        fi
    done
    # remove excluded repos
    IFS=', ' read -a EXCLUDE_ARRAY <<< "$EXCLUDE"
    for excluded_repo in "${EXCLUDE_ARRAY[@]}";do
        BUILD_ORDER=${BUILD_ORDER/$excluded_repo/}
    done
    read BUILD_ORDER <<< $BUILD_ORDER
}

# Check image dependencies and populate BUILD_ORDER/REQUIRED_BUILDER/REQUIRED_ENGINES. Recursive.
#
# Arguments:
#
# 1: REPO
# 2: PREV_REPO
check_image_dependencies()
{
    local REPO_EXPANDED="${1}"
    # add image path if missing
    [[ $REPO_EXPANDED != *"/${IMAGE_PATH}"* ]] && REPO_EXPANDED=${REPO_EXPANDED/\//\/${IMAGE_PATH}}
    if [ "${1}" != "scratch" ]; then
        source_namespace_conf $REPO_EXPANDED

        # collect required engines
        ! string_has_word "${REQUIRED_ENGINES}" ${CONTAINER_ENGINE} && REQUIRED_ENGINES+=" ${CONTAINER_ENGINE}"

        # collect required build containers
        IMAGE_BUILDER=$(get_image_builder "${1}" "${IMAGE_PATH}")
        [[ $? == 1 ]] && die "error executing get_image_builder(): ${IMAGE_BUILDER}"
        if [[ "${IMAGE_BUILDER}" != "" ]] && ! string_has_word "${REQUIRED_BUILDER}" ${IMAGE_BUILDER}; then
             REQUIRED_BUILDER+=" ${IMAGE_BUILDER}"
        else
            # add default build container of current namespace
            ! string_has_word "${REQUIRED_BUILDER}" ${DEF_BUILD_CONTAINER} && REQUIRED_BUILDER+=" ${DEF_BUILD_CONTAINER}"
        fi

        PARENT_IMAGE=$(get_parent_image "${1}" "${IMAGE_PATH}")
        [[ $? == 1 ]] && die "error executing get_parent_image(): ${PARENT_IMAGE}"
        if [[ "${PARENT_IMAGE}" != "" ]]; then
            # skip further checking if already processed
            if ! string_has_word "${BUILD_ORDER}" ${1}; then
                # add parent image dependencies
                check_image_dependencies $PARENT_IMAGE $1
                [[ "${2}" != "" ]] && BUILD_ORDER+=" ${1}"
            fi
        fi
    fi
}

# Check builder dependencies and populate BUILD_ORDER_BUILDER. Recursive.
#
# Arguments:
#
# 1: BUILDER_REPO
# 2: PREV_BUILDER_REPO
check_builder_dependencies() {
    local REPO_EXPANDED="${1}"
    # add builder path if missing
    [[ $REPO_EXPANDED != *"/${BUILDER_PATH}"* ]] && REPO_EXPANDED=${REPO_EXPANDED/\//\/${BUILDER_PATH}}
    if [ "${1}" != "${BUILDER_CORE}" ]; then
        source_namespace_conf "$REPO_EXPANDED"
        # skip further checking if already processed
        if ! string_has_word "${BUILD_ORDER_BUILDER}" ${1}; then
            PARENT_BUILDER=$(get_build_container "${1}" "${BUILDER_PATH}")
            [[ $? == 1 ]] && die "error executing get_parent_builder(): ${PARENT_BUILDER}"
            # if defined, add parent builder dependencies
            [[ "${PARENT_BUILDER}" != "" ]] && [[ "${PARENT_BUILDER}" != "${BUILDER_CORE}" ]] && [[ "${PARENT_BUILDER}" != "${DEF_BUILD_CONTAINER}" ]]  && \
                [[ "${PARENT_BUILDER}" != ${1} ]] && check_builder_dependencies ${PARENT_BUILDER} ${1}
            [[ "${2}" != "" ]] && BUILD_ORDER_BUILDER+=" ${1}"
        fi
    fi
}

build()
{
    if ($BUILD_WITHOUT_DEPS && [ "${1}" == "*" ]); then
        die "error: -n does not support wildcards, specify one or more repo names."
    fi

    if $BUILD_WITHOUT_DEPS; then
        cd $REPO_PATH
        for REPO in $1; do
            source_namespace_conf ${REPO}
            validate_repo ${REPO} ${IMAGE_PATH}
            build_image_no_deps ${REPO}
        done
        exit 0
    fi

    msg "generate build order"
    cd $REPO_PATH
    REPOS=$(expand_requested_repos "${REPOS}") || die "failed to expand requested images, typo in namespace or image name?"
    generate_build_order "${REPOS}"
    msg "required engines: ${REQUIRED_ENGINES}"
    msg "required builders: ${BUILD_ORDER_BUILDER}"
    msg "build sequence:    ${BUILD_ORDER}"
    [[ -n ${EXCLUDE} ]] && msg "excluded: ${EXCLUDE}"

    e=($REQUIRED_ENGINES)
    for ENGINE in "${e[@]}"; do
       source "${PROJECT_ROOT}/inc/engine/${ENGINE}.sh"
       validate_engine
       build_core
    done

    b=($BUILD_ORDER_BUILDER)
    for REPO in "${b[@]}"; do
        source_namespace_conf ${REPO}
        validate_repo ${REPO} ${BUILDER_PATH}
        build_builder "${REPO}"
    done

    b=($BUILD_ORDER)
    for REPO in "${b[@]}"; do
        source_namespace_conf ${REPO}
        validate_repo ${REPO} ${IMAGE_PATH}
        build_image "${REPO}"
    done
}

# Update DATE to latest stage3 build date
update_stage3_date() {
    S3DATE_REMOTE="$(curl -s ${MIRROR}/releases/amd64/autobuilds/latest-stage3.txt | grep ${STAGE3_BASE} | awk -F '/' '{print $1}')"
    regex='^DATE=("?([0-9]+)"?)|("\$\{DATE:-([0-9]+)\}")'
    if [[ "$(grep ^DATE= build.conf)" =~ $regex ]]; then
        S3DATE_LOCAL="${BASH_REMATCH[4]}"
    else
        die "Could not parse DATE in build.conf"
    fi
    if [ "$S3DATE_LOCAL" -lt "$S3DATE_REMOTE" ]; then
        msg "Updating DATE from $S3DATE_LOCAL to $S3DATE_REMOTE in ./build.conf"
        sed -i s/^DATE=\"\${DATE:-[0-9]*}\"/DATE=\"\${DATE:-${S3DATE_REMOTE}}\"/g build.conf
    else
        msg "Already up to date. ($S3DATE_LOCAL)"
    fi
}

# List images that are not build yet
missing()
{
    cd $REPO_PATH
    for NS in ${1}; do
        for REPO in ${NS}/images/*; do
            source_namespace_conf ${REPO}
            ! image_exists "${REPO/${IMAGE_PATH}/}" && msg "${REPO/${IMAGE_PATH}/}"
        done
    done
}

has_required_binaries

while getopts ":fFcCnsh" opt; do
  case $opt in
    f)
      FORCE_REBUILD=true
      ;;
    F)
      FORCE_ROOTFS_REBUILD=true
      ;;
    c)
      FORCE_BUILDER_REBUILD=true
      ;;
    C)
      FORCE_FULL_REBUILD=true
      ;;
    n)
      BUILD_WITHOUT_DEPS=true
      ;;
    s)
      SKIP_GPG=true
      ;;
    h)
      ACTION="help"
  esac
done
shift $(( $OPTIND -1 ))

if [ -z "$ACTION" ]; then
    ACTION="${1:-build}"
fi
shift
REPOS="${@:-"*"}"

case "${ACTION}" in
    build) build "$REPOS";;
    update) update_stage3_date;;
    missing) missing "$REPOS";;
    help) msg "usage: ${0} [-n, -f, -F, -c, -C, -h] {build|update|missing} [repo ...]
    -f force repo rebuild
    -F also rebuild repo rootfs tar ball
    -c rebuild building containers
    -C also rebuild stage3 import containers
    -n do not build repo dependencies for given repo(s)
    -s skip gpg validation on downloaded files
    -h help" ;;
*) die "invalid action '${ACTION}'" ;;
esac
