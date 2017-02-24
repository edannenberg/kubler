#!/usr/bin/env bash
#
# (c) Erik Dannenberg <erik.dannenberg@xtrade-gmbh.de>
#
# variable type conventions:
#
# environment     : SOME_VAR
# constant        : _SOME_VAR
# local           : some_var
# global          : _some_var
# function return : __function_name

_help_header="gentoo-bb"
_help_commands="Commands:

build   - Build image(s) or namespace(s)
clean   - Remove build artifacts, like rootfs.tar, from all namespaces
new     - Add a new namespace, image or builder
push    - Push image(s) or namespace(s) to a registry
update  - Check for stage3 updates and sync portage container

${0} <command> --help for more information
"

function show_help() {
    local header_current_cmd
    [[ "${_is_valid_cmd}" == "true" ]] && header_current_cmd=" - ${_arg_command}"
    echo -e "\n${_help_header}${header_current_cmd}\n"
    [[ ! -z "${_help_command_description}" ]] && echo -e "${_help_command_description}\n"
    print_help
    # only show command listing if no/invalid command was provided
    if [[ -z "${_arg_command}" ]] || [[ -z "${_is_valid_cmd}" ]]; then
        echo -e "\n${_help_commands}"
    fi
}

function realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "${PWD}/${1#./}"
}

# Arguments:
# 1: exit_message as string
# 2: exit_code as int
function die()
{
    local exit_code
    exit_code=${2:-1}
    echo -e '--#@!>' "$1" >&2
    exit ${exit_code}
}

_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" \
    || die "Error, couldn't determine the script's running directory, aborting" 2

# read global build.conf
_global_conf_file="${_script_dir}/build.conf"
[[ -f "${_global_conf_file}" ]] || die "Error, couldn't read ${_global_conf_file}"
source "${_global_conf_file}"

_core_file="${_script_dir}/lib/core.sh"
[[ -f "${_core_file}" ]] || die "Error, couldn't read ${_core_file}"
source "${_core_file}"

# parse main args
_parser_file="${_script_dir}/lib/argbash/opt-main.sh"
file_exists_or_die "${_parser_file}" && source "${_parser_file}"

# handle --help for main script
[[ -z "${_arg_command}" ]] && [[ "${_arg_help}" == "on" ]] \
    && show_help && exit 0

# valid command?
_cmd_script="${_script_dir}/lib/cmd/${_arg_command}.sh"
[[ ! -f "${_cmd_script}" ]] && show_help && die "Error, unknown command: ${_arg_command}"
_is_valid_cmd="true"

# parse command args
_parser_file="${_script_dir}/lib/argbash/${_arg_command}.sh"
file_exists_or_die "${_parser_file}" && source "${_parser_file}" "${_arg_leftovers[@]}"

# handle --help for command script
[[ "${_arg_help}" == "on" ]] && show_help && exit 0

# run command
source "${_cmd_script}" "${_arg_leftovers[@]}"
