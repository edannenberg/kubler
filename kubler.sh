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

# variable type conventions:
#
# environment     : SOME_VAR
# constant        : _SOME_VAR
# local           : some_var
# global          : _some_var
# function return : __function_name

readonly _KUBLER_VERSION=0.9.10
readonly _KUBLER_BASH_MIN=4.2
readonly _KUBLER_CONF=kubler.conf

# shellcheck disable=SC1004
_help_header=' __        ___.   .__
|  | ____ _\_ |__ |  |   ___________
|  |/ /  |  \ __ \|  | _/ __ \_  __ \
|    <|  |  / \_\ \  |_\  ___/|  | \/
|__|_ \____/|___  /____/\___  >__|
     \/         \/          \/'

function show_help() {
    local help_commands header_current_cmd
    help_commands="Commands:

build     - Build image(s) or namespace(s)
clean     - Remove build artifacts and/or delete built images
dep-graph - Visualize image dependencies
new       - Create a new namespace, image or builder
push      - Push image(s) or namespace(s) to a registry
update    - Check for new stage3 releases and kubler namespace updates

${_KUBLER_BIN} <command> --help for more information on specific commands\\n"
    header_current_cmd="${_KUBLER_VERSION}"
    # shellcheck disable=SC2154
    [[ "${_is_valid_cmd}" == 'true' ]] && header_current_cmd=" ${_arg_command}"
    echo -e "${_help_header}${header_current_cmd}\\n"
    [[ -n "${_help_command_description}" ]] && echo -e "${_help_command_description}\\n"
    print_help
    # only show command listing if no/invalid command was provided
    [[ -z "${_arg_command}" || -z "${_is_valid_cmd}" ]] && echo -e "\\n${help_commands}"
}

# Get the absolute path for given file or directory, resolve symlinks.
# Adapted from: http://stackoverflow.com/a/697552/5731095
#
# Arguments:
# 1: path
function get_absolute_path() {
    __get_absolute_path=
    local path_in path_out current_dir current_link
    path_in="$1"
    path_out="$(cd -P -- "$(dirname -- "${path_in}")" && pwd -P)" \
        || die "Couldn't determine the script's running directory, aborting" 2
    path_out="${path_out}/$(basename -- "${path_in}")" \
        || die "Couldn't determine the script's base name, aborting" 2
    # resolve symlinks
    while [[ -h "${path_out}" ]]; do
        current_dir=$(dirname -- "${path_out}")
        current_link=$(readlink "${path_out}")
        path_out="$(cd "${current_dir}" && cd "$(dirname -- "${current_link}")" && pwd)/$(basename -- "${current_link}")"
    done
    # handle ./ or ../
    regex='^[.]{1,2}\/?$'
    [[ "${path_in}" =~ ${regex} ]] && path_out="$(dirname "${path_out}")"
    # and once more if ../
    regex='^[.]{2}\/?$'
    [[ "${path_in}" =~ ${regex} ]] && path_out="$(dirname "${path_out}")"
    __get_absolute_path="${path_out}"
}

# https://stackoverflow.com/a/44660519/5731095
# Compares two tuple-based, dot-delimited version numbers a and b (possibly
# with arbitrary string suffixes). Returns:
# 1 if a<b
# 2 if equal
# 3 if a>b
# Everything after the first character not in [0-9.] is compared
# lexicographically using ASCII ordering if the tuple-based versions are equal.
#
# Arguments:
# 1: version_one
# 2: version_two
function compare_versions() {
    if [[ "$1" == "$2" ]]; then
        return 2
    fi
    local IFS=.
    # shellcheck disable=SC2206
    local i a=(${1%%[^0-9.]*}) b=(${2%%[^0-9.]*})
    local arem=${1#"${1%%[^0-9.]*}"} brem=${2#"${2%%[^0-9.]*}"}
    for ((i=0; i<${#a[@]} || i<${#b[@]}; i++)); do
        if ((10#${a[i]:-0} < 10#${b[i]:-0})); then
            return 1
        elif ((10#${a[i]:-0} > 10#${b[i]:-0})); then
            return 3
        fi
    done
    if [ "$arem" '<' "$brem" ]; then
        return 1
    elif [ "$arem" '>' "$brem" ]; then
        return 3
    fi
    return 2
}

# Read config from /etc/kubler.conf or $_KUBLER_DIR/kubler.conf as fallback, then $KUBLER_DATA_DIR config if it exists
#
# Arguments:
# 1: kubler_dir
function source_base_conf() {
    local kubler_dir conf_path
    kubler_dir="$1"
    conf_path=/etc/"${_KUBLER_CONF}"
    if [[ ! -f "${conf_path}" ]]; then
        conf_path="${kubler_dir}/${_KUBLER_CONF}"
        [[ ! -f "${conf_path}" ]] && die "Couldn't find config at /etc/${_KUBLER_CONF} or ${conf_path}"
    fi
    # shellcheck source=kubler.conf
    source "${conf_path}"
    conf_path="${KUBLER_DATA_DIR}/${_KUBLER_CONF}"
    # shellcheck source=template/docker/namespace/kubler.conf.multi
    [[ -n "${KUBLER_DATA_DIR}" && -f "${conf_path}" ]] && source "${conf_path}"
}

# Arguments:
# 1: exit_message as string
# 2: exit_code as int, optional, default: 1
function die() {
    local exit_message exit_code
    exit_message="$1"
    exit_code="${2:-1}"
    [[ "$_PRINT_HELP" = 'yes' ]] && show_help >&2
    if [[ -n "${exit_message}" ]]; then
        if declare -F msg_error &>/dev/null; then
            msg_error "fatal: ${exit_message}" >&2
        else
            echo -e 'fatal:' "${exit_message}" >&2
        fi
    fi
    [[ "${KUBLER_BELL_ON_ERROR}" == 'true' ]] && tput bel
    _kubler_internal_abort='true'
    exit "${exit_code}"
}

function main() {
    compare_versions "${BASH_VERSION}" "${_KUBLER_BASH_MIN}"
    [[ $? -eq 1 ]] && die "Kubler needs Bash version ${_KUBLER_BASH_MIN} or greater, installed is ${BASH_VERSION}."

    get_absolute_path "$0"
    [[ -z "${__get_absolute_path}" ]] && die "Couldn't determine the script's real directory, aborting" 2
    _KUBLER_DIR="$(dirname -- "${__get_absolute_path}")"
    readonly _KUBLER_DIR

    local kubler_bin lib_dir core parser working_dir cmd_script
    kubler_bin="$(basename "$0")"
    command -v "${kubler_bin}" > /dev/null
    # use full path name if not in PATH
    [[ $? -eq 1 ]] && kubler_bin="$0"
    readonly _KUBLER_BIN="${kubler_bin}"

    lib_dir="${_KUBLER_DIR}"/lib
    [[ -d "${lib_dir}" ]] || die "Couldn't find ${lib_dir}" 2
    readonly _LIB_DIR="${lib_dir}"

    source_base_conf "${_KUBLER_DIR}"

    core="${_LIB_DIR}"/core.sh
    [[ -f "${core}" ]] || die "Couldn't read ${core}" 2
    # shellcheck source=lib/core.sh
    source "${core}"

    # parse main args
    get_include_path "cmd/argbash/opt-main.sh"
    parser="${__get_include_path}"
    # shellcheck source=cmd/argbash/opt-main.sh
    file_exists_or_die "${parser}" && source "${parser}"

    if [[ "${_arg_debug}" == 'on' ]]; then
        readonly BOB_IS_DEBUG='true'
        set -x
    else
        # shellcheck disable=SC2034
        readonly BOB_IS_DEBUG='false'
    fi

    # KUBLER_WORKING_DIR overrides --working-dir, else use current working directory
    get_absolute_path "${KUBLER_WORKING_DIR:-${_arg_working_dir}}"
    working_dir="${__get_absolute_path}"
    [[ -z "${working_dir}" ]] && working_dir="${PWD}"
    detect_namespace "${working_dir}"

    validate_or_init_data_dir "${KUBLER_DATA_DIR}"

    # handle --help for main script
    [[ -z "${_arg_command}" && "${_arg_help}" == 'on' ]] && { bc_helper; show_help; exit 0; }

    if [[ -n "${_arg_working_dir}" ]]; then
        # shellcheck disable=SC2034
        readonly _KUBLER_BIN_HINT=" --working-dir=${working_dir}"
    fi

    # valid command?
    get_include_path "cmd/${_arg_command}.sh" || { show_help; die "Unknown command, ${_arg_command}" 5; }
    cmd_script="${__get_include_path}"
    _is_valid_cmd='true'

    # parse command args if a matching parser exists
    get_include_path "cmd/argbash/${_arg_command}.sh"
    parser="${__get_include_path}"
    # shellcheck source=cmd/argbash/build.sh
    [[ -f "${parser}" ]] && source "${parser}" "${_arg_leftovers[@]}"

    # for this setting env overrides args
    [[ "${KUBLER_VERBOSE}" == 'true' ]] && _arg_verbose='on'

    # handle --help for command script
    [[ "${_arg_help}" == 'on' ]] && { show_help; exit 0; }

    if [[ "${KUBLER_CMD_LOG}" == 'true' && "${_arg_verbose}" == 'off' && ! -d "${_KUBLER_LOG_DIR}" ]];then
        mkdir -p "${_KUBLER_LOG_DIR}" || die
    fi
    [[ "${_arg_verbose}" == 'off' ]] && file_exists_and_truncate "${_KUBLER_LOG_DIR}/${_arg_command}.log"

    # run the selected command
    trap "{ kubler_abort_handler; }" EXIT
    # shellcheck source=cmd/build.sh
    source "${cmd_script}" "${_arg_leftovers[@]}"
    trap ' ' EXIT
}

main "$@"
