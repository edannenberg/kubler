#!/bin/bash

_help_command_description="Add a new namespace, image or builder"

# ARGBASH_WRAP([opt-global])
# ARG_POSITIONAL_SINGLE([template_type],[namespace|image|builder])
# ARG_POSITIONAL_SINGLE([name],[name i.e. myns or myns/myimage])
# ARG_HELP([])
# ARGBASH_SET_INDENT([    ])
# ARGBASH_GO()
# needed because of Argbash --> m4_ignore([
### START OF CODE GENERATED BY Argbash v2.3.0 one line above ###
# Argbash is a bash code generator used to get arguments parsing right.
# Argbash is FREE SOFTWARE, see https://argbash.io for more info

die()
{
    local _ret=$2
    test -n "$_ret" || _ret=1
    test "$_PRINT_HELP" = yes && print_help >&2
    echo "$1" >&2
    exit ${_ret}
}

# THE DEFAULTS INITIALIZATION - POSITIONALS
_positionals=()
# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_verbose=off

print_help ()
{
    printf 'Usage: %s [--(no-)verbose] [-h|--help] <template_type> <name>\n' "$0"
    printf "\t%s\n" "<template_type>: namespace|image|builder"
    printf "\t%s\n" "<name>: name i.e. myns or myns/myimage"
    printf "\t%s\n" "-h,--help: Prints help"
}

# THE PARSING ITSELF
while test $# -gt 0
do
    _key="$1"
    case "$_key" in
        --no-verbose|--verbose)
            _arg_verbose="on"
            _args_opt_global_opt+=("${_key%%=*}")
            test "${1:0:5}" = "--no-" && _arg_verbose="off"
            ;;
        -h*|--help)
            print_help
            exit 0
            ;;
        *)
            _positionals+=("$1")
            ;;
    esac
    shift
done

_positional_names=('_arg_template_type' '_arg_name' )
test ${#_positionals[@]} -lt 2 && _PRINT_HELP=yes die "FATAL ERROR: Not enough positional arguments - we require exactly 2, but got only ${#_positionals[@]}." 1
test ${#_positionals[@]} -gt 2 && _PRINT_HELP=yes die "FATAL ERROR: There were spurious positional arguments --- we expect exactly 2, but got ${#_positionals[@]} (the last one was: '${_positionals[*]: -1}')." 1
for (( ii = 0; ii < ${#_positionals[@]}; ii++))
do
    eval "${_positional_names[ii]}=\${_positionals[ii]}" || die "Error during argument parsing, possibly an Argbash bug." 1
done

# OTHER STUFF GENERATED BY Argbash
_args_opt_global=("${_args_opt_global_opt[@]}" "${_args_opt_global_pos[@]}")

### END OF CODE GENERATED BY Argbash (sortof) ### ])