#!/usr/bin/env sh

# Replace all matches for given sed regex with given replace_value.
# Exit codes:
#   0 - success
#   3 - no match for regex
#   5 - file not found
#
# Arguments:
# 1: regex
# 2: replace_value
# 3: target_file
# 4: sed_delimiter - optional, default: %
replace_in_file() {
    regex="$1"
    replace_value="$2"
    target_file="$3"
    sed_delimiter="${4:-%}"
    [ ! -f "${target_file}" ] && return 5
    # shellcheck disable=SC2016
    /bin/sed -i "\\${sed_delimiter}${regex}${sed_delimiter},\${s${sed_delimiter}${sed_delimiter}${replace_value}${sed_delimiter}g"';b};$q3' \
        "${target_file}"
}

# Replace all matches for given sed regex with given replace_value. Script is aborted on no match or missing file.
#
# Arguments:
# 1: regex
# 2: replace_value
# 3: target_file
# 4: sed_delimiter - optional, default: %
main() {
    regex="$1"
    replace_value="$2"
    target_file="$3"
    sed_delimiter="${4:-%}"
    replace_in_file "${regex}" "${replace_value}" "${target_file}" "${sed_delimiter}"
    exit_sig=$?
    if [ "${exit_sig}" -eq 5 ]; then
        echo "fatal: couldn't find file ${target_file}"
    elif [ "${exit_sig}" -eq 3 ]; then
        echo "fatal: no match for '${regex}' in ${target_file}"
    fi
    exit "${exit_sig}"
}

[ "$#" -ne 3 ] && [ "$#" -ne 4 ] \
    && echo "usage: sed-or-die <regex> <replace_value> <target_file> [sed_separator, optional, default: %]" \
    && exit 1

main "$@"
