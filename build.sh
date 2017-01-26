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

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

PROJECT_ROOT=$(dirname $(realpath $0))
DL_PATH="${DL_PATH:-${PROJECT_ROOT}/tmp/downloads}"

# read global build.conf
[[ ! -f "${PROJECT_ROOT}/build.conf" ]] && echo "error: could not find ${PROJECT_ROOT}/build.conf" && exit 1
source ./build.conf

DATE_ROOT="${DATE?Error \$DATE is not defined.}"
NAMESPACE_ROOT="${NAMESPACE:-gentoobb}"

BUILD_OPTS="${BUILD_OPTS:-}"

SKIP_GPG="${SKIP_GPG:-false}"
EXCLUDE="${EXCLUDE:-}"

REQUIRED_BINARIES="awk bzip2 grep id wget"
[ "${SKIP_GPG}" != "false" ] && REQUIRED_BINARIES+=" gpg"
[[ $(command -v sha512sum) ]] && REQUIRED_BINARIES+=" sha512sum" || REQUIRED_BINARIES+=" shasum"

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
    REQUIRED_CORES=""
    for BUILDER_ID in $REQUIRED_BUILDER; do
        check_builder_dependencies ${BUILDER_ID}
        if [ -z "$BUILD_ORDER_BUILDER" ]; then
            BUILD_ORDER_BUILDER="${BUILDER_ID}"
        else
            ! string_has_word "${BUILD_ORDER_BUILDER}" ${BUILDER_ID} && BUILD_ORDER_BUILDER+=" ${BUILDER_ID}"
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
        source_image_conf $REPO_EXPANDED

        # collect required engines
        ! string_has_word "${REQUIRED_ENGINES}" ${CONTAINER_ENGINE} && REQUIRED_ENGINES+=" ${CONTAINER_ENGINE}"

        # collect required build containers
        IMAGE_BUILDER=$(get_image_builder "${1}" "${IMAGE_PATH}")
        [[ $? == 1 ]] && die "error executing get_image_builder(): ${IMAGE_BUILDER}"
        if [[ "${IMAGE_BUILDER}" != "" ]];then
             ! string_has_word "${REQUIRED_BUILDER}" ${IMAGE_BUILDER} && REQUIRED_BUILDER+=" ${IMAGE_BUILDER}"
        else
            # add default build container of current namespace
            ! string_has_word "${REQUIRED_BUILDER}" ${DEFAULT_BUILDER} && REQUIRED_BUILDER+=" ${DEFAULT_BUILDER}"
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
    source_image_conf "${REPO_EXPANDED}"
    [[ ! -z "${STAGE3_BASE}" ]] && ! string_has_word "${REQUIRED_CORES}" "${STAGE3_BASE}" && REQUIRED_CORES+=" ${STAGE3_BASE}"
    # skip further checking if already processed
    if ! string_has_word "${BUILD_ORDER_BUILDER}" ${1}; then
        if [[ -z "${STAGE3_BASE}" ]]; then
            PARENT_BUILDER=$(get_build_container "${1}" "${BUILDER_PATH}")
            [[ $? == 1 ]] && die "error executing get_parent_builder(): ${PARENT_BUILDER}"
            check_builder_dependencies ${PARENT_BUILDER} ${1}
        fi
        [[ "${2}" != "" ]] && BUILD_ORDER_BUILDER+=" ${1}"
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
            local REPO_EXPANDED=${REPO/\//\/${IMAGE_PATH}}
            source_image_conf ${REPO_EXPANDED}
            validate_repo ${REPO} ${IMAGE_PATH}
            build_image_no_deps ${REPO}
        done
        exit 0
    fi

    msg "generate build order"
    cd $REPO_PATH
    REPOS=$(expand_requested_repos "${1}") || die "failed to expand requested images, typo in namespace or image name?"
    generate_build_order "${REPOS}"
    msgf "required engines:" "${REQUIRED_ENGINES:1}"
    msgf "required stage3:" "${REQUIRED_CORES:1}"
    msgf "required builders:" "${BUILD_ORDER_BUILDER}"
    msgf "build sequence:" "${BUILD_ORDER}"
    [[ -n ${EXCLUDE} ]] && msgf "excluded:" "${EXCLUDE}"

    e=($REQUIRED_ENGINES)
    for ENGINE in "${e[@]}"; do
       source "${PROJECT_ROOT}/inc/engine/${ENGINE}.sh"
       validate_engine
    done

    b=($BUILD_ORDER_BUILDER)
    for REPO in "${b[@]}"; do
        local REPO_EXPANDED=${REPO/\//\/${BUILDER_PATH}}
        source_image_conf ${REPO_EXPANDED}
        validate_repo ${REPO} ${BUILDER_PATH}
        build_builder "${REPO}"
    done

    b=($BUILD_ORDER)
    for REPO in "${b[@]}"; do
        local REPO_EXPANDED=${REPO/\//\/${IMAGE_PATH}}
        source_image_conf ${REPO_EXPANDED}
        validate_repo ${REPO} ${IMAGE_PATH}
        build_image "${REPO}"
    done
}

# Update STAGE3_DATE in build.conf for all builders in all namespaces
update_stage3_date() {
    cd "${REPO_PATH}"
    for CURRENT_NS in */; do
        msg $CURRENT_NS
        local BPATH=${PROJECT_ROOT}/$REPO_PATH/${CURRENT_NS}${BUILDER_PATH}
        if [ -d "${BPATH}" ]; then
            cd $BPATH
            for CURRENT_B in  */; do
                local UPDATE_STATUS=""
                cd $PROJECT_ROOT/$REPO_PATH
                source_image_conf $CURRENT_NS/$BUILDER_PATH/$CURRENT_B
                if [[ ! -z ${STAGE3_BASE} ]]; then
                    local RFILES="$(wget -qO- ${ARCH_URL})"
                    local REGEX="${STAGE3_BASE//+/\\+}-([0-9]{8})\.tar\.bz2"
                    if [[ $RFILES =~ $REGEX ]]; then
                        local S3DATE_REMOTE="${BASH_REMATCH[1]}"
                        if [ "$STAGE3_DATE" -lt "$S3DATE_REMOTE" ]; then
                            sed -r -i s/^STAGE3_DATE=\"?\{0,1\}[0-9]*\"?/STAGE3_DATE=\"${S3DATE_REMOTE}\"/g \
                                "${BPATH}${CURRENT_B}build.conf"
                            UPDATE_STATUS="updated ${STAGE3_DATE} -> ${S3DATE_REMOTE}"
                        else
                            UPDATE_STATUS="up-to-date ${STAGE3_DATE}"
                        fi
                    else
                        UPDATE_STATUS="could not parse remote STAGE3 DATE from ${ARCH_URL}"
                    fi
                fi
                printf "      %-20s %s\n" "${CURRENT_B}" "${UPDATE_STATUS}"
            done
        else
            echo "      no build containers"
        fi
    done
}

add_from_template()
{
    echo "NotImplementedException ;/"
}

clean_project_artifacts()
{
    msg "removing all rootfs.tar files"
    find "${PROJECT_ROOT}/${REPO_PATH}" -name rootfs.tar -exec rm {} \;
    msg "removing all PACKAGES.md files"
    find "${PROJECT_ROOT}/${REPO_PATH}" -name PACKAGES.md -exec rm {} \;
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
REMAINING_ARGS="${@:-"*"}"

case "${ACTION}" in
    add) add_from_template "$REMAINING_ARGS";;
    clean) clean_project_artifacts;;
    build) build "$REMAINING_ARGS";;
    update) update_stage3_date;;
    missing) missing "$REMAINING_ARGS";;
    help) msg "usage: ${0} [-n, -f, -F, -c, -C, -h] {add|build|update|missing} [repo ...]
    -f force repo rebuild
    -F also rebuild repo rootfs tar ball
    -c rebuild building/core containers
    -C also rebuild stage3 import containers, a.k.a everything
    -n do not build repo dependencies for given repo(s)
    -s skip gpg validation on downloaded files
    -h help" ;;
*) die "invalid action '${ACTION}'" ;;
esac
