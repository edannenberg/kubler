#!/usr/bin/env bash
#
# Copyright (c) 2014-2017, Erik Dannenberg <erik.dannenberg@xtrade-gmbh.de>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
# following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following
#    disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
# following disclaimer in the documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

readonly _KUBLER_NAMESPACE_DIR="${_KUBLER_DIR}"/dock
readonly _KUBLER_CONF='kubler.conf'
readonly _IMAGE_PATH="images/"
readonly _BUILDER_PATH="builder/"
readonly _STAGE3_NAMESPACE="kubler-gentoo"
readonly _PORTAGE_IMAGE="${_STAGE3_NAMESPACE}/portage"
readonly _PORTAGE_CONTAINER="${_STAGE3_NAMESPACE}-portage"
readonly _TODAY="$(date +%Y%m%d)"

# shellcheck disable=SC2034
BOB_HOST_UID=$(id -u)
# shellcheck disable=SC2034
BOB_HOST_GID=$(id -g)

# stage3 defaults, override via build container .conf
STAGE3_BASE="stage3-amd64-hardened+nomultilib"

# used as primitive caching mechanism
_last_sourced_engine=
_last_sourced_image=
_last_sourced_push_conf=

# Arguments
# n: message
function msg() {
    echo -e "$@"
}

# printf version of msg(), 20 char padding between prefix and suffix
#
# Arguments:
# 1: msg_prefix
# n: msg_suffix
function msgf() {
    local msg_prefix
    msg_prefix="$1"
    shift
    printf '%s %-20s %s\n' '-->' "${msg_prefix}" "$@"
}

# Read user input displaying given question
#
# Arguments:
# 1: question
# 2: default_value
# Return value: user input or passed default_value
function ask() {
    __ask=
    local question default_value
    question="$1"
    default_value="$2"
    read -r -p "${question} (${default_value}): " __ask
    [[ -z "${__ask}" ]] && __ask="${default_value}"
}

# Arguments:
# 1: file_path as string
# 2: error_msg, optional
function file_exists_or_die() {
    local file error_msg
    file="$1"
    [[ -z "$2" ]] && error_msg="Couldn't read: ${file}"
    [[ -f "${file}" ]] || die "${error_msg}"
}

function sha_sum() {
    [[ $(command -v sha512sum) ]] && echo 'sha512sum' || echo 'shasum -a512'
}

# Make sure required binaries are in PATH
function has_required_binaries() {
    local binary
    for binary in ${_required_binaries}; do
        if ! [ -x "$(command -v "${binary}")" ]; then
            die "${binary} is required for this script to run. Please install and try again"
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
function replace_in_file() {
    local file_path sed_arg
    file_path="${1}"
    declare -a sed_arg=("${!2}")
    sed "${sed_arg[@]}" "${file_path}" > "${file_path}.tmp" || die
    mv "${file_path}.tmp" "${file_path}" || die
}

# Source build engine script depending on BUILD_ENGINE value
function source_build_engine() {
    local engine
    engine="${_LIB_DIR}/engine/${BUILD_ENGINE}.sh"
    if [[ "${_last_sourced_engine}" != "${BUILD_ENGINE}" ]]; then
        file_exists_or_die "${engine}"
        # shellcheck source=lib/engine/docker.sh
        source "${engine}"
        _last_sourced_engine="${BUILD_ENGINE}"
    fi
}

# Read namespace build.conf for given image_id
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
function source_namespace_conf() {
    local image_id current_ns conf_file
    image_id="$1"

    [[ "${_NAMESPACE_TYPE}" == 'single' ]] && return 0

    # reset to possible user conf first..
    # shellcheck disable=SC1090
    [[ -f "${_ns_conf}" ]] && source "${_ns_conf}"

    # ..then read project conf to initialize any missing defaults if necessary
    # shellcheck source=kubler.conf
    [[ "${_ns_conf}" != "${_global_conf}" ]] && source "${_global_conf}"

    [[ "${image_id}" != *"/"* ]] && return 0

    current_ns="${image_id%%/*}"
    conf_file="${_NAMESPACE_DIR}/${current_ns}/${_KUBLER_CONF}"

    # ..then read current namespace conf
    # shellcheck source=dock/kubler/kubler.conf
    file_exists_or_die "${conf_file}" && source "${conf_file}"
    _current_namespace="${current_ns}"
    # just for BC and to make build.conf/templates a bit more consistent to use. not used otherwise
    NAMESPACE="${current_ns}"

    source_build_engine
}

# Read image build.conf for given image_path
#
# Arguments:
# 1: image_path (i.e. kubler/images/busybox)
function source_image_conf() {
    local image_path build_conf
    image_path="$1"
    # exit if we just sourced the given build.conf
    [[ "${_last_sourced_image}" == "${image_path}" ]] && return 0
    if [[ "${_NAMESPACE_TYPE}" != 'single' ]]; then
        unset BOB_CHOST BOB_CFLAGS BOB_CXXFLAGS BOB_BUILDER_CHOST BOB_BUILDER_CFLAGS BOB_BUILDER_CXXFLAGS ARCH ARCH_URL IMAGE_TAG
        source_namespace_conf "${image_path}"
    fi
    unset STAGE3_BASE STAGE3_DATE IMAGE_PARENT BUILDER BUILD_PRIVILEGED
    [[ -z "${_use_parent_builder_mounts}" ]] && unset BUILDER_MOUNTS

    build_conf="${image_path}/build.conf"
    # shellcheck source=dock/kubler/images/busybox/build.conf
    file_exists_or_die "${build_conf}" && source "${build_conf}"

    # assume scratch if IMAGE_PARENT is not set
    [[ -z "${IMAGE_PARENT}" ]] && IMAGE_PARENT='scratch'

    # stage3 overrides BUILDER, unset if defined
    [[ -n "${STAGE3_BASE}" ]] && unset BUILDER

    _last_sourced_image="${image_path}"
}

# Read namespace push.conf for given image_id
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
function source_push_conf() {
    local namespace
    namespace=${1%%/*}
    # exit if we just sourced for this NS
    [[ "${_last_sourced_push_conf}" == "${namespace}" ]] && return 0
    # shellcheck disable=SC1090
    [[ -f "${namespace}/push.conf" ]] && source "${namespace}/push.conf"
    _last_sourced_push_conf="${namespace}"
}

# Check image dependencies and return base build container for given image_id. Recursive.
#
# Arguments:
#
# 1: image_id
function get_image_builder_id() {
    __get_image_builder_id=
    local image_id
    image_id="$1"
    [[ "${image_id}" == 'scratch' ]] && __get_image_builder_id="${DEFAULT_BUILDER}" && return 0
    expand_image_id "${image_id}" "${_IMAGE_PATH}"
    if [[ -n "${image_id}" && "${image_id}" != "scratch" ]]; then
        # shellcheck disable=SC2154
        source_image_conf "${__expand_image_id}"
        if [[ -n "${BUILDER}" ]];then
            __get_image_builder_id="${BUILDER}"
        elif [[ -n "${IMAGE_PARENT}" ]]; then
            get_image_builder_id "${IMAGE_PARENT}"
        else
            __get_image_builder_id="${DEFAULT_BUILDER}"
        fi
    fi
}

# Download and verify stage3 tar ball
function download_stage3() {
    ARCH="${ARCH:-amd64}"
    ARCH_URL="${ARCH_URL:-${MIRROR}releases/${ARCH}/autobuilds/current-${STAGE3_BASE}/}"

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
        trap 'handle_download_error ${DOWNLOAD_PATH}/${file}' EXIT
        wget -O "${DOWNLOAD_PATH}/${file}" "${ARCH_URL}${file}"
        wget_exit=$?
        [[ "${wget_exit}" -eq 8 ]] && msg "*** Got a 404 for ${file}, try running the update command to resolve this."
        [[ "${wget_exit}" -ne 0 ]] && exit $?
        trap - EXIT
    done
    # shellcheck disable=SC2154
    if [ "${_arg_skip_gpg_check}" = false ] && [ "${is_autobuild}" = true ]; then
        gpg --verify "${DOWNLOAD_PATH}/${stage3_digests}" || die "insecure digests"
    elif [ "${is_autobuild}" = false ]; then
        msg "GPG verification not supported for experimental stage3 tar balls, only checking SHA512"
    fi
    sha512_hashes="$(grep -A1 SHA512 "${DOWNLOAD_PATH}/${stage3_digests}" | grep -v '^--')"
    sha512_check="$(cd "${DOWNLOAD_PATH}/" && (echo "${sha512_hashes}" | $(sha_sum) -c))"
    sha512_failed="$(echo "${sha512_check}" | grep FAILED)"
    if [ -n "${sha512_failed}" ]; then
        die "${sha512_failed}"
    fi
}

# Download and verify portage snapshot, when using latest it will download at most once per day
function download_portage_snapshot() {
    PORTAGE_DATE="${PORTAGE_DATE:-latest}"
    PORTAGE_URL="${PORTAGE_URL:-${MIRROR}snapshots/}"
    [[ -d "${DOWNLOAD_PATH}" ]] || mkdir -p "${DOWNLOAD_PATH}"
    local portage_sig portage_md5 file dl_name
    _portage_file="portage-${PORTAGE_DATE}.tar.xz"
    portage_sig="${_portage_file}.gpgsig"
    portage_md5="${_portage_file}.md5sum"

    for file in "${_portage_file}" "${portage_sig}" "${portage_md5}"; do
        dl_name="${file}"
        if [[ "${PORTAGE_DATE}" == 'latest' ]]; then
            dl_name="${_portage_file//latest/${_TODAY}}"
        fi
        if [ ! -f "${DOWNLOAD_PATH}/${dl_name}" ]; then
            trap 'handle_download_error ${DOWNLOAD_PATH}/${dl_name}' EXIT
            wget -O "${DOWNLOAD_PATH}/${dl_name}" "${MIRROR}snapshots/${file}" || exit $?
            trap - EXIT
        fi
    done

    # use current date instead of latest from here on
    if [[ "${PORTAGE_DATE}" == 'latest' ]]; then
        portage_sig="${_portage_file//latest/${_TODAY}}.gpgsig"
        portage_md5="${_portage_file//latest/${_TODAY}}.md5sum"
        _portage_file="${_portage_file//latest/${_TODAY}}"
        PORTAGE_DATE="${_TODAY}"
    fi

    if [[ "${_arg_skip_gpg_check}" != 'on' ]] && [[ -f "${DOWNLOAD_PATH}/${portage_sig}" ]]; then
        gpg --verify "${DOWNLOAD_PATH}/${portage_sig}" "${DOWNLOAD_PATH}/${_portage_file}" || die "Insecure digests."
    fi
}

# Arguments:
# 1: file - full path of downloaded file
# 2: error_message - optional
function handle_download_error() {
    local file msg
    file="$1"
    msg="${2:-Aborted download of ${file}}"
    [[ -f "${file}" ]] && rm "${file}"
    die "${msg}"
}

# Sets __expand_image_id to image sub-path for given image_id
#
# 1: image_id (i.e. kubler/busybox)
# 2: image_type ($_IMAGE_PATH or $_BUILDER_PATH)
function expand_image_id() {
    __expand_image_id=
    local image_id image_type msg_type
    image_id="$1"
    image_type="$2"
    msg_type='image'
    [[ "${image_type}" == "${_BUILDER_PATH}" ]] && msg_type="builder"
    if [[ "${_NAMESPACE_TYPE}" == 'single' ]]; then
        if [[ "${image_id}" == *"/"* ]]; then
            image_ns="${image_id%%/*}"
            [[ "${image_ns}" != "${_current_namespace}" ]] \
                && die "Unknown namespace \"${image_ns}\" for ${msg_type} ${image_id}, expected \"${_current_namespace}\""
            image_id="${image_id##*/}"
        fi
        __expand_image_id="${image_type}${image_id}"
    else
        __expand_image_id="${image_id/\//\/${image_type}}"
    fi
}

# Expand requested namespace and image mix of passed target_ids to fully qualified image ids
# i.e. kubler/busybox mynamespace othernamespace/myimage
#
# Arguments:
# n: target_id (i.e. namespace or namespace/image)
function expand_requested_target_ids() {
    __expand_requested_target_ids=
    local target_ids expanded target image current_ns
    target_ids=( "$@" )
    expanded=""
    if [[ "${_NAMESPACE_TYPE}" == 'single' ]]; then
        current_ns="$(basename -- "${_NAMESPACE_DIR}")"
        for target in "${target_ids[@]}"; do
            # strip namespace if this is a fully qualified image id, redundant in single namespace mode
            if [[ "${target}" == *"/"* ]]; then
                [[ "${target%%/*}" != "${current_ns}" ]] && die "Invalid namespace for ${target}, expected: ${current_ns}"
                target="${target##*/}"
            fi
            expand_image_id "${target}" "${_IMAGE_PATH}"
            [[ ! -d "${__expand_image_id}" ]] && die "Couldn't find image ${target} in ${_NAMESPACE_DIR}"
            expanded+=" ${current_ns}/${target}"
        done
    else
        local is_processed
        for target in "${target_ids[@]}"; do
            is_processed=
            # is target a fully qualified image id?
            if [[ "${target}" == *"/"* ]]; then
                expand_image_id "${target}" "${_IMAGE_PATH}"
                [[ ! -d "${__expand_image_id}" ]] && die "Couldn't find image ${target} in ${_NAMESPACE_DIR}"
                expanded+=" ${target}"
            else
                # is target an image id with omitted namespace?
                if [[ -n "${_NAMESPACE_DEFAULT}" ]]; then
                    expand_image_id "${_NAMESPACE_DEFAULT}/${target}" "${_IMAGE_PATH}"
                    if [[ -d "${__expand_image_id}" ]]; then
                        expanded+=" ${_NAMESPACE_DEFAULT}/${target}"
                        is_processed=1
                    fi
                fi
                # ..if not it should be a namespace, expand to image ids
                if [[ -z "${is_processed}" ]]; then
                    [[ ! -d "${_NAMESPACE_DIR}/${target}/${_IMAGE_PATH}" ]] \
                        && die "Couldn't find namespace ${target} in ${_NAMESPACE_DIR}"
                    pushd "${_NAMESPACE_DIR}" > /dev/null || die "pushd error on directory ${_NAMESPACE_DIR}"
                    for image in "${target}/${_IMAGE_PATH}"*; do
                       expanded+=" ${image/${_IMAGE_PATH}/}"
                    done
                    popd > /dev/null || die "popd failed in function expand_requested_target_ids"
                fi
            fi
        done
    fi
    # shellcheck disable=SC2034
    __expand_requested_target_ids=${expanded}
}

# Sets __find_in_parents to path where given search_path exists, or empty string if it doesn't.
# Starts with given start_path, then traverses all it's parent directories.
#
# 1: start_path
# 2: search_path
function find_in_parents() {
    __find_in_parents=
    local path search_path
    path="$1"
    search_path="$2"
    while [[ "${path}" != "" && ! -e "${path}/${search_path}" ]]; do
        path="${path%/*}"
    done
    __find_in_parents="${path}"
}

# Set the _NAMESPACE_DIR and _NAMESPACE_TYPE variables for given working_dir
# Types:
# local  - path is inside kubler project root
# multi  - directory with multiple namespaces outside of project root
# single - only a single namespace dir outside of project root
# none   - only allowed when creating a new namespace
#
# 1: working_dir
function detect_namespace() {
    local working_dir real_ns_dir parent_dir parent_conf
    working_dir="$1"
    _global_conf="${_KUBLER_DIR}/${_KUBLER_CONF}"
    _ns_conf="${_global_conf}"

    get_absolute_path "${working_dir}"
    [[ -d "${__get_absolute_path}" ]] || die "Couldn't find namespace location: ${working_dir}"

    # find next namespace dir, respect symlink paths, as in don't resolve
    find_in_parents "${working_dir}" "${_KUBLER_CONF}"
    real_ns_dir="${__find_in_parents}"

    # working dir inside kubler project root?
    if [[ "${working_dir}" == "${_KUBLER_DIR}"* ]]; then
        # ..and inside a namespace dir?
        if [[ -d "${real_ns_dir}/${_IMAGE_PATH}" ]]; then
            readonly _NAMESPACE_DEFAULT="$(basename -- "${real_ns_dir}")"
        fi
        real_ns_dir="${_KUBLER_DIR}"/dock
        readonly _NAMESPACE_TYPE='local'
    else
        # allow missing namespace dir for new command, the user might want to create a new namespace
        if [[ -z "${real_ns_dir}" ]]; then
            # shellcheck disable=SC2154
            if [[ "${_arg_command}" == 'new' ]]; then
                real_ns_dir="${working_dir}"
                readonly _NAMESPACE_TYPE='none'
            else
                die "Couldn't find ${_KUBLER_CONF} in current or parent directories starting from ${working_dir}
               Either cd to Kubler's project root or cd-into/create an external namespace dir."
            fi
        fi
        _ns_conf="${real_ns_dir}/${_KUBLER_CONF}"

        parent_dir="$(dirname -- "${real_ns_dir}")"
        parent_conf="${parent_dir}/${_KUBLER_CONF}"
        # is it a single namespace dir?
        if [[ -d "${real_ns_dir}/${_IMAGE_PATH}" ]]; then
            readonly _NAMESPACE_DEFAULT="$(basename -- "${real_ns_dir}")"
            if [[ ! -f "${parent_conf}" ]]; then
                readonly _NAMESPACE_TYPE='single'
                _current_namespace="${_NAMESPACE_DEFAULT}"
                # just for BC and to make build.conf/templates a bit more consistent to use. not used otherwise
                NAMESPACE="${_current_namespace}"
            else
                real_ns_dir="${parent_dir}"
                _ns_conf="${parent_conf}"
            fi
        fi

    fi
    # else assume multi mode
    [[ -z "${_NAMESPACE_TYPE}" ]] && readonly _NAMESPACE_TYPE='multi'

    # read namespace config first..
    # shellcheck disable=SC1090
    [[ -f "${_ns_conf}" ]] && source "${_ns_conf}"

    # ..then project conf to initialize any missing defaults
    # shellcheck source=kubler.conf
    [[ "${_ns_conf}" != "${_global_conf}" ]] && source "${_global_conf}"

    [[ "${_NAMESPACE_TYPE}" == 'single' ]] && source_build_engine

    readonly _NAMESPACE_DIR="${real_ns_dir}"
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
        grep -q "^${header}" "${doc_file}" && sed -i '1,4d' "${doc_file}"
    else
        echo -e "" > "${doc_file}"
    fi
    # add header
    echo -e "${header}\\n\\nBuilt: $(date)\\nImage Size: ${__get_image_size}\\n\\n$(cat "${doc_file}")" > "${doc_file}"
}
