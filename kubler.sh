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

# variable type conventions:
#
# environment     : SOME_VAR
# constant        : _SOME_VAR
# local           : some_var
# global          : _some_var
# function return : __function_name

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

build   - Build image(s) or namespace(s)
clean   - Remove build artifacts, like rootfs.tar, from all namespaces
new     - Create a new namespace, image or builder
push    - Push image(s) or namespace(s) to a registry
update  - Check for stage3 updates and sync portage container

${_KUBLER_BIN} <command> --help for more information\\n"
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
    [[ "${path_in}" =~ $regex ]] && path_out="$(dirname "${path_out}")"
    # and once more if ../
    regex='^[.]{2}\/?$'
    [[ "${path_in}" =~ $regex ]] && path_out="$(dirname "${path_out}")"
    __get_absolute_path="${path_out}"
}

# Arguments:
# 1: exit_message as string
# 2: exit_code as int, optional, default: 1
function die() {
    local exit_code
    exit_code="${2:-1}"
    [[ "$_PRINT_HELP" = 'yes' ]] && show_help >&2
    echo -e 'fatal:' "$1" >&2
    exit "${exit_code}"
}

function main() {
    (( ${BASH_VERSION%%.*} >= 4 )) || die "Kubler needs Bash version 4 or greater, only found version ${BASH_VERSION}."

    get_absolute_path "$0"
    [[ -z "${__get_absolute_path}" ]] && die "Couldn't determine the script's real directory, aborting" 2
    readonly _KUBLER_DIR="$(dirname -- "${__get_absolute_path}")"

    local kubler_bin lib_dir core parser working_dir cmd_script
    kubler_bin="$(basename "$0")"
    command -v "${kubler_bin}" > /dev/null
    # use full path name if not in PATH
    [[ $? -eq 1 ]] && kubler_bin="$0"
    readonly _KUBLER_BIN="${kubler_bin}"

    lib_dir="${_KUBLER_DIR}"/lib
    [[ -d "${lib_dir}" ]] || die "Couldn't find ${lib_dir}" 2
    readonly _LIB_DIR="${lib_dir}"

    core="${_LIB_DIR}"/core.sh
    [[ -f "${core}" ]] || die "Couldn't read ${core}" 2
    # shellcheck source=lib/core.sh
    source "${core}"

    # parse main args
    parser="${_LIB_DIR}"/argbash/opt-main.sh
    # shellcheck source=lib/argbash/opt-main.sh
    file_exists_or_die "${parser}" && source "${parser}"

    if [[ "${_arg_debug}" == 'on' ]]; then
        readonly BOB_IS_DEBUG='true'
        set -x
    else
        readonly BOB_IS_DEBUG='false'
    fi

    # handle --help for main script
    [[ -z "${_arg_command}" && "${_arg_help}" == 'on' ]] && { show_help; exit 0; }

    # KUBLER_WORKING_DIR overrides --working-dir, else use current working directory
    get_absolute_path "${KUBLER_WORKING_DIR:-${_arg_working_dir}}"
    working_dir="${__get_absolute_path}"
    [[ -z "${working_dir}" ]] && working_dir="${PWD}"
    detect_namespace "${working_dir}"
    
    if [[ -n "${_arg_working_dir}" ]]; then
        # shellcheck disable=SC2034
        readonly _KUBLER_BIN_HINT=" --working-dir=${working_dir}"
    fi

    # valid command?
    cmd_script="${_LIB_DIR}/cmd/${_arg_command}.sh"
    [[ -f "${cmd_script}" ]] || { show_help; die "Unknown command, ${_arg_command}" 5; }
    _is_valid_cmd='true'

    # parse command args if a matching parser exists
    parser="${_LIB_DIR}/argbash/${_arg_command}.sh"
    # shellcheck source=lib/argbash/build.sh
    [[ -f "${parser}" ]] && source "${parser}" "${_arg_leftovers[@]}"

    # handle --help for command script
    [[ "${_arg_help}" == 'on' ]] && { show_help; exit 0; }

    # run command
    # shellcheck source=lib/cmd/build.sh
    source "${cmd_script}" "${_arg_leftovers[@]}"
}

main "$@"
