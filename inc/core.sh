#!/bin/bash

FORCE_REBUILD=false
FORCE_ROOTFS_REBUILD=false
FORCE_BUILDER_REBUILD=false
FORCE_FULL_REBUILD=false
BUILD_WITHOUT_DEPS=false
IMAGE_PATH="images/"
BUILDER_PATH="builder/"

die()
{
    echo -e "$1"
    exit 1
}

msg()
{
    echo -e "--> $@"
}

# Make sure required binaries are in PATH
has_required_binaries() {
    for BINARY in ${REQUIRED_BINARIES}; do
        if ! [ -x "$(command -v ${BINARY})" ]; then
            die "${BINARY} is required for this script to run. Please install and try again"
        fi
    done
}

LAST_SOURCED_NS=""
LAST_SOURCED_PUSH_CONF=""
LAST_SOURCED_ENGINE=""

# Read namespace build.conf for given REPO_ID
#
# Arguments:
# 1: REPO_ID (i.e. gentoobb/busybox)
source_namespace_conf() {
    # exit if we just sourced the given NS
    [[ "${LAST_SOURCED_NS}" == ${1%%/*} ]] && return 0
    # reset to global defaults first..
    [[ -f ${PROJECT_ROOT}/build.conf ]] && source ${PROJECT_ROOT}/build.conf
    # ..then read namespace build.conf if passed args have a namespace
    [[ ${1} != *"/"* ]] && return 0
    local CURRENT_NS=${1%%/*}
    NAMESPACE=${CURRENT_NS}
    [[ -f $CURRENT_NS/build.conf ]] && source $CURRENT_NS/build.conf
    # prevent setting namespace and date via namespace build.conf
    NAMESPACE=${CURRENT_NS}
    LAST_SOURCED_NS=${NAMESPACE}
    DATE=${DATE_ROOT}
    if [[ "${LAST_SOURCED_ENGINE}" != "${CONTAINER_ENGINE}" ]]; then
        source "${PROJECT_ROOT}/inc/engine/${CONTAINER_ENGINE}.sh" ||
            die "failed to source engine file ${PROJECT_ROOT}/inc/engine/${CONTAINER_ENGINE}.sh"
        LAST_SOURCED_ENGINE="${CONTAINER_ENGINE}"
    fi
}

# Read namespace push.conf for given REPO_ID
#
# Arguments:
# 1: REPO_ID (i.e. gentoobb/busybox)
source_push_conf() {
    local NAMESPACE=${1%%/*}
    # exit if we just sourced for this NS
    [[ "${LAST_SOURCED_PUSH_CONF}" == "${NAMESPACE}" ]] && return 0
    [[ -f "${NAMESPACE}/push.conf" ]] && source "${NAMESPACE}/push.conf"
    LAST_SOURCED_PUSH_CONF="${NAMESPACE}"
}

# Returns 0 if given string contains given word. Does not match substrings.
#
# Arguments:
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

# Download and verify stage3 tar ball
download_stage3() {
    [ -d $DL_PATH ] || mkdir -p $DL_PATH

    for FILE in "${STAGE3}" "${STAGE3_CONTENTS}" "${STAGE3_DIGESTS}"; do
        [ -f "$DL_PATH/${FILE}" ] && continue
        wget -O "$DL_PATH/${FILE}" "${ARCH_URL}${FILE}" ||
            (rm "$DL_PATH/${FILE}" && die "failed to download ${ARCH_URL}${FILE}")
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
}

# Download and verify portage snapshot
download_portage_snapshot()
{
    [ -d ${DL_PATH} ] || mkdir -p ${DL_PATH}

    for FILE in "${PORTAGE}" "${PORTAGE_SIG}" "${PORTAGE_MD5}"; do
        if [ ! -f "${DL_PATH}/${FILE}" ]; then
            wget -O "${DL_PATH}/${FILE}" "${PORTAGE_URL}${FILE}" ||
                (msg "failed to download ${PORTAGE_URL}${FILE}" && rm "${DL_PATH}/${FILE}")
        fi
    done

    if [ "$SKIP_GPG" = false ] && [ -f "${DL_PATH}/${PORTAGE_SIG}" ]; then
        gpg --verify "${DL_PATH}/${PORTAGE_SIG}" "${DL_PATH}/${PORTAGE}" || die "insecure digests"
    fi
}

# Expand requested namespace/image mix of build command, i.e. build gentoobb/busybox mynamespace othernamespace/myimage
#
# Arguments:
# 1: REPO(S)/NAMESPACE(S)
expand_requested_repos() {
    local REPO_ARGS="${1}"
    EXPANDED=""
    for REPO in $REPO_ARGS; do
        if [[ $REPO == *"/"* ]]; then
            [[ ! -d ${REPO/\//\/${IMAGE_PATH}} ]] && return 1
            EXPANDED+=" ${REPO}"
        else
           [[ ! -d ${REPO}/${IMAGE_PATH} ]] && return 1
           for IMAGE in ${REPO}/${IMAGE_PATH}*; do
               EXPANDED+=" ${IMAGE/${IMAGE_PATH}/}"
            done
        fi
    done
    echo $EXPANDED
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
    IMAGE_SIZE="$(get_image_size ${REPO} ${DATE})" || die "failed to get image size: ${IMAGE_SIZE}"
    # remove existing header
    if [[ -f ${DOC_FILE} ]]; then
        $(grep -q "^${HEADER}" ${DOC_FILE}) && sed -i '1,4d' ${DOC_FILE}
    else
        echo -e "" > ${DOC_FILE}
    fi
    # add header
    sed -i "1i${HEADER}\nBuilt: $(date)\n\nImage Size: $IMAGE_SIZE" $DOC_FILE
}
