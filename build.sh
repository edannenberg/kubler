#!/bin/sh
#
# Copyright (C) 2014 W. Erik Dannenberg <erik.dannenberg@bbe-consulting.de>
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

AUTHOR="${AUTHOR:-Erik Dannenberg <erik.dannenberg@bbe-consulting.de>}"
NAMESPACE="${NAMESPACE:-gentoobb}"
DATE="${DATE:-20141016}"
MIRROR="${MIRROR:-http://distfiles.gentoo.org/}"
ARCH_URL="${ARCH_URL:-${MIRROR}releases/amd64/autobuilds/${DATE}/}"
STAGE3="${STAGE3:-stage3-amd64-nomultilib-${DATE}.tar.bz2}"
STAGE3_CONTENTS="${STAGE3_CONTENTS:-${STAGE3}.CONTENTS}"
STAGE3_DIGESTS="${STAGE3_DIGESTS:-${STAGE3}.DIGESTS.asc}"
PORTAGE_URL="${PORTAGE_URL:-${MIRROR}snapshots/}"
PORTAGE="${PORTAGE:-portage-${DATE}.tar.xz}"
#PORTAGE="${PORTAGE:-portage-latest.tar.xz}"
PORTAGE_SIG="${PORTAGE_SIG:-${PORTAGE}.gpgsig}"

DOCKER_IO=$(command -v docker.io)
DOCKER="${DOCKER:-${DOCKER_IO:-docker}}"
BUILD_OPTS="${BUILD_OPTS:-}"
BUILDER_PATH="${REPO_PATH:-bb-builder}"
REPO_PATH="${REPO_PATH:-bb-dock}"
DL_PATH=tmp/downloads
SKIP_GPG=false
EXCLUDE="${EXCLUDE:-}"

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

# Remove container from registry
#
# Arguments:
#
# 1: REPO
remove_image()
{
    REPO="${1}"
    "${DOCKER}" rmi -f "${NAMESPACE}/$REPO:${DATE}" || die "failed to remove image"
}

# Does "${NAMESPACE}/${REPO}:${DATE}" exist?
# Returns 0 (exists) or 1 (missing).
#
# Arguments:
#
# 1: REPO
repo_exists()
{
    REPO="${1}"
    IMAGES=$("${DOCKER}" images "${NAMESPACE}/${REPO}")
    MATCHES=$(echo "${IMAGES}" | grep "${DATE}")
    if [ -z "${MATCHES}" ]; then
        return 1
    fi
    if $FORCE_FULL_REBUILD; then
        remove_image "$REPO"
        return 1
    elif $FORCE_BUILDER_REBUILD && [ "$REPO" = "bob" ]; then
        remove_image "$REPO"
        return 1
    elif ($FORCE_REBUILD || $FORCE_ROOTFS_REBUILD) && [ "$REPO" != "portage-data" ] && [ "$REPO" != "bob" ] && [ "$REPO" != "stage3-import" ] && [ "$REPO" != "portage-import" ]; then
        case "$REPO" in
            "stage3-import"|"portage-import"|"portage-data"|"bob")
                return 0
                ;;
            *)
                remove_image "$REPO"
                return 1
                ;;
        esac
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
    if ! repo_exists stage3-import; then
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

# If they don't already exist:
#
# * download a portage snapshot and
# * create "${NAMESPACE}/portage-import:${DATE}"
#
# Forcibly tag "${NAMESPACE}/portage-import:${DATE}" with "latest"
import_portage()
{
    msg " portage"
    if ! repo_exists portage-import; then
    # import portage image from Gentoo mirrors

    [ -d $DL_PATH ] || mkdir $DL_PATH

    for FILE in "${PORTAGE}" "${PORTAGE_SIG}"; do
    if [ ! -f "$DL_PATH/${FILE}" ]; then
        wget -O "$DL_PATH/${FILE}" "${PORTAGE_URL}${FILE}" ||
        die "failed to download ${PORTAGE_URL}${FILE}"
    fi
    done
    
    if [ "$SKIP_GPG" = false ]; then
        gpg --verify "$DL_PATH/${PORTAGE_SIG}" "$DL_PATH/${PORTAGE}" || die "insecure digests"
    fi
    
    msg "import ${NAMESPACE}/portage-import:${DATE}"
    "${DOCKER}" import - "${NAMESPACE}/portage-import:${DATE}" < "$DL_PATH/${PORTAGE}" || die "failed to import"
    fi
    
    msg "tag ${NAMESPACE}/portage-data:latest"
    "${DOCKER}" tag -f "${NAMESPACE}/portage-import:${DATE}" "${NAMESPACE}/portage-import:latest" || die "failed to tag"
}

# extract Busybox for the portage image
#
# Arguments:
#
# 1: SUBDIR target subdirectory for the busybox binary
extract_busybox()
{
    SUBDIR="${1}"
    msg "extract Busybox binary to ${SUBDIR}"
    THIS_DIR=$(dirname $($REALPATH $0))
    CONTAINER="${NAMESPACE}-gentoo-${DATE}-extract-busybox"
    "${DOCKER}" run --name "${CONTAINER}" -v "${THIS_DIR}/${SUBDIR}/":/tmp "${NAMESPACE}/stage3-import:${DATE}" cp /bin/busybox /tmp/
    "${DOCKER}" rm "${CONTAINER}"
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
    env -i \
    NAMESPACE="${NAMESPACE}" \
    TAG="${DATE}" \
    MAINTAINER="${AUTHOR}" \
    envsubst '
    ${NAMESPACE}
    ${TAG}
    ${MAINTAINER}
    ' \
    < "$1/Dockerfile.template" > "$1/Dockerfile"
}

# Generate package.provided file from image dependency for given REPO.
#
# Arguments:
#
# 1: REPO
generate_provided_file()
{
    mkdir -p ${1}/tmp
    dockerf=$(grep ^FROM $1/Dockerfile)
    regex="^FROM (${NAMESPACE}/)?(.*)"
    if [[ ${dockerf} =~ $regex ]]; then
        match="${BASH_REMATCH[2]}"
        if [ "$match" != "scratch" ]; then
            PARENT_TMP_PATH=${match}/tmp/
            TMP_PATH=${1}/tmp/
            if [ -f ${PARENT_TMP_PATH}/package.provided ] && [ -f ${PARENT_TMP_PATH}/package.provided ]; then
                cat ${PARENT_TMP_PATH}/package.provided ${PARENT_TMP_PATH}/package.installed > ${TMP_PATH}/package.provided
            elif [ -f ${PARENT_TMP_PATH}/package.installed ]; then
                cat ${PARENT_TMP_PATH}/package.installed > ${TMP_PATH}/package.provided
            fi
            if [ -f ${TMP_PATH}/package.provided ]; then
                # remove virtual package atoms
                sed -i /^virtual/d ${TMP_PATH}/package.provided
            #    sort -u ${1}/package.provided
            fi
            # copy passwd/group files
            if [ -f ${PARENT_TMP_PATH}/passwd ]; then
                cp ${PARENT_TMP_PATH}/{passwd,group} $TMP_PATH/
            fi
        fi
    fi
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
build_repo()
{
    REPO="${1}"
    msg "build repo ${REPO}"

    if ! repo_exists "${REPO}"; then
    if [ "${REPO}" = portage-data ]; then
        extract_busybox "${REPO}"
    fi

    if ([ ! -f $REPO/rootfs.tar ] || $FORCE_ROOTFS_REBUILD) && [ "${REPO}" != "bob" ] && [ "${REPO}" != "portage-data" ]; then
        msg "building rootfs"
        generate_provided_file ${REPO}
        "${DOCKER}" run --rm --volumes-from portage-data \
            -v $(dirname $(realpath -s $0))/$REPO:/config \
            -v $(realpath -s ../tmp/distfiles):/distfiles \
            -v $(realpath -s ../tmp/packages):/packages \
            -i -t "${NAMESPACE}/bob:${DATE}" build-root $REPO || die "failed to build rootfs for $REPO"
    fi

    msg "build ${NAMESPACE}/${REPO}:${DATE}"
    "${DOCKER}" build ${BUILD_OPTS} -t "${NAMESPACE}/${REPO}:${DATE}" "${REPO}" || die "failed to build ${REPO}"
    fi
    msg "tag ${NAMESPACE}/${REPO}:latest"
    "${DOCKER}" tag -f "${NAMESPACE}/${REPO}:${DATE}" "${NAMESPACE}/${REPO}:latest" || die "failed to tag ${REPO}"
}

# Run a docker container
#
# Arguments:
#
# 1: REPO
# 2: CONTAINER_NAME
run_container()
{
    REPO="${1}"
    CONTAINER_NAME="${2}"
    msg "running repo ${REPO} as ${CONTAINER_NAME}"

    "${DOCKER}" run --name ${CONTAINER_NAME} "${NAMESPACE}/${REPO}:${DATE}"
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
    for REPO in $1; do
        check_repo_dependencies ${REPO}
        if [ -z "$BUILD_ORDER" ]; then
            BUILD_ORDER="${REPO}"
        else
            if ! string_has_word "${BUILD_ORDER}" ${REPO};then
                BUILD_ORDER="${BUILD_ORDER} ${REPO}"
            fi
        fi
    done
    # remove excluded repos
    IFS=', ' read -a EXCLUDE_ARRAY <<< "$EXCLUDE"
    for excluded_repo in "${EXCLUDE_ARRAY[@]}";do
        BUILD_ORDER=${BUILD_ORDER/$excluded_repo/}
    done
    read BUILD_ORDER <<< $BUILD_ORDER
}

# Check image dependencies. Recursive.
#
# Arguments:
#
# 1: REPO
# 2: PREV_REPO
check_repo_dependencies()
{
    if [ "${1}" != "scratch" ]; then
    generate_dockerfile $1
    dockerf=$(grep ^FROM $1/Dockerfile)
    regex="^FROM (${NAMESPACE}/)?(.*)"
    if [[ ${dockerf} =~ $regex ]]; then
            match="${BASH_REMATCH[2]}"
            # skip further checking if already processed
            if ! string_has_word "${BUILD_ORDER}" ${1};then
                check_repo_dependencies $match $1
                if [ "${2}" != "" ]; then
                    BUILD_ORDER="${BUILD_ORDER} ${1}"
                fi
            fi
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
            generate_dockerfile ${REPO}
            build_repo ${REPO}
        done
        exit 0
    fi

    import_stage3
    import_portage

    cd $BUILDER_PATH
    generate_dockerfile portage-data
    build_repo portage-data
    run_container "${REPO}" portage-data /bin/sh
    generate_dockerfile bob
    build_repo bob

    msg "generate build order"
    cd ../$REPO_PATH
    generate_build_order "$REPOS"
    msg "build sequence: ${BUILD_ORDER}"
    msg "excluded: ${EXCLUDE}"

    b=($BUILD_ORDER)
    for REPO in "${b[@]}"; do
        build_repo "${REPO}"
    done
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
    missing) missing "$REPOS";;
    help) msg "usage: ${0} [-f, -F, -c, -C, -h] {build|missing} [repo ...]
    -f force repo rebuild
    -F also rebuild repo rootfs tar ball
    -c rebuild building containers
    -C also rebuild stage3/portage import containers
    -n do not build repo dependencies for given repo(s)
    -s skip gpg validation on downloaded files
    -h help" ;;
*) die "invalid action '${ACTION}'" ;;
esac