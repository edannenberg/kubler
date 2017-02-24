#!/usr/bin/env bash

readonly _IMAGE_PATH="images/"
readonly _BUILDER_PATH="builder/"
readonly _NAMESPACE_PATH="dock"
readonly _STAGE3_NAMESPACE="bob"
readonly _PORTAGE_IMAGE="${_STAGE3_NAMESPACE}/portage"
readonly _PORTAGE_CONTAINER="${_STAGE3_NAMESPACE}-portage"
readonly _TODAY="$(date +%Y%m%d)"
PORTAGE_DATE="${PORTAGE_DATE:-latest}"
PORTAGE_URL="${PORTAGE_URL:-${MIRROR}snapshots/}"
_portage_file="portage-${PORTAGE_DATE}.tar.xz"
BOB_HOST_UID=$(id -u)
BOB_HOST_GID=$(id -g)
DOCKER_BUILD_OPTS="${DOCKER_BUILD_OPTS:-}"

DOWNLOAD_PATH="${DOWNLOAD_PATH:-${_script_dir}/tmp/downloads}"

# used as primitive caching mechanism
_last_sourced_engine=""
_last_sourced_ns=""
_last_sourced_image=""
_last_sourced_push_conf=""

# override "safeguard"
_image_tag_root="${IMAGE_TAG?Error \$IMAGE_TAG is not defined.}"
_namespace_root="${NAMESPACE:-gentoobb}"

# Arguments
# n: message
function msg()
{
    echo -e "$@"
}

# printf version of msg(), 20 char padding between prefix and suffix
#
# Arguments:
# 1: msg_prefix
# n: msg_suffix
function msgf()
{
    local msg_prefix
    msg_prefix="$1"
    shift
    printf "%s %-20s %s\n" "-->" "${msg_prefix}" "$@"
}

# Arguments:
# 1: file_path as string
function file_exists_or_die()
{
    local file
    file="$1"
    [[ -f "${file}" ]] || die "Error: Couldn't read: ${file}"
}

function sha_sum() {
    [[ $(command -v sha512sum) ]] && echo 'sha512sum' || echo 'shasum -a512'
}

# Make sure required binaries are in PATH
function has_required_binaries() {
    local binary
    for binary in ${_required_binaries}; do
        if ! [ -x "$(command -v ${binary})" ]; then
            die "Error, ${binary} is required for this script to run. Please install and try again"
        fi
    done
}

# Returns 0 if given string contains given word or 3 if not. Does *not* match substrings.
#
# Arguments:
# 1: string
# 2: word
function string_has_word() {
    local regex
    regex="(^| )${2}($| )"
    if [[ "${1}" =~ $regex ]];then
        return 0
    else
        return 3
    fi
}

# Run sed over given $file with given $sed_args array
#
# Arguments:
# 1: full file path as string
# 2: sed_args as array
function replace_in_file()
{
    local file_path sed_arg
    file_path="${1}"
    declare -a sed_arg=("${!2}")
    sed "${sed_arg[@]}" "${file_path}" > "${file_path}.tmp" && mv "${file_path}.tmp" "${file_path}" || die
}

# Read namespace build.conf for given image_id
#
# Arguments:
# 1: image_id (i.e. gentoobb/busybox)
function source_namespace_conf() {
    local image_id current_ns
    image_id="$1"
    # reset to global defaults first..
    file_exists_or_die "${_script_dir}/build.conf" && source "${_script_dir}/build.conf"
    [[ ${image_id} != *"/"* ]] && return 0
    # ..then read namespace build.conf if passed image has a namespace
    current_ns=${image_id%%/*}
    NAMESPACE=${current_ns}
    file_exists_or_die "${current_ns}/build.conf" && source "${current_ns}/build.conf"
    # prevent setting namespace and image tag via namespace build.conf
    NAMESPACE=${current_ns}
    IMAGE_TAG=${_image_tag_root}
    if [[ "${_last_sourced_engine}" != "${CONTAINER_ENGINE}" ]]; then
        source "${_script_dir}/lib/engine/${CONTAINER_ENGINE}.sh" ||
            die "failed to source engine file ${_script_dir}/lib/engine/${CONTAINER_ENGINE}.sh"
        _last_sourced_engine="${CONTAINER_ENGINE}"
    fi
}

# Read image build.conf for given image_path
#
# Arguments:
# 1: image_path (i.e. gentoobb/images/busybox)
function source_image_conf() {
    local image_path build_conf
    image_path="$1"
    # exit if we just sourced the given build.conf
    [[ "${_last_sourced_image}" == "${image_path}" ]] && return 0
    unset BOB_CHOST BOB_CFLAGS BOB_CXXFLAGS BOB_BUILDER_CHOST BOB_BUILDER_CFLAGS BOB_BUILDER_CXXFLAGS ARCH ARCH_URL IMAGE_TAG
    source_namespace_conf "${image_path}"
    unset STAGE3_BASE STAGE3_DATE IMAGE_PARENT BUILDER BUILD_PRIVILEGED
    build_conf="${image_path}/build.conf"
    file_exists_or_die "${build_conf}" && source "${build_conf}"
    # stage3 overrides BUILDER, unset if defined
    [[ ! -z ${STAGE3_BASE} ]] && unset BUILDER
    _last_sourced_image="${image_path}"
}

# Read namespace push.conf for given image_id
#
# Arguments:
# 1: image_id (i.e. gentoobb/busybox)
function source_push_conf() {
    local namespace
    namespace=${1%%/*}
    # exit if we just sourced for this NS
    [[ "${_last_sourced_push_conf}" == "${namespace}" ]] && return 0
    [[ -f "${namespace}/push.conf" ]] && source "${namespace}/push.conf"
    _last_sourced_push_conf="${namespace}"
}

# Download and verify stage3 tar ball
function download_stage3() {
    [[ -d "${DOWNLOAD_PATH}" ]] || mkdir -p "${DOWNLOAD_PATH}"
    local is_autobuild stage3_contents stage3_digests sha512_hashes sha512_check sha512_failed wget_exit
    is_autobuild=false
    _stage3_file="${STAGE3_BASE}-${STAGE3_DATE}.tar.bz2"
    stage3_contents="${_stage3_file}.CONTENTS"
    stage3_digests="${_stage3_file}.DIGESTS"
    if [[ "${ARCH_URL}" == *autobuilds*  ]]; then
        stage3_digests="${_stage3_file}.DIGESTS.asc"
        is_autobuild=true
    fi

    for file in "${_stage3_file}" "${stage3_contents}" "${stage3_digests}"; do
        [ -f "${DOWNLOAD_PATH}/${file}" ] && continue
        wget -O "${DOWNLOAD_PATH}/${file}" "${ARCH_URL}${file}"
        wget_exit=$?
        if [[ "${wget_exit}" -ne 0 ]]; then
            rm -f "${DOWNLOAD_PATH}/${file}"
            # give hint if 404
            [[ "${wget_exit}" -eq 8 ]] && die "Error, got a 404 for ${file}, try running update to resolve this."
            die "Error, couldn't download ${ARCH_URL}${file}"
        fi
    done

    if [ "${_arg_skip_gpg_check}" = false ] && [ "${is_autobuild}" = true ]; then
        gpg --verify "${DOWNLOAD_PATH}/${stage3_digests}" || die "insecure digests"
    elif [ "${is_autobuild}" = false ]; then
        msg "GPG verification not supported for experimental stage3 tar balls, only checking SHA512"
    fi
    sha512_hashes=$(grep -A1 SHA512 "${DOWNLOAD_PATH}/${stage3_digests}" | grep -v '^--')
    sha512_check=$(cd "${DOWNLOAD_PATH}/" && (echo "${sha512_hashes}" | $(sha_sum) -c))
    sha512_failed=$(echo "${sha512_check}" | grep FAILED)
    if [ -n "${sha512_failed}" ]; then
        die "${sha512_failed}"
    fi
}

# Download and verify portage snapshot, when using latest it will download at most once per day
function download_portage_snapshot() {
    [ -d "${DOWNLOAD_PATH}" ] || mkdir -p "${DOWNLOAD_PATH}"
    local portage_sig portage_md5 file portage_backup dl_name
    portage_sig="${_portage_file}.gpgsig"
    portage_md5="${_portage_file}.md5sum"

    for file in "${_portage_file}" "${portage_sig}" "${portage_md5}"; do
        dl_name="${file}"
        if [[ "${PORTAGE_DATE}" == "latest" ]]; then
            dl_name="${_portage_file//latest/${_TODAY}}"
        fi
        if [ ! -f "${DOWNLOAD_PATH}/${dl_name}" ]; then
            wget -O "${DOWNLOAD_PATH}/${dl_name}" "${MIRROR}snapshots/${file}"
            [[ $? -ne 0 ]] && rm "${DOWNLOAD_PATH}/${file}" && die "Error, couldn't download ${MIRROR}snapshots/${file}"
        fi
    done

    # use current date instead of latest from here on
    if [[ "${PORTAGE_DATE}" == "latest" ]]; then
        portage_sig="${_portage_file//latest/${_TODAY}}.gpgsig"
        portage_md5="${_portage_file//latest/${_TODAY}}.md5sum"
        _portage_file="${_portage_file//latest/${_TODAY}}"
        PORTAGE_DATE="${_TODAY}"
    fi

    if [[ "${_arg_skip_gpg_check}" != "on" ]] && [ -f "${DOWNLOAD_PATH}/${portage_sig}" ]; then
        gpg --verify "${DOWNLOAD_PATH}/${portage_sig}" "${DOWNLOAD_PATH}/${_portage_file}" || die "Error, insecure digests."
    fi
}

# Sets __expand_image_id to image sub-path for given image_id
#
# 1: image_id (i.e. gentoobb/busybox)
# 2: image_type ($_IMAGE_PATH or $_BUILDER_PATH)
function expand_image_id() {
    # assume failure
    __expand_image_id=
    local image_id image_type
    image_id="$1"
    image_type="$2"
    __expand_image_id=${image_id/\//\/${image_type}}
}

# Sets __expand_requested_target_ids to requested namespace and image mix of build command,
# i.e. build gentoobb/busybox mynamespace othernamespace/myimage
#
# Arguments:
# n: target_id (i.e. namespace or namespace/image)
function expand_requested_target_ids() {
    # assume failure
    __expand_requested_target_ids=
    local target_ids expanded target image
    target_ids="$1"
    expanded=""
    for target in $target_ids; do
        if [[ "${target}" == *"/"* ]]; then
            expand_image_id "${target}" "${_IMAGE_PATH}"
            [[ ! -d "${__expand_image_id}" ]] && die "Error: Couldn't find image folder for ${target}"
            expanded+=" ${target}"
        else
            [[ ! -d "${target}/${_IMAGE_PATH}" ]] && die "Error: Couldn't find namespace folder for ${target}"
            for image in "${target}/${_IMAGE_PATH}"*; do
               expanded+=" ${image/${_IMAGE_PATH}/}"
            done
        fi
    done
    __expand_requested_target_ids=$expanded
}

# Generate PACKAGES.md header
#
# Arguments:
# 1: image
# 2: image_type ($_IMAGE_PATH or $_BUILDER_PATH)
function add_documentation_header() {
    local image image_type doc_file header
    image="$1"
    image_type="$2"
    expand_image_id "${image}" "${image_type}"
    doc_file="${__expand_image_id}/PACKAGES.md"
    header="### ${image}:${IMAGE_TAG}"
    get_image_size "${image}" "${IMAGE_TAG}"
    # remove existing header
    if [[ -f "${doc_file}" ]]; then
        $(grep -q "^${header}" ${doc_file}) && sed -i '1,4d' "${doc_file}"
    else
        echo -e "" > "${doc_file}"
    fi
    # add header
    echo -e "${header}\n\nBuilt: $(date)\nImage Size: ${__get_image_size}\n\n$(cat "${doc_file}")" > "${doc_file}"
}
