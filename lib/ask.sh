#!/usr/bin/env bash

# rlwrap does not work with functions or bash builtins, wrap read with a external script
function main() {
    __ask=
    local question default_value prefix_ask
    question="$1"
    default_value="$2"
    prefix_ask="${3:->}"
    read -r -p "${prefix_ask} ${question} (${default_value}): " __ask
    [[ -z "${__ask}" ]] && __ask="${default_value}"
    echo "${__ask}"
}

main "$@"
