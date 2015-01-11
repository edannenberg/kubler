#!/bin/bash
#
# Copyright (C) 2014 Erik Dannenberg <erik.dannenberg@bbe-consulting.de>
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

# read global build.conf
[[ ! -f ./build.conf ]] && die error: could not find build.conf!
source ./build.conf

DATE_ROOT="${DATE}"
NAMESPACE_ROOT="${NAMESPACE:-gentoobb}"

MIRROR="${MIRROR:-http://distfiles.gentoo.org/}"
ARCH_URL="${ARCH_URL:-${MIRROR}releases/amd64/autobuilds/${DATE}/hardened/}"
STAGE3_BASE="${STAGE3_BASE:-stage3-amd64-hardened+nomultilib}"
STAGE3="${STAGE3:-${STAGE3_BASE}-${DATE}.tar.bz2}"

STAGE3_CONTENTS="${STAGE3_CONTENTS:-${STAGE3}.CONTENTS}"
STAGE3_DIGESTS="${STAGE3_DIGESTS:-${STAGE3}.DIGESTS.asc}"

BUILD_CONTAINER="${BUILD_CONTAINER:-bob-core}"
# variables starting with BOB_ are exported as ENV to build container
BOB_TIMEZONE="${BOB_TIMEZONE:-UTC}"

DOCKER_IO=$(command -v docker.io)
DOCKER="${DOCKER:-${DOCKER_IO:-docker}}"
BUILD_OPTS="${BUILD_OPTS:-}"
REPO_PATH="${REPO_PATH:-dock}"
IMAGE_PATH="images/"
BUILDER_PATH="builder/"
BUILDER_CORE="${NAMESPACE_ROOT}/bob-core"

DL_PATH="${DL_PATH:-tmp/downloads}"
SKIP_GPG="${SKIP_GPG:-false}"
EXCLUDE="${EXCLUDE:-}"

REQUIRED_BINARIES="bzip2 docker sha512sum wget"
[ "${SKIP_GPG}" != "false" ] && REQUIRED_BINARIES+=" gpg"

die()
{
    echo "$1"
    exit 1
}

msg()
{
    echo "--> $@"
}

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

# Remove container from registry
#
# Arguments:
#
# 1: REPO
remove_image()
{
    REPO="${1}"
    "${DOCKER}" rmi -f "$REPO:${DATE}" || die "failed to remove image"
}

# Get docker image size for given ${NAMESPACE}/${IMAGE}:${TAG}
#
# Arguments:
# 1: IMAGE
# 2: TAG
get_image_size() {
    echo "$(${DOCKER} images ${1} | grep ${2} | awk '{print $(NF-1)" "$NF}')"
}

# Does "${NAMESPACE}/${REPO}:${DATE}" exist?
# Returns 0 (exists) or 1 (missing).
#
# Arguments:
#
# 1: REPO
# 2: TYPE (images/|builder/)
repo_exists()
{
    local REPO="${1}"
    [[ "${REPO}" == ${BUILDER_CORE##*/} ]] && REPO=${BUILDER_CORE}
    IMAGES=$("${DOCKER}" images "${REPO}")
    MATCHES=$(echo "${IMAGES}" | grep "${DATE}")
    if [ -z "${MATCHES}" ]; then
        return 1
    fi
    if $FORCE_FULL_REBUILD; then
        remove_image "$REPO"
        return 1
    elif $FORCE_BUILDER_REBUILD && [ "${2}" == "${BUILDER_PATH}" ]; then
        remove_image "$REPO"
        return 1
    elif ($FORCE_REBUILD || $FORCE_ROOTFS_REBUILD) && [ "${2}" != "${BUILDER_PATH}" ] && [ "$REPO" != "${NAMESPACE}/stage3-import" ] && [ "$REPO" != "${BUILDER_CORE}" ]; then
        remove_image "$REPO"
        return 1
    fi
    return 0
}

# If they don't already exist:
#
# * download the stage3 and
# * create "${NAMESPACE}/gentoo:${DATE}"
#
# Forcibly tag "${NAMESPACE}/gentoo:${DATE}" with "latest"
import_stage3()
{
    msg "import stage3"
    if ! repo_exists "${NAMESPACE}/stage3-import"; then
    # import stage3 image from Gentoo mirrors

    [ -d $DL_PATH ] || mkdir -p $DL_PATH

    for FILE in "${STAGE3}" "${STAGE3_CONTENTS}" "${STAGE3_DIGESTS}"; do
    if [ ! -f "$DL_PATH/${FILE}" ]; then
        wget -O "$DL_PATH/${FILE}" "${ARCH_URL}${FILE}" ||
        die "failed to download ${ARCH_URL}${FILE}"
    fi
    done

    if [ "$SKIP_GPG" = false ]; then
        gpg --verify "$DL_PATH/${STAGE3_DIGESTS}" || die "insecure digests"
    fi
    SHA512_HASHES=$(grep -A1 SHA512 "$DL_PATH/${STAGE3_DIGESTS}" | grep -v '^--')
    SHA512_CHECK=$(cd $DL_PATH/ && (echo "${SHA512_HASHES}" | sha512sum -c))
    SHA512_FAILED=$(echo "${SHA512_CHECK}" | grep FAILED)
    if [ -n "${SHA512_FAILED}" ]; then
        die "${SHA512_FAILED}"
    fi

    msg "import ${NAMESPACE}/stage3-import:${DATE}"
    bzcat < "$DL_PATH/${STAGE3}" | bzip2 | "${DOCKER}" import - "${NAMESPACE}/stage3-import:${DATE}" || die "failed to import"
    fi

    msg "tag ${NAMESPACE}/stage3-import:latest"
    "${DOCKER}" tag -f "${NAMESPACE}/stage3-import:${DATE}" "${NAMESPACE}/stage3-import:latest" || die "failed to tag"
}

# generate Dockerfile from template
#
# Arguments:
# 1: REPO
generate_dockerfile()
{
    if [ ! -d ${1} ]; then
        die "error: repo ${REPO_PATH}/${1} does not exist, typo?"
    fi
    if [ ! -f ${1}/Dockerfile.template ]; then
        die "error: repo ${REPO_PATH}/${1} does not have a Dockerfile.template"
    fi

    sed \
        -e 's/${NAMESPACE}/'"${NAMESPACE}"'/' \
        -e 's/${TAG}/'"${DATE}"'/' \
        -e 's/${MAINTAINER}/'"${AUTHOR}"'/' "$1/Dockerfile.template" > "$1/Dockerfile"
}

# Returns image given REPO is based on by parsing FROM
#
# Arguments:
# 1: REPO
# 2: TYPE (builder/|images/)
get_parent_repo() {
    dockerf=$(grep ^FROM ${1/\//\/$2}/Dockerfile)
    regex="^FROM (.*)"
    if [[ ${dockerf} =~ $regex ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        die "error parsing FROM tag in {$1/\//\/$2}/Dockerfile"
    fi
}

# Returns builder given REPO should use by parsing BUILD_FROM
#
# Arguments:
# 1: REPO
# 2: TYPE (builder/|images/)
get_build_from() {
    dockerf=$(grep ^#BUILD_FROM ${1/\//\/$2}/Dockerfile)
    regex="^#BUILD_FROM (.*)"
    if [[ ${dockerf} =~ $regex ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "false"
    fi
}

# Returns 0 if given REPO's Dockerfile has a #SKIP_ROOTFS pseudo tag
#
# Arguments:
# 1: REPO
# 2: TYPE (images/|builder/)
has_skip_rootfs_tag() {
    return $(grep -q ^#SKIP_ROOTFS ${1/\//\/$2}/Dockerfile)
}

# Read namespace build.conf for given REPO
#
# Arguments:
# 1: REPO
source_namespace_conf() {
    # reset to global defaults first..
    [[ -f ${PROJECT_ROOT}/build.conf ]] && source ${PROJECT_ROOT}/build.conf
    # ..then read namespace build.conf if passed args have a namespace
    [[ ${1} != *"/"* ]] && return 0
    local CURRENT_NS=${1%%/*}
    [[ -f $CURRENT_NS/build.conf ]] && source $CURRENT_NS/build.conf
    # prevent setting namespace and date via namespace build.conf
    NAMESPACE=${CURRENT_NS}
    DATE=${DATE_ROOT}
}

# If it doesn't already exist:
#
# * create "${NAMESPACE}/${REPO}:${DATE}" from
# "${REPO}/Dockerfile.template"
#
# Forcibly tag "${NAMESPACE}/${REPO}:${DATE}" with "latest"
#
# Arguments:
#
# 1: REPO
# 2: SUB_PATH (images/|builder/)
build_repo()
{
    REPO="${1}"
    REPO_TYPE="${2}"
    REPO_EXPANDED=${REPO/\//\/${REPO_TYPE}}
    msg "build repo ${REPO}"

    repo_exists "${REPO}" "${REPO_TYPE}" && return 0
    source_namespace_conf ${REPO}
    if ([ ! -f $REPO_EXPANDED/rootfs.tar ] || $FORCE_ROOTFS_REBUILD) && \
        [ "${REPO}" != ${BUILDER_CORE##*/} ] && \
        ! has_skip_rootfs_tag ${REPO} ${REPO_TYPE}; then

        msg "building rootfs"

        # determine build container
        local BUILD_FROM=$(get_build_from ${REPO} ${2})
        local PARENT_REPO=$(get_parent_repo ${REPO} ${2})
        local PARENT_IMAGE=${PARENT_REPO##*/}
        local CURRENT_IMAGE=${REPO##*/}

        if [[ "$BUILD_FROM" != "false" ]]; then
            BUILD_CONTAINER="${BUILD_FROM}"
            BUILDER_COMMIT_ID="${BUILD_CONTAINER##*/}-${CURRENT_IMAGE}"
        elif [[ "${2}" == "${IMAGE_PATH}" ]]; then
            BUILDER_COMMIT_ID="${BUILD_CONTAINER##*/}-${CURRENT_IMAGE}"
            [[ "${PARENT_IMAGE}" != "scratch" ]] && repo_exists "${BUILD_CONTAINER}-${PARENT_IMAGE}" "${BUILDER_PATH}" && \
                BUILD_CONTAINER="${BUILD_CONTAINER}-${PARENT_IMAGE}"
        fi

        if [[ "${PARENT_REPO}" == "${BUILD_CONTAINER}" ]] && [[ "${BUILD_FROM}" == "false" ]]; then
            BUILD_CONTAINER=${BUILDER_CORE}
            BUILDER_COMMIT_ID=${REPO##*/}
        fi

        if [ "$PARENT_REPO" == "$REPO" ]; then
            BUILDER_COMMIT_ID="${CURRENT_IMAGE}"
        fi

        # pass variables starting with BOB_ to build container as ENV
        for bob_var in ${!BOB_*}; do
            BOB_ENV+=('-e' "${bob_var}=${!bob_var}")
        done

        msg "run ${BUILD_CONTAINER}:${DATE}"
        "${DOCKER}" run \
            -v $(dirname $(realpath -s $0))/$REPO_EXPANDED:/config \
            -v $(realpath -s ../tmp/distfiles):/distfiles \
            -v $(realpath -s ../tmp/packages):/packages \
            "${BOB_ENV[@]}" \
            -it --hostname "${BUILDER_ID}" "${BUILD_CONTAINER}:${DATE}" build-root $REPO_EXPANDED || die "failed to build rootfs for $REPO_EXPANDED"

        local RUN_ID="$(${DOCKER} ps -a | grep -m1 ${BUILD_CONTAINER}:${DATE} | awk '{print $1}')"

        msg "commit ${RUN_ID} ${NAMESPACE}/${BUILDER_COMMIT_ID}:${DATE}"
        "${DOCKER}" commit "${RUN_ID}" "${NAMESPACE}/${BUILDER_COMMIT_ID}:${DATE}"

        "${DOCKER}" rm "${RUN_ID}" || die "failed to remove container ${RUN_ID}"

        msg "tag ${NAMESPACE}/${BUILDER_COMMIT_ID}:latest"
        "${DOCKER}" tag -f "${NAMESPACE}/${BUILDER_COMMIT_ID}:${DATE}" "${NAMESPACE}/${BUILDER_COMMIT_ID}:latest" || die "failed to tag ${BUILDER_COMMIT_ID}"
    fi

    REPO_ID=$REPO
    [[ "$REPO" == ${BUILDER_CORE##*/} ]] && REPO_ID=${BUILDER_CORE}

    msg "build ${REPO}:${DATE}"
    "${DOCKER}" build ${BUILD_OPTS} -t "${REPO_ID}:${DATE}" "${REPO_EXPANDED}" || die "failed to build ${REPO_EXPANDED}"

    msg "tag ${REPO}:latest"
    "${DOCKER}" tag -f "${REPO_ID}:${DATE}" "${REPO_ID}:latest" || die "failed to tag ${REPO_EXPANDED}"

    add_documentation_header "${REPO}" "${REPO_TYPE}" || die "failed to generate PACKAGES.md for ${REPO_EXPANDED}"
}

# Generate PACKAGES.md header
#
# Arguments:
# 1: REPO
# 2: TYPE (images/|builder/)
add_documentation_header() {
    REPO="${1}"
    REPO_EXPANDED=${REPO/\//\/${2}}
    DOC_FILE="${REPO_EXPANDED}/PACKAGES.md"
    HEADER="### ${REPO}:${DATE}"
    IMAGE_SIZE="$(get_image_size ${REPO} ${DATE})"
    # remove existing header
    if [[ -f ${DOC_FILE} ]]; then
        $(grep -q "^${HEADER}" ${DOC_FILE}) && sed -i '1,4d' ${DOC_FILE}
    else
        echo -e "" > ${DOC_FILE}
    fi
    # add header
    sed -i "1i${HEADER}\nBuilt: $(date)\n\nImage Size: $IMAGE_SIZE" $DOC_FILE
}


# Returns 0 if given string contains given word. Does not match substrings.
#
# 1: string
# 2: word
string_has_word() {
    regex="(^| )${2}($| )"
    if [[ "${1}" =~ $regex ]];then
        return 0
    else
        return 1
    fi
}

# Populate $BUILD_ORDER by checking image dependencies
#
# Arguments:
#
# 1: REPOS
generate_build_order()
{
    # generate image build order
    REQUIRED_BUILDER=""
    for REPO in $1; do
        check_repo_dependencies ${REPO}
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

# Check image dependencies and populate BUILD_ORDER/REQUIRED_BUILDER. Recursive.
#
# Arguments:
#
# 1: REPO
# 2: PREV_REPO
check_repo_dependencies()
{
    local REPO_EXPANDED="${1}"
    # add image path if missing
    [[ $REPO_EXPANDED != *"/${IMAGE_PATH}"* ]] && REPO_EXPANDED=${REPO_EXPANDED/\//\/${IMAGE_PATH}}
    if [ "${1}" != "scratch" ]; then
        source_namespace_conf $REPO_EXPANDED
        generate_dockerfile $REPO_EXPANDED
        # collect #BUILD_FROM tags
        local BUILD_FROM=$(get_build_from $1 $IMAGE_PATH)
        if [[ "$BUILD_FROM" != "false" ]] && ! string_has_word "${REQUIRED_BUILDER}" ${BUILD_FROM}; then
             REQUIRED_BUILDER+=" ${BUILD_FROM}"
        else
            # add default build container of current namespace
            ! string_has_word "${REQUIRED_BUILDER}" ${BUILD_CONTAINER} && REQUIRED_BUILDER+=" ${BUILD_CONTAINER}"
        fi
        dockerf=$(grep ^FROM ${REPO_EXPANDED}/Dockerfile)
        regex="^FROM (.*)"
        if [[ ${dockerf} =~ $regex ]]; then
            match=${BASH_REMATCH[1]}
            # skip further checking if already processed
            if ! string_has_word "${BUILD_ORDER}" ${1}; then
                # add parent image dependencies
                check_repo_dependencies $match $1
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
        generate_dockerfile "$REPO_EXPANDED"
        # skip further checking if already processed
        if ! string_has_word "${BUILD_ORDER_BUILDER}" ${1}; then
            local BUILD_FROM=$(get_build_from $1 $BUILDER_PATH)
            # if defined, add parent builder dependencies
            [[ "$BUILD_FROM" != "false" ]] && [[ "$BUILD_FROM" != "$BUILDER_CORE" ]] && check_builder_dependencies $BUILD_FROM $1
            [[ "${2}" != "" ]] && BUILD_ORDER_BUILDER+=" ${1}"
        fi
    fi
}

# Expand requested namespace/image mix to build command, i.e. build gentoobb/busybox mynamespace othernamespace/myimage
#
# Arguments:
# 1: REPO(S)/NAMESPACE(S)
expand_requested_repos() {
    REPO_ARGS="${1}"
    EXPANDED=""
    for REPO in ${REPO_ARGS}; do
        if [[ $REPO == *"/"* ]]; then
            EXPANDED+=" ${REPO}"
        else
           for IMAGE in ${REPO}/${IMAGE_PATH}*; do
               EXPANDED+=" ${IMAGE/${IMAGE_PATH}/}"
            done
        fi
    done
    echo $EXPANDED
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
            generate_dockerfile ${REPO/\//\/${IMAGE_PATH}}
            build_repo ${REPO} ${IMAGE_PATH}
        done
        exit 0
    fi

    import_stage3

    generate_dockerfile ${BUILDER_CORE##*/}
    build_repo ${BUILDER_CORE##*/}

    msg "generate build order"
    cd $REPO_PATH
    REPOS=$(expand_requested_repos "$REPOS")
    generate_build_order "${REPOS}"
    msg "required builders: ${BUILD_ORDER_BUILDER}"
    msg "build sequence: ${BUILD_ORDER}"
    msg "excluded: ${EXCLUDE}"

    b=($BUILD_ORDER_BUILDER)
    for REPO in "${b[@]}"; do
        build_repo "${REPO}" "${BUILDER_PATH}"
    done

    b=($BUILD_ORDER)
    for REPO in "${b[@]}"; do
        build_repo "${REPO}" "${IMAGE_PATH}"
    done
}

# Update DATE to latest stage3 build date
update_stage3_date() {
    S3DATE_REMOTE="$(curl -s ${MIRROR}/releases/amd64/autobuilds/latest-stage3.txt | grep ${STAGE3_BASE} | awk -F '/' '{print $1}')"
    regex='DATE="?([0-9]+)"?'
    if [[ "$(grep ^DATE= build.conf)" =~ $regex ]]; then
        S3DATE_LOCAL="${BASH_REMATCH[1]}"
    else
        die "Could not parse DATE in build.conf"
    fi
    if [ "$S3DATE_LOCAL" -lt "$S3DATE_REMOTE" ]; then
        msg "Updating DATE from $S3DATE_LOCAL to $S3DATE_REMOTE in ./build.conf"
        sed -i s/^DATE=\"[0-9]*\"/DATE=\"${S3DATE_REMOTE}\"/g build.conf
    else
        msg "Already up to date. ($S3DATE_LOCAL)"
    fi
}

missing()
{
    cd $REPO_PATH
    for REPO in $1; do
        if ! repo_exists "${REPO}"; then
            msg "${REPO}"
        fi
    done
}

FORCE_REBUILD=false
FORCE_ROOTFS_REBUILD=false
FORCE_BUILDER_REBUILD=false
FORCE_FULL_REBUILD=false
BUILD_WITHOUT_DEPS=false

for BINARY in ${REQUIRED_BINARIES}; do
    if ! [ -x "$(command -v ${BINARY})" ]; then
        die "${BINARY} is required for this script to run. Please install and try again"
    fi
done

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
