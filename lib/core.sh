#!/usr/bin/env bash
#
# Copyright (c) 2014-2019, Erik Dannenberg <erik.dannenberg@xtrade-gmbh.de>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
# following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following
#    disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
#    following disclaimer in the documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

KUBLER_DISABLE_KUBLER_NS="${KUBLER_DISABLE_KUBLER_NS:-false}"

KUBLER_DATA_DIR="${KUBLER_DATA_DIR:-${HOME}/.kubler}"
KUBLER_DOWNLOAD_DIR="${KUBLER_DOWNLOAD_DIR:-${KUBLER_DATA_DIR}/downloads}"
KUBLER_DISTFILES_DIR="${KUBLER_DISTFILES_DIR:-${KUBLER_DATA_DIR}/distfiles}"
KUBLER_PACKAGES_DIR="${KUBLER_PACKAGES_DIR:-${KUBLER_DATA_DIR}/packages}"
KUBLER_DEPGRAPH_IMAGE="${KUBLER_DEPGRAPH_IMAGE:-kubler/graph-easy}"
KUBLER_POSTBUILD_IMAGE_PRUNE="${KUBLER_POSTBUILD_IMAGE_PRUNE:-true}"
KUBLER_POSTBUILD_VOLUME_PRUNE="${KUBLER_POSTBUILD_VOLUME_PRUNE:-true}"

AUTHOR="${AUTHOR:-Erik Dannenberg <erik.dannenberg@xtrade-gmbh.de>}"

readonly _KUBLER_NAMESPACE_DIR="${KUBLER_DATA_DIR}"/namespaces
readonly _KUBLER_LOG_DIR="${KUBLER_DATA_DIR}"/log
readonly _KUBLER_NS_GIT_URL='https://github.com/edannenberg/kubler-images.git'
readonly _IMAGE_PATH="images/"
readonly _BUILDER_PATH="builder/"
readonly _BUILD_TEST_FAILED_FILE=".kubler-build-test.error"
readonly _HEALTHCHECK_FAILED_FILE=".kubler-healthcheck.error"
readonly _COMPOSE_TEST_FAILED_FILE=".kubler-composetest.error"
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

_kubler_trap_functions=()
_kubler_internal_abort=

# used as primitive caching mechanism
_last_sourced_engine=
_last_sourced_image=
_last_sourced_push_conf=

# shellcheck source=lib/util.sh
source "${_LIB_DIR}"/util.sh || die

# Helper function that provides parsable data for Kubler's bash completion script.
function bc_helper() {
    [[ -z "${KUBLER_BC_HELP}" ]] && return
    local available_cmds cmd_dirs cmd
    available_cmds=()
    cmd_dirs=( "${_KUBLER_DIR}"/cmd/*.sh )
    [[ -d "${KUBLER_DATA_DIR}"/cmd ]] && dir_has_scripts "${KUBLER_DATA_DIR}"/cmd \
        && cmd_dirs+=( "${KUBLER_DATA_DIR}"/cmd/*.sh )
    for cmd in "${cmd_dirs[@]}"; do
        available_cmds+=( "$(basename -- "${cmd%.*}")" )
    done

    echo "${KUBLER_DATA_DIR}"
    echo "${_NAMESPACE_DIR}"
    echo "${_NAMESPACE_TYPE}"
    echo "${_NAMESPACE_DEFAULT}"
    echo "${available_cmds[*]}"
    exit 0
}

# The main trap handler for any command script, do not call this function manually! Instead add your own trap handlers
# like so:
#
# add_trap_fn myhandler_fn
# do stuff..
# rm_trap_fn myhandler_fn
#
# If your handler requires arguments use a global var named _myhandler_fn_args. The rm_trap_fn function will unset this
# var should it be set.
#
# Note that your trap handler should not exit the script, it might prevent other handlers from executing.
function kubler_abort_handler() {
    local trap_fn
    [[ "${_kubler_internal_abort}" != 'true' ]] && { echo -e ""; msg_error "caught interrupt, aborting.."; }
    for trap_fn in "${_kubler_trap_functions[@]}"; do
        [[ -z "${trap_fn}" ]] && continue
        "${trap_fn}"
    done
    die
}

# Arguments:
# 1: fn_name - function name that should be called on abort
function add_trap_fn() {
    local fn_name
    fn_name="$1";
    _kubler_trap_functions+=( "${fn_name}" )
}

# Arguments:
# 1: fn_name - function name that should be removed from global trap handler
function rm_trap_fn() {
    local fn_name trap_fn tmp_array
    fn_name="$1";
    tmp_array=()
    for trap_fn in "${_kubler_trap_functions[@]}"; do
        [[ "${trap_fn}" != "${fn_name}" ]] && tmp_array+=("${trap_fn}")
    done
    unset _"${fn_name}"_args
    _kubler_trap_functions=( "${tmp_array[@]}" )
}

# Sets __get_include_path to absolute path for given relative file_sub_path. The function will check both
# KUBLER_DATA_DIR and _KUBLER_DIR, in that order. First hit wins, returns exit signal 3 if the path doesn't exist.
#
# Arguments:
# 1: file_sub_path as string
function get_include_path() {
    __get_include_path=
    local file_sub_path base_path
    file_sub_path="$1"
    if [[ -f "${KUBLER_DATA_DIR}/${file_sub_path}" ]]; then
        base_path="${KUBLER_DATA_DIR}"
    elif [[ -f "${_KUBLER_DIR}/${file_sub_path}" ]]; then
        base_path="${_KUBLER_DIR}"
    else
        return 3
    fi
    __get_include_path="${base_path}/${file_sub_path}"
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

# Check if passed target_path is a valid KUBLER_DATA_DIR, if not create and/or initialize the dir.
#
# Arguments:
# 1: target_path
function validate_or_init_data_dir() {
    local target_path conf_sed_args kubler_ns_path
    target_path="$1"
    if [[ ! -d "${target_path}" ]]; then
        mkdir -p "${target_path}" || die
    fi
    if dir_is_empty "${target_path}"; then
        cp "${_KUBLER_DIR}"/template/docker/namespace/kubler.conf.multi "${target_path}/${_KUBLER_CONF}" || die
        # shellcheck disable=SC2034
        conf_sed_args=(
            '-e' "s|\${_tmpl_author}|Your Name|g"
            '-e' "s|\${_tmpl_author_email}|your@mail.org|g"
            '-e' "s|\${_tmpl_image_tag}|${_TODAY}|g"
            '-e' "s|\${_tmpl_engine}|${BUILD_ENGINE}|g"
        )
        replace_in_file "${target_path}/${_KUBLER_CONF}" conf_sed_args[@] || die
        cp "${_KUBLER_DIR}"/template/gitignore-data-dir "${target_path}"/.gitignore || die
    else
        [[ ! -f  "${target_path}/${_KUBLER_CONF}" ]] \
            && die "Configured KUBLER_DATA_DIR ${target_path} is not empty but has no ${_KUBLER_CONF} file, aborting."
    fi
    # clone kubler-images repo if non-existing
    [[ ! -d  "${target_path}"/namespaces ]] && mkdir "${target_path}"/namespaces
    kubler_ns_path="${target_path}"/namespaces/kubler
    if [[ -z "${KUBLER_BC_HELP}" && "${KUBLER_DISABLE_KUBLER_NS}" != 'true' ]] && ! is_git_dir "${kubler_ns_path}"; then
        add_status_value 'kubler-images'
        clone_or_update_git_repo "${_KUBLER_NS_GIT_URL}" "${target_path}"/namespaces 'kubler'
        add_status_value
    fi
}

# Source build engine script depending on passed engine_id or BUILD_ENGINE value
#
# Arguments:
# 1: engine_id - optional, default: value of BUILD_ENGINE
# shellcheck disable=SC2120
function source_build_engine() {
    local engine_id
    engine_id="${1:-${BUILD_ENGINE}}"
    if [[ "${_last_sourced_engine}" != "${engine_id}" ]]; then
        get_include_path "engine/${engine_id}.sh" || die "Couldn't find build engine: ${engine_id}"
        # shellcheck source=engine/docker.sh
        source "${__get_include_path}"
        _last_sourced_engine="${engine_id}"
    fi
}

# Return namespace dir of given absolute image_path.
#
# Arguments:
# 1: image_path
function get_ns_dir_by_image_path() {
    __get_ns_dir_by_image_path=
    local image_path
    image_path="$1"
    if [[ "${image_path}" == /*/"${_IMAGE_PATH}"* ]]; then
        image_path="${image_path%%/${_IMAGE_PATH}*}"
    elif [[ "${image_path}" == /*/"${_BUILDER_PATH}"* ]]; then
        image_path="${image_path%%/${_BUILDER_PATH}*}"
    else
        return 3
    fi
    __get_ns_dir_by_image_path="${image_path}"
}

# Read namespace kubler.conf for given absolute ns_dir
#
# Arguments:
# 1: ns_dir
function source_namespace_conf() {
    local ns_dir conf_file final_tag
    ns_dir="$1"

    # reset to system config at /etc/kubler.conf or _KUBLER_DIR/kubler.conf first..
    # shellcheck source=kubler.conf disable=SC1090
    source "${_kubler_system_conf}"

    # ..then read user config at KUBLER_DATA_DIR/kubler.conf..
    # shellcheck source=kubler.conf
    [[ -f "${_kubler_user_conf}" ]] && source "${_kubler_user_conf}"

    # ..then current multi namespace conf..
    # shellcheck source=kubler.conf
    [[ "${_kubler_ns_conf}" != "${_kubler_user_conf}" && -f "${_kubler_ns_conf}" ]] && source "${_kubler_ns_conf}"
    [[ -n "${IMAGE_TAG}" ]] && final_tag="${IMAGE_TAG}"

    conf_file="${ns_dir}"/"${_KUBLER_CONF}"

    # ..finally read current namespace conf
    # shellcheck source=kubler.conf
    file_exists_or_die "${conf_file}" "Couldn't read namespace conf ${conf_file}" && source "${conf_file}"

    [[ -z "${IMAGE_TAG}" ]] && die 'No IMAGE_TAG defined in any kubler.conf file.'
    # silently ignore IMAGE_TAG if it was already defined in a parent kubler.conf
    [[ -n "${IMAGE_TAG}" && -n "${final_tag}" && "${IMAGE_TAG}" != "${final_tag}" ]] \
        && IMAGE_TAG="${final_tag}"

    _current_namespace="$(basename -- "${ns_dir}")"
    # just for BC and to make build.conf/templates a bit more consistent to use. not used otherwise internally
    NAMESPACE="${_current_namespace}"

    source_build_engine "${BUILD_ENGINE}"
}

# Read image build.conf for given image_path
#
# Arguments:
# 1: image_path - can be either relative to a namespace dir or an absolute path
function source_image_conf() {
    local image_path build_conf
    image_path="$1"

    # exit if we just sourced the given build.conf
    [[ "${_last_sourced_image}" == "${image_path}" ]] && return 0
    unset BOB_CHOST BOB_CFLAGS BOB_CXXFLAGS BOB_BUILDER_CHOST BOB_BUILDER_CFLAGS BOB_BUILDER_CXXFLAGS ARCH ARCH_URL IMAGE_TAG
    unset POST_BUILD_HC POST_BUILD_HC_MAX_DURATION POST_BUILD_HC_INTERVAL POST_BUILD_HC_START_PERIOD POST_BUILD_HC_RETRY
    unset POST_BUILD_DC_DEPENDENCIES

    if [[ "${image_path}" != '/'* ]]; then
        get_ns_include_path "${image_path}"
        image_path="${__get_ns_include_path}"
    fi

    get_ns_dir_by_image_path "${image_path}"
    source_namespace_conf "${__get_ns_dir_by_image_path}"

    unset STAGE3_BASE STAGE3_DATE IMAGE_PARENT BUILDER BUILDER_CAPS_SYS_PTRACE BUILDER_DOCKER_ARGS
    [[ "${_use_parent_builder_mounts}" != 'true' ]] && unset BUILDER_MOUNTS

    build_conf="${image_path}/"build.conf
    file_exists_or_die "${build_conf}" "Couldn't read image config ${build_conf}"
    # shellcheck source=template/docker/image/build.conf
    source "${build_conf}"

    # assume scratch if IMAGE_PARENT is not set
    [[ -z "${IMAGE_PARENT}" ]] && IMAGE_PARENT='scratch'

    # stage3 overrides BUILDER, unset if defined
    [[ -n "${STAGE3_BASE}" ]] && unset BUILDER
    _last_sourced_image="${image_path}"
}

# Read namespace push.conf for given image_id
#
# Arguments:
# 1: namespace_path - absolute
function source_push_conf() {
    local namespace_path
    namespace_path="$1"
    # exit if we just sourced for this NS
    [[ "${_last_sourced_push_conf}" == "${namespace_path}" ]] && return 0
    # shellcheck disable=SC1090
    [[ -f "${namespace_path}/push.conf" ]] && source "${namespace_path}/push.conf"
    _last_sourced_push_conf="${namespace_path}"
}

# Check image dependencies and return base build container id for given image_id. Recursive.
#
# Arguments:
#
# 1: image_id
function get_image_builder_id() {
    __get_image_builder_id=
    local image_id
    image_id="$1"
    [[ "${image_id}" == 'scratch' ]] && __get_image_builder_id="${DEFAULT_BUILDER}" && return 0
    if [[ -n "${image_id}" && "${image_id}" != 'scratch' ]]; then
        expand_image_id "${image_id}" "${_IMAGE_PATH}"
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

# Compare given local and remote stage3 date, returns 0 if remote is newer or 1 if not
#
# Arguments:
# 1: stage3_date_local
# 2: stage3_date_remote
function is_newer_stage3_date {
    local stage3_date_local stage3_date_remote
    # parsing ISO8601 with the date command is a bit tricky due to differences on macOS
    # as a workaround we just remove any possible non-numeric chars and compare as integers
    stage3_date_local="${1//[!0-9]/}"
    stage3_date_remote="${2//[!0-9]/}"
    if [[ "${stage3_date_local}" -lt "${stage3_date_remote}" ]]; then
        return 0
    else
        return 1
    fi
}

# Return a Bash regex that should match for any given stage3_base
# Arguments:
# 1: stage3_base (i.e. stage3-amd64-hardened+nomultilib)
function get_stage3_archive_regex() {
    __get_stage3_archive_regex=
    local stage3_base
    stage3_base="$1"
    __get_stage3_archive_regex="${stage3_base//+/\\+}-([0-9]{8})(T[0-9]{6}Z)?\\.tar\\.(bz2|xz)"
}

# Fetch latest stage3 archive name/type, returns exit signal 3 if no archive could be found
function fetch_stage3_archive_name() {
    __fetch_stage3_archive_name=
    ARCH="${ARCH:-amd64}"
    ARCH_URL="${ARCH_URL:-${MIRROR}releases/${ARCH}/autobuilds/current-${STAGE3_BASE}/}"
    local remote_files remote_line remote_date remote_file_type
    readarray -t remote_files <<< "$(wget -qO- "${ARCH_URL}")"
    remote_date=0
    get_stage3_archive_regex "${STAGE3_BASE}"
    for remote_line in "${remote_files[@]}"; do
        if [[ "${remote_line}" =~ ${__get_stage3_archive_regex}\< ]]; then
            is_newer_stage3_date "${remote_date}" "${BASH_REMATCH[1]}${BASH_REMATCH[2]}" \
                && { remote_date="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"; remote_file_type="${BASH_REMATCH[3]}"; }
        fi
    done
    [[ "${remote_date//[!0-9]/}" -eq 0 ]] && return 3
    __fetch_stage3_archive_name="${STAGE3_BASE}-${remote_date}.tar.${remote_file_type}"
}

# Download and verify stage3 tar ball
#
# Arguments:
# 1: stage3_file
function download_stage3() {
    [[ -d "${KUBLER_DOWNLOAD_DIR}" ]] || mkdir -p "${KUBLER_DOWNLOAD_DIR}"
    local is_autobuild stage3_file stage3_contents stage3_digests sha512_hashes sha512_check sha512_failed \
          wget_exit wget_args
    is_autobuild=false
    stage3_file="$1"
    stage3_contents="${stage3_file}.CONTENTS"
    stage3_digests="${stage3_file}.DIGESTS"
    if [[ "${ARCH_URL}" == *autobuilds*  ]]; then
        stage3_digests="${stage3_file}.DIGESTS.asc"
        is_autobuild=true
    fi

    wget_args=()
    [[ "${_arg_verbose}" == 'off' ]] && wget_args+=( '-q' '-nv' )

    for file in "${stage3_file}" "${stage3_contents}" "${stage3_digests}"; do
        [ -f "${KUBLER_DOWNLOAD_DIR}/${file}" ] && continue

        _handle_download_error_args="${KUBLER_DOWNLOAD_DIR}/${file}"
        add_trap_fn 'handle_download_error'
        wget "${wget_args[@]}" -O "${KUBLER_DOWNLOAD_DIR}/${file}" "${ARCH_URL}${file}"
        wget_exit=$?
        [[ "${wget_exit}" -eq 8 ]] && msg_error "HTTP 404 for ${file}, try running the update command to resolve this."
        [[ "${wget_exit}" -ne 0 ]] && exit $?
        rm_trap_fn 'handle_download_error'
    done
    # shellcheck disable=SC2154
    if [ "${_arg_skip_gpg_check}" = false ] && [ "${is_autobuild}" = true ]; then
        gpg --verify "${KUBLER_DOWNLOAD_DIR}/${stage3_digests}" || die "Insecure digests"
    elif [ "${is_autobuild}" = false ]; then
        msg "GPG verification not supported for experimental stage3 tar balls, only checking SHA512"
    fi
    # some experimental stage3 builds don't update the file names in the digest file, replace so sha512 check won't fail
    grep -q "${STAGE3_BASE}-2008\.0\.tar\.bz2" "${KUBLER_DOWNLOAD_DIR}/${stage3_digests}" \
        && sed -i "s/${STAGE3_BASE}-2008\.0\.tar\.bz2/${stage3_file}/g" "${KUBLER_DOWNLOAD_DIR}/${stage3_digests}"
    sha512_hashes="$(grep -A1 SHA512 "${KUBLER_DOWNLOAD_DIR}/${stage3_digests}" | grep -v '^--')"
    sha512_check="$(cd "${KUBLER_DOWNLOAD_DIR}/" && (echo "${sha512_hashes}" | $(sha_sum) -c))"
    sha512_failed="$(echo "${sha512_check}" | grep FAILED)"
    if [ -n "${sha512_failed}" ]; then
        die "${sha512_failed}"
    fi
}

# Download and verify portage snapshot, when using latest it will download at most once per day
#
# Arguments:
# 1: portage_file
function download_portage_snapshot() {
    PORTAGE_DATE="${PORTAGE_DATE:-latest}"
    local portage_file portage_sig portage_md5 file dl_name wget_args portage_url parsed_mirrors
    portage_file="$1"
    portage_sig="${portage_file}.gpgsig"
    portage_md5="${portage_file}.md5sum"
    IFS=', ' read -r -a parsed_mirrors <<< "${PORTAGE_URL:-${MIRROR}}"
    portage_url="${parsed_mirrors[0]}"
    [[ "${portage_url}" != *'/$' ]] && portage_url+='/'
    portage_url+='snapshots'
    [[ -d "${KUBLER_DOWNLOAD_DIR}" ]] || mkdir -p "${KUBLER_DOWNLOAD_DIR}"

    for file in "${portage_file}" "${portage_sig}" "${portage_md5}"; do
        dl_name="${file}"
        if [[ "${PORTAGE_DATE}" == 'latest' ]]; then
            dl_name="${portage_file//latest/${_TODAY}}"
        fi
        if [[ ! -f "${KUBLER_DOWNLOAD_DIR}/${dl_name}" ]]; then
            wget_args=()
            [[ "${_arg_verbose}" == 'off' ]] && wget_args+=( '-q' '-nv' )
            _handle_download_error_args="${KUBLER_DOWNLOAD_DIR}/${dl_name}"
            add_trap_fn 'handle_download_error'
            wget "${wget_args[@]}" -O "${KUBLER_DOWNLOAD_DIR}/${dl_name}" "${portage_url}/${file}" || exit $?
            rm_trap_fn 'handle_download_error'
        fi
    done

    # use current date instead of latest from here on
    if [[ "${PORTAGE_DATE}" == 'latest' ]]; then
        portage_sig="${portage_file//latest/${_TODAY}}.gpgsig"
        portage_md5="${portage_file//latest/${_TODAY}}.md5sum"
        portage_file="${portage_file//latest/${_TODAY}}"
        PORTAGE_DATE="${_TODAY}"
    fi

    if [[ "${_arg_skip_gpg_check}" != 'on' ]] && [[ -f "${KUBLER_DOWNLOAD_DIR}/${portage_sig}" ]]; then
        gpg --verify "${KUBLER_DOWNLOAD_DIR}/${portage_sig}" "${KUBLER_DOWNLOAD_DIR}/${portage_file}" || die "Insecure digests."
    fi
}

function handle_download_error() {
    local file msg
    file="${_handle_download_error_args}"
    msg="${2:-Aborted download of ${file}}"
    [[ -f "${file}" ]] && rm "${file}"
    die "${msg}"
}

# Returns the absolute path for given relative_image_path.
#
# Arguments:
# 1: relative_image_path
function get_ns_include_path() {
    __get_ns_include_path=
    local relative_image_path abs_path
    relative_image_path="$1"
    # return input if it's actually an absolute path
    [[ "${relative_image_path}" == "/"* ]] && __get_ns_include_path="${relative_image_path}" && return 0

    if [[ "${_NAMESPACE_TYPE}" == 'single' ]] && \
        [[ "${relative_image_path}" == "${_NAMESPACE_DEFAULT}"/* || "${relative_image_path}" == "${_NAMESPACE_DEFAULT}" ]]
        then
        relative_image_path="${relative_image_path//${_NAMESPACE_DEFAULT}//}"
        abs_path="${_NAMESPACE_DIR}/${relative_image_path}"
    else
        if [[ -d "${_NAMESPACE_DIR}/${relative_image_path}" ]]; then
            abs_path="${_NAMESPACE_DIR}/${relative_image_path}"
        elif [[ -d "${_KUBLER_NAMESPACE_DIR}/${relative_image_path}" || "${relative_image_path}" == *"-core" ]]; then
            abs_path="${_KUBLER_NAMESPACE_DIR}/${relative_image_path}"
        else
            return 3
        fi
    fi
    __get_ns_include_path="${abs_path}"
}

# Sets __expand_image_id to absolute image path for given image_id and image_type
#
# 1: image_id (i.e. kubler/busybox)
# 2: image_type ($_IMAGE_PATH or $_BUILDER_PATH), optional, default: $_IMAGE_PATH
function expand_image_id() {
    __expand_image_id=
    local image_id image_type image_ns expand_id
    image_id="$1"
    image_type="${2:-${_IMAGE_PATH}}"
    image_ns="${image_id%%/*}"
    if [[ "${_NAMESPACE_TYPE}" == 'single' && "${image_ns}" == "${_NAMESPACE_DEFAULT}" ]]; then
        if [[ "${image_id}" == *"/"* ]]; then
            image_id="${image_id##*/}"
        fi
        expand_id="${image_type}${image_id}"
    else
        expand_id="${image_id/\//\/${image_type}}"
    fi
    get_ns_include_path "${expand_id}" || return $?
    __expand_image_id="${__get_ns_include_path}"
}

# Expand requested namespace and image mix of passed target_ids to fully qualified image ids
# i.e. kubler/busybox mynamespace othernamespace/myimage
#
# Arguments:
# n: target_id (i.e. namespace or namespace/image)
function expand_requested_target_ids() {
    __expand_requested_target_ids=
    local target_ids expanded target image is_processed
    target_ids=( "$@" )
    expanded=()
    for target in "${target_ids[@]}"; do
        is_processed=
        # strip trailing slash possibly added by bash completion
        [[ "${target}" == */ ]] && target="${target: : -1}"
        # is target a fully qualified image id?
        if [[ "${target}" == *"/"* ]]; then
            expand_image_id "${target}" "${_IMAGE_PATH}" || die "Couldn't find a image dir for ${target}"
            expanded+=( "${target}" )
        else
            # is target an image id with omitted namespace?
            if [[ -n "${_NAMESPACE_DEFAULT}" ]]; then
                expand_image_id "${_NAMESPACE_DEFAULT}/${target}" "${_IMAGE_PATH}" \
                    && expanded+=( "${_NAMESPACE_DEFAULT}/${target}" ) && is_processed=1
            fi
            # ..if not it should be a namespace, expand to image ids
            if [[ -z "${is_processed}" ]]; then
                get_ns_include_path "${target}" \
                    || die "Couldn't find namespace dir ${target} in ${_NAMESPACE_DIR}"
                pushd "${__get_ns_include_path}" > /dev/null || die "pushd error on directory ${_NAMESPACE_DIR}"
                if ! dir_has_subdirs "${__get_ns_include_path}/${_IMAGE_PATH}"; then
                    msg_error "Namespace ${target} has no images yet. To create an image run:"
                    msg_info_sub
                    msg_info_sub "$ kubler new image ${target}/<imagename>"
                    msg_info_sub
                    popd > /dev/null || die "popd failed in function expand_requested_target_ids"
                    die
                fi
                for image in "${_IMAGE_PATH}"*; do
                   expanded+=( "${target}/${image/${_IMAGE_PATH}/}" )
                done
                popd > /dev/null || die "popd failed in function expand_requested_target_ids"
            fi
        fi
    done
    # shellcheck disable=SC2034
    __expand_requested_target_ids=( "${expanded[@]}" )
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
# local  - working_dir is inside KUBLER_DATA_DIR
# multi  - working_dir has multiple namespaces
# single - working_dir has only a single namespace
# none   - only allowed when creating a new namespace
#
# 1: working_dir
function detect_namespace() {
    local working_dir real_ns_dir parent_dir parent_conf
    working_dir="$1"
    # deny executing kubler inside it's main script folder
    if [[ "${working_dir}" == "${_KUBLER_DIR}" || "${working_dir}" == "${_KUBLER_DIR}"/* ]]; then
        if [[ "${_is_terminal}" == 'true' ]]; then
            die "Kubler execution forbidden in --working-dir ${working_dir}"
        else
            # silent exit if not in a terminal to handle possible bash-completion invocation, etc
            exit 1
        fi
    fi
    _kubler_system_conf=/etc/"${_KUBLER_CONF}"
    [[ ! -f /etc/"${_kubler_system_conf}" ]] && _kubler_system_conf="${_KUBLER_DIR}/${_KUBLER_CONF}"
    _kubler_user_conf="${KUBLER_DATA_DIR}/${_KUBLER_CONF}"
    _kubler_ns_conf="${_kubler_user_conf}"

    get_absolute_path "${working_dir}"
    # shellcheck disable=SC2154
    if [[ ! -d "${__get_absolute_path}" ]]; then
        # silent exit if called by bash completion
        [[ "${KUBLER_BC_HELP}" != 'true' ]] && msg_error "fatal: Couldn't find namespace location: ${working_dir}"
        die
    fi

    # find next namespace dir, respect symlink paths, as in don't resolve
    find_in_parents "${working_dir}" "${_KUBLER_CONF}"
    real_ns_dir="${__find_in_parents}"

    # working dir inside kubler data dir?
    if [[ "${working_dir}" == "${KUBLER_DATA_DIR}" || "${working_dir}" == "${KUBLER_DATA_DIR}"/* ]]; then
        # ..and inside a namespace dir?
        if [[ -d "${real_ns_dir}/${_IMAGE_PATH}" ]]; then
            readonly _NAMESPACE_DEFAULT="$(basename -- "${real_ns_dir}")"
        fi
        real_ns_dir="${_KUBLER_NAMESPACE_DIR}"
        readonly _NAMESPACE_TYPE='local'
    else
        # allow missing namespace dir for new command, the user might want to create a new namespace
        if [[ -z "${real_ns_dir}" ]]; then
            # shellcheck disable=SC2154
            if [[ "${_arg_command}" == 'new' || "${_arg_help}" == 'on' ]]; then
                real_ns_dir="${working_dir}"
                readonly _NAMESPACE_TYPE='none'
            else
                die "Current --working-dir is not a Kubler namespace: ${working_dir}"
            fi
        fi
        _kubler_ns_conf="${real_ns_dir}/${_KUBLER_CONF}"

        parent_dir="$(dirname -- "${real_ns_dir}")"
        parent_conf="${parent_dir}/${_KUBLER_CONF}"
        # is it a single namespace dir?
        if [[ -d "${real_ns_dir}/${_IMAGE_PATH}" ]]; then
            readonly _NAMESPACE_DEFAULT="$(basename -- "${real_ns_dir}")"
            if [[ ! -f "${parent_conf}" ]]; then
                readonly _NAMESPACE_TYPE='single'
                _current_namespace="${_NAMESPACE_DEFAULT}"
                # just for BC and to make build.conf/templates a bit more consistent to use. unused otherwise internally
                export NAMESPACE="${_current_namespace}"
            else
                real_ns_dir="${parent_dir}"
                _kubler_ns_conf="${parent_conf}"
            fi
        fi

    fi
    # else assume multi mode
    [[ -z "${_NAMESPACE_TYPE}" ]] && readonly _NAMESPACE_TYPE='multi'

    # Read system config at /etc/kubler.conf or _KUBLER_DIR/kubler.conf first..
    # shellcheck source=kubler.conf
    file_exists_or_die "${_kubler_system_conf}" && source "${_kubler_system_conf}"

    # ..then possible user config at KUBLER_DATA_DIR/kubler.conf
    # shellcheck source=kubler.conf
    [[ -f "${_kubler_user_conf}" ]] && source "${_kubler_user_conf}"

    # ..then current namespace config
    # shellcheck source=kubler.conf
    [[  "${_NAMESPACE_TYPE}" != 'local' && -f "${_kubler_ns_conf}" ]] && source "${_kubler_ns_conf}"

    # just for well formatted output
    get_absolute_path "${real_ns_dir}"
    readonly _NAMESPACE_DIR="${__get_absolute_path}"
}

# Generate PACKAGES.md header
#
# Arguments:
# 1: image
# 2: image_type ($_IMAGE_PATH or $_BUILDER_PATH)
function add_documentation_header() {
    local image image_type image_path doc_file header
    image="$1"
    image_type="$2"
    expand_image_id "${image}" "${image_type}" || die "Couldn't find image ${image}"
    image_path="${__expand_image_id}"
    doc_file="${image_path}/PACKAGES.md"
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
