#!/bin/bash

FORCE_REBUILD=false
FORCE_ROOTFS_REBUILD=false
FORCE_BUILDER_REBUILD=false
FORCE_FULL_REBUILD=false
BUILD_WITHOUT_DEPS=false
IMAGE_PATH="images/"
BUILDER_PATH="builder/"
REPO_PATH="dock"
BOB_HOST_UID=$(id -u)
BOB_HOST_GID=$(id -g)

die()
{
    echo -e "$1"
    exit 1
}

msg()
{
    echo -e "--> $@"
}

msgf()
{
    local PREFIX="${1}"
    shift
    printf "%s %-20s %s\n" "-->" "${PREFIX}" "${@}"
}

sha_sum() {
    [[ $(command -v sha512sum) ]] && echo 'sha512sum' || echo 'shasum -a512'
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
    # reset to global defaults first..
    [[ -f ${PROJECT_ROOT}/build.conf ]] && source ${PROJECT_ROOT}/build.conf || die "could not read ${PROJECT_ROOT}/build.conf"
    # ..then read namespace build.conf if passed args have a namespace
    [[ ${1} != *"/"* ]] && return 0
    local CURRENT_NS=${1%%/*}
    NAMESPACE=${CURRENT_NS}
    [[ -f $CURRENT_NS/build.conf ]] && source $CURRENT_NS/build.conf
    # prevent setting namespace and image tag via namespace build.conf
    NAMESPACE=${CURRENT_NS}
    IMAGE_TAG=${IMAGE_TAG_ROOT}
    if [[ "${LAST_SOURCED_ENGINE}" != "${CONTAINER_ENGINE}" ]]; then
        source "${PROJECT_ROOT}/inc/engine/${CONTAINER_ENGINE}.sh" ||
            die "failed to source engine file ${PROJECT_ROOT}/inc/engine/${CONTAINER_ENGINE}.sh"
        LAST_SOURCED_ENGINE="${CONTAINER_ENGINE}"
    fi
}

# Read image build.conf for given EXPANDED_REPO_ID
#
# Arguments:
# 1: EXPANDED_REPO_ID (i.e. gentoobb/images/busybox)
source_image_conf() {
    # exit if we just sourced the given build.conf
    [[ "${LAST_SOURCED_IMAGE}" == ${1} ]] && return 0
    unset BOB_CHOST BOB_CFLAGS BOB_CXXFLAGS BOB_BUILDER_CHOST BOB_BUILDER_CFLAGS BOB_BUILDER_CXXFLAGS ARCH ARCH_URL IMAGE_TAG
    source_namespace_conf ${1}
    unset STAGE3_BASE STAGE3_DATE IMAGE_PARENT BUILDER
    local BUILD_CONF="${1}/build.conf"
    [[ -f ${BUILD_CONF} ]] && source ${BUILD_CONF} || die "Could not read required ${BUILD_CONF}"
    # stage3 overrides BUILDER, unset if defined
    [[ ! -z ${STAGE3_BASE} ]] && unset BUILDER
    LAST_SOURCED_IMAGE=${1}
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

# Run sed over given $file with given $sed_args array
#
# Arguments:
# 1: full file path as string
# 2: sed_args as array
replace_in_file()
{
    local file_path="${1}"
    declare -a sed_arg=("${!2}")
    sed "${sed_arg[@]}" "${file_path}" > "${file_path}.tmp" && mv "${file_path}.tmp" "${file_path}" || die
}

# Download and verify stage3 tar ball
download_stage3() {
    [ -d $DL_PATH ] || mkdir -p $DL_PATH

    local IS_AUTOBUILD=false
    STAGE3="${STAGE3_BASE}-${STAGE3_DATE}.tar.bz2"
    local STAGE3_CONTENTS="${STAGE3}.CONTENTS"
    local STAGE3_DIGESTS="${STAGE3}.DIGESTS"
    if [[ $ARCH_URL == *autobuilds*  ]]; then
        STAGE3_DIGESTS="${STAGE3}.DIGESTS.asc"
        IS_AUTOBUILD=true
    fi

    for FILE in "${STAGE3}" "${STAGE3_CONTENTS}" "${STAGE3_DIGESTS}"; do
        [ -f "$DL_PATH/${FILE}" ] && continue
        wget -O "$DL_PATH/${FILE}" "${ARCH_URL}${FILE}" ||
            (rm "$DL_PATH/${FILE}" && die "failed to download ${ARCH_URL}${FILE}")
    done

    if [ "$SKIP_GPG" = false ] && [ "${IS_AUTOBUILD}" = true ]; then
        gpg --verify "$DL_PATH/${STAGE3_DIGESTS}" || die "insecure digests"
    elif [ "${IS_AUTOBUILD}" = false ]; then
        msg "GPG verification not supported for experimental stage3 tar balls, only checking SHA512"
    fi
    SHA512_HASHES=$(grep -A1 SHA512 "$DL_PATH/${STAGE3_DIGESTS}" | grep -v '^--')
    SHA512_CHECK=$(cd $DL_PATH/ && (echo "${SHA512_HASHES}" | $(sha_sum) -c))
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
    HEADER="### ${REPO}:${IMAGE_TAG}"
    IMAGE_SIZE="$(get_image_size ${REPO} ${IMAGE_TAG})" || die "failed to get image size: ${IMAGE_SIZE}"
    # remove existing header
    if [[ -f ${DOC_FILE} ]]; then
        $(grep -q "^${HEADER}" ${DOC_FILE}) && sed -i '1,4d' ${DOC_FILE}
    else
        echo -e "" > ${DOC_FILE}
    fi
    # add header
    echo -e "${HEADER}\n\nBuilt: $(date)\nImage Size: $IMAGE_SIZE\n$(cat $DOC_FILE)" > $DOC_FILE
}
