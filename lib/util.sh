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

KUBLER_VERBOSE="${KUBLER_VERBOSE:-false}"
KUBLER_CMD_LOG="${KUBLER_CMD_LOG:-true}"
KUBLER_COLORS="${KUBLER_COLORS:-true}"
KUBLER_BELL_ON_ERROR="${KUBLER_BELL_ON_ERROR:-true}"

# terminal output related stuff
_term_red=$(tput setaf 1)
_term_green=$(tput setaf 2)
_term_yellow=$(tput setaf 3)
#_term_blue=$(tput setaf 4)
#_term_magenta=$(tput setaf 5)
_term_cyan=$(tput setaf 6)

#_term_bold=$(tput bold)
_term_reset=$(tput sgr0)
# clear until eol
_term_ceol=$(tput el)
# cursor 1 line up
_term_cup=$(tput cuu1)

_is_terminal='true'
# unset color vars if requested or not on terminal
[[ "${KUBLER_COLORS}" == 'false' || ! -t 1 ]] \
    && unset _term_red _term_green _term_yellow _term_blue _term_magenta _term_cyan _term_bold _term_reset
[[ ! -t 1 ]] && unset _is_terminal

# 1 char = 1 frame
_status_spinner='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
# printf template, extend/override at will
_def_status_spinner_tmpl="${_term_yellow}»[${_term_reset}%s${_term_yellow}]»"
_status_spinner_tmpl="${_def_status_spinner_tmpl}"
_status_msg='this could be your msg'

_def_prefix_info="${_term_yellow}»»»»»${_term_reset}"
_def_prefix_info_sub="${_term_yellow}»»»${_term_reset}"
_def_prefix_ok="${_term_yellow}»[${_term_green}✔${_term_yellow}]»${_term_reset}"
_def_prefix_error="${_term_yellow}»[${_term_red}✘${_term_yellow}]»${_term_reset}"
_def_prefix_warn="${_term_yellow}»[${_term_cyan}!${_term_yellow}]»${_term_reset}"
_def_prefix_ask="${_term_yellow}»[${_term_cyan}?${_term_yellow}]»${_term_reset}"

_prefix_info="${_def_prefix_info}"
_prefix_info_sub="${_def_prefix_info_sub}"
_prefix_ok="${_def_prefix_ok}"
_prefix_error="${_def_prefix_error}"
_prefix_warn="${_def_prefix_warn}"
_prefix_ask="${_def_prefix_ask}"

# Arguments
# n: message
function msg() {
    echo -e "$@"
}

# Arguments
# n: message
function msg_error() {
    msg "${_prefix_error}" "${@}"
}

# Arguments
# n: message
function msg_info() {
    msg "${_prefix_info}" "${@}"
}

# Arguments
# n: message
function msg_info_sub() {
    msg "${_prefix_info_sub}" "${@}"
}

# Arguments
# n: message
function msg_ok() {
    msg "${_prefix_ok}" "${@}"
}

# Arguments
# n: message
function msg_warn() {
    msg "${_prefix_warn}" "${@}"
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
    printf "${_prefix_info_sub} %-20s %s\n" "${msg_prefix}" "$@"
}

# Arguments:
# 1: src_str
# 2: repeat_amount
function repeat_str() {
    __repeat_str=
    local src_str repeat_amount tmp_str
    src_str="$1"
    repeat_amount="$2"
    [[ ${repeat_amount} -eq 0 ]] && { __repeat_str=""; return; }
    printf -v tmp_str '%*s' "${repeat_amount}" ''
    # shellcheck disable=SC2034
    __repeat_str="${tmp_str// /${src_str}}"
}

function is_compact_output_active() {
    # shellcheck disable=SC2154
    [[ -z "${_is_terminal}" || "${_arg_verbose}" == 'on' ]] && return 3
    return 0
}

# Print status bar with an activity spinner. The spinner moves one frame per call.
#
# Arguments:
# 1: status_msg - text to be displayed
# 2: callback_name - optional, a function named that is called on each invocation. it's output var is echoed
# 3: callback_args - optional, passed to callback function on execution
function status_with_spinner() {
    local status_msg callback_name cb_ret_name callback_output
    status_msg="$1"
    [[ -n "$2" ]] && callback_name="$2" && shift 2;

    if [[ -n "${callback_name}" ]] && declare -F "${callback_name}" &>/dev/null; then
        "${callback_name}" "$@" 1> /dev/null
        cb_ret_name=__"${callback_name}"
        callback_output="${!cb_ret_name}"
    fi

    printf "${_term_cup}${_term_ceol}${_status_spinner_tmpl}${_term_reset} %s\n\r" \
        "${_status_spinner:x++%${#_status_spinner}:1}" \
        "${status_msg}${callback_output}"
    sleep 0.5
}

# Manipulate the global status bar
#
# Arguments:
# 1: status_value - optional, the value to be added to the global status bar. if empty the bar is reset to it's default.
# 2: append - optional, if true appends the value to the current state, else the status bar defaults are used as base
function add_status_value() {
    local status_value append_status status_box
    status_value="$1"
    append_status="${2:-false}"

    # shellcheck disable=SC2154,2034
    [[ -n "${status_value}" ]] \
        && status_box="${_term_yellow}[${_term_reset}${status_value}${_term_yellow}]»${_term_reset}"

    if [[ "${append_status}" == 'false' ]]; then
        # shellcheck disable=SC2154,2034
        _status_spinner_tmpl="${_def_status_spinner_tmpl}${status_box}"
        # shellcheck disable=SC2154,2034
        _prefix_error="${_def_prefix_error}${status_box}"
        # shellcheck disable=SC2154,2034
        _prefix_info="${_def_prefix_info}${status_box}"
        # shellcheck disable=SC2154,2034
        _prefix_ok="${_def_prefix_ok}${status_box}"
        # shellcheck disable=SC2154,2034
        _prefix_warn="${_def_prefix_warn}${status_box}"
    else
        # shellcheck disable=SC2154,2034
        _status_spinner_tmpl="${_status_spinner_tmpl}${status_box}"
        # shellcheck disable=SC2154,2034
        _prefix_error="${_prefix_error}${status_box}"
        # shellcheck disable=SC2154,2034
        _prefix_info="${_prefix_info}${status_box}"
        # shellcheck disable=SC2154,2034
        _prefix_ok="${_prefix_ok}${status_box}"
        # shellcheck disable=SC2154,2034
        _prefix_warn="${_prefix_warn}${status_box}"
    fi
}

# Callback for pwrap that add the size of a given filen_path to the status bar. Usage:
#
# _pwrap_callback=('cb_add_filesize_to_status' "${some_path}")
# pwrap some_command "foo"
#
# 1: file_path
function cb_add_filesize_to_status() {
    __cb_add_filesize_to_status=
    local file_path file_size
    file_path="$1"
    file_size='n/a'
    get_file_size "${file_path}" 'true'
    [[ -n "${__get_file_size}" ]] && file_size="${__get_file_size}"
    # shellcheck disable=SC2034
    __cb_add_filesize_to_status=" ${_term_yellow}[${_term_reset} ${file_size} ${_term_yellow}]${_term_reset}"
}

# Thin wrapper for passed command that prints an activity spinner along with the current value of the global
# var _status_msg for the duration of the command. StdOut of passed command is redirected into the void. If --verbose
# was passed, or if we are not in a terminal, only _status_msg is echoed, no spinner and normal command output.
#
# Arguments:
# 1: command
# n: args
# Return value: exit signal of passed command
function pwrap() {
    local exit_sig no_stderr redirect_target
    exit_sig=0
    no_stderr=
    no_log=
    [[ "$1" == 'nostderr' ]] && no_stderr='true' && shift
    [[ "$1" == 'nolog' ]] && no_log='true' && shift
    msg_info "${_status_msg}"
    is_compact_output_active || { "$@"; return $?; }

    redirect_target='/dev/null'
    # shellcheck disable=SC2154
    [[ "${KUBLER_CMD_LOG}" == 'true' ]] && redirect_target="${_KUBLER_LOG_DIR}/${_arg_command}.log"

    # launch spinner in bg
    # shellcheck disable=SC2154
    while true;do status_with_spinner "${_status_msg}" "${_pwrap_callback[@]}";done &
    # save job id
    _pwrap_handler_args=$!
    add_trap_fn 'pwrap_handler'
    # exec passed cmd with disabled stdout
    if [[ -z "${no_stderr}" && "${redirect_target}" == '/dev/null' ]] \
        || [[ -z "${no_stderr}" && "${no_log}" == 'true' ]]
    then
        "$@" 1> /dev/null
        exit_sig=$?
    elif [[ "${redirect_target}" == '/dev/null' ]] || [[ "${no_log}" == 'true' ]]; then
        "$@" &> /dev/null
        exit_sig=$?
    else
        echo "»»» $(date) »»» exec:" "$@" >> "${redirect_target}"
        "$@" &>> "${redirect_target}"
        exit_sig=$?
    fi
    # kill job
    kill $!
    wait $! &> /dev/null
    rm_trap_fn 'pwrap_handler'
    unset _pwrap_callback _pwrap_handler_args
    echo -n "${_term_cup}${_term_ceol}"
    return ${exit_sig}
}

function pwrap_handler() {
    [[ -n "${_pwrap_handler_args}" ]] && \
        { kill "${_pwrap_handler_args}" 2> /dev/null;
          wait "${_pwrap_handler_args}" &> /dev/null;
          unset _pwrap_handler_args _prwap_callback; }
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
    read -r -p "${_prefix_ask} ${question} (${default_value}): " __ask
    [[ -z "${__ask}" ]] && __ask="${default_value}"
}

# Arguments:
# 1: file_path as string
# 2: error_msg, optional
function file_exists_or_die() {
    local file error_msg
    file="$1"
    error_msg="${2:-couldn\'t read: ${file}}"
    [[ -f "${file}" ]] || die "${error_msg}"
}

# Arguments:
# 1: file_path as string
function file_exists_and_truncate() {
    local file error_msg
    file="$1"
    [[ -f "${file}" ]] && cp /dev/null "${file}"
}

function sha_sum() {
    [[ -n "$(command -v sha512sum)" ]] && echo 'sha512sum' || echo 'shasum -a512'
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

# Arguments:
# 1: value - string to check for
# 2: src_array - passed via "${some_array[@]}"
function is_in_array() {
    local value src_array
    value="$1"
    shift
    src_array=( "$@" )
    for entry in "${src_array[@]}"; do
        [[ "${entry}" == "${value}" ]] && return 0
    done
    return 1
}

# Remove any entry from given non-associative array_to_check that matches given value_to_rm. The returned array is not
# sparse and the original order is preserved.
#
# Arguments:
# 1: value_to_rm - string to remove from array
# n: array_to_check - passed via "${some_array[@]}"
function rm_array_value() {
    __rm_array_value=()
    local value_to_rm array_to_check tmp_array entry
    value_to_rm="$1"
    shift
    array_to_check=( "$@" )
    tmp_array=()
    for entry in "${array_to_check[@]}"; do
        [[ "${entry}" != "${value_to_rm}" ]] && tmp_array+=( "${entry}" )
    done
    # shellcheck disable=SC2034
    __rm_array_value=( "${tmp_array[@]}" )
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

# Set __get_file_size to size of file in bytes for given file_path.
#
# Arguments:
# 1: file_path - the path to get the size for
# 2: format_output - optional, if true converts output to human readable format, default: false
function get_file_size() {
    __get_file_size=
    local file_path du_args file_size
    file_path="$1"
    format_output="${2:-false}"
    if [[ -f "${file_path}" ]]; then
        du_args=()
        [[ "${format_output}" == 'true' ]] && du_args+=( '-h' )
        file_size="$(du "${du_args[@]}" --max-depth=0 "${file_path}" | cut -f1)"
        __get_file_size="${file_size}"
    fi
}

# Arguments:
# 1: dir_path
function dir_is_empty() {
    local dir_path
    dir_path="$1"
    [[ -d "${dir_path}" ]] || die "${dir_path} is not a directory"
    [[ -z "$(ls -A "${dir_path}")" ]]&& return 0
    return 1
}

# Returns with exit signla 0 if given dir_path has sub directories, or 3 if not
#
# Arguments:
# 1: dir_path
function dir_has_subdirs() {
    local dir_path exit_sig
    dir_path="$1"
    ls "${dir_path}"/*/ &> /dev/null
    exit_sig=$?
    [[ ${exit_sig} -eq 0 ]] && return 0
    return 3
}

# Arguments:
# 1: dir_path
function is_git_dir() {
    local dir_path
    dir_path="$1"
    git -C "$1" rev-parse 2> /dev/null
    return $?
}

# Arguments:
# 1: repo_url
# 2: working_dir
# 3: dir_name
function clone_or_update_git_repo() {
    local repo_url working_dir dir_name cherry_out git_args
    repo_url="$1"
    working_dir="$2"
    dir_name="$3"
    git_args=()
    [[ ! -d "${working_dir}" ]] && die "Git working dir ${working_dir} does not exist."
    is_compact_output_active && git_args+=( '-q' )
    if is_git_dir "${working_dir}/${dir_name}"; then
        _status_msg='check git remote for updates'
        pwrap 'nostderr' git -C "${working_dir}/${dir_name}" fetch "${git_args[@]}" origin || die
        cherry_out="$(git -C "${working_dir}/${dir_name}" cherry master origin/master)"
        if [[ -z "${cherry_out}" ]]; then
            msg_ok "no updates."
            return 0
        else
            # reset to remote as PACKAGES.md files might prevent a normal pull
            _status_msg="updates found, reset ${working_dir}/${dir_name} to remote"
            pwrap 'nostderr' git -C "${working_dir}/${dir_name}" reset "${git_args[@]}" --hard origin/master || die
            msg_ok "updated."
            return 3
        fi
    else
        _status_msg="clone ${repo_url}"
        pwrap 'nostderr' git -C "${working_dir}" clone "${git_args[@]}" "${repo_url}" "${dir_name}" || die
        msg_ok "cloned."
    fi
}
