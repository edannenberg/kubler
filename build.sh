#!/bin/sh
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
DATE="${DATE:-20140731}"
MIRROR="${MIRROR:-http://distfiles.gentoo.org/}"
ARCH_URL="${ARCH_URL:-${MIRROR}releases/amd64/autobuilds/${DATE}/}"
STAGE3="${STAGE3:-stage3-amd64-nomultilib-${DATE}.tar.bz2}"
STAGE3_CONTENTS="${STAGE3_CONTENTS:-${STAGE3}.CONTENTS}"
STAGE3_DIGESTS="${STAGE3_DIGESTS:-${STAGE3}.DIGESTS.asc}"
PORTAGE_URL="${PORTAGE_URL:-${MIRROR}snapshots/}"
#PORTAGE="${PORTAGE:-portage-${DATE}.tar.xz}"
PORTAGE="${PORTAGE:-portage-latest.tar.xz}"
PORTAGE_SIG="${PORTAGE_SIG:-${PORTAGE}.gpgsig}"

DOCKER_IO=$(command -v docker.io)
DOCKER="${DOCKER:-${DOCKER_IO:-docker}}"
BUILD_OPTS="${BUILD_OPTS:-}"
BUILDER_PATH="${REPO_PATH:-bb-builder}"
REPO_PATH="${REPO_PATH:-bb-dock}"
DL_PATH=tmp/downloads
SKIP_GPG=false

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
        "${DOCKER}" run --rm --volumes-from portage-data \
            -v $(dirname $(realpath -s $0))/$REPO:/config \
            -v $(realpath -s ../tmp/distfiles):/distfiles \
            -v $(realpath -s ../tmp/packages):/packages \
            -i -t "${NAMESPACE}/bob:${DATE}" build-root $REPO || die "failed to build rootfs for $REPO"
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
    < "${REPO}/Dockerfile.template" > "${REPO}/Dockerfile"
    
    msg "build ${NAMESPACE}/${REPO}:${DATE}"
    "${DOCKER}" build ${BUILD_OPTS} -t "${NAMESPACE}/${REPO}:${DATE}" "${REPO}" || die "failed to build ${REPO}"
    rm "${REPO}/Dockerfile"
    fi
    msg "tag ${NAMESPACE}/${REPO}:latest"
    "${DOCKER}" tag -f "${NAMESPACE}/${REPO}:${DATE}" "${NAMESPACE}/${REPO}:latest" || die "failed to tag ${REPO}"

}

# Run a container
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

build()
{
    import_stage3
    import_portage

    cd $BUILDER_PATH
    build_repo portage-data
    run_container "${REPO}" portage-data /bin/sh
    build_repo bob

    cd ../$REPO_PATH
    for REPO in $1; do
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

while getopts ":fFcCsh" opt; do
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
    -s skip gpg validation on downloaded files
    -h help" ;;
*) die "invalid action '${ACTION}'" ;;
esac