#!/usr/bin/env bash
# Copyright (c) 2014-2019, Erik Dannenberg <erik.dannenberg@xtrade-gmbh.de>
# All rights reserved.

# Check image dependencies and populate global var _dep_graph. Recursive.
#
# Arguments:
#
# 1: image_id
function check_image_dependencies() {
    local image_id test_deps test_dep
    image_id="$1"
    
    if [[ "${image_id}" == 'scratch' ]]; then
        return
    fi
    
    expand_image_id "${image_id}" "${_IMAGE_PATH}"
    # shellcheck disable=SC2154
    source_image_conf "${__expand_image_id}"
    test_deps=("${POST_BUILD_DC_DEPENDENCIES[@]}")

    # skip further checking if already processed
    if is_in_array "${image_id}" "${_dep_graph[@]}"; then
        return
    fi
    
    if [[ -n "${IMAGE_PARENT}" ]]; then
        # check parent image dependencies
        check_image_dependencies "${IMAGE_PARENT}"
        
        # check test dependencies, if any
        for test_dep in "${test_deps[@]}"; do
            check_image_dependencies "${test_dep}"
        done
    fi
    
    # finally add the image
    _dep_graph+=( "${image_id}" )
}

function main() {
    local dotstring output_file dot_exec
    # shellcheck disable=SC2154
    output_file="${_arg_output_file}"
    dot_exec=()

    # shellcheck disable=SC2154
    [[ -z "${output_file}" && "${_arg_as_raw_dot}" != 'on' && "${_arg_as_ascii}" != 'on' && "${_arg_as_boxart}" != 'on' ]] \
        && die "--output-file is required for png output"

    # shellcheck disable=SC2154
    expand_requested_target_ids "${_arg_target_id[@]}"

    declare -a _dep_graph

    # shellcheck disable=SC2154
    for image_id in "${__expand_requested_target_ids[@]}"; do
        check_image_dependencies "${image_id}"
    done

    dotstring="strict digraph imagedeps {\n    rankdir=LR;"

    for image_id in "${_dep_graph[@]}"; do
        node_options=''
        expand_image_id "${image_id}"
        source_image_conf "${__expand_image_id}"
        if [[ -n "${BUILDER}" ]]; then
            node_options=" [label=\"${BUILDER}\"]"
        elif [[ "${IMAGE_PARENT}" == 'scratch' ]]; then
            node_options=" [label=\"${DEFAULT_BUILDER}\"]"
        fi
        dotstring="${dotstring}\n   \"${IMAGE_PARENT}\" -> \"${image_id}\"${node_options};"
        for test_dep in "${POST_BUILD_DC_DEPENDENCIES[@]}"; do
            dotstring="${dotstring}\n   \"${test_dep}\" -> \"${image_id}\" [label=\"compose-test\"];"
        done
    done

    [[ "${_arg_as_raw_dot}" != 'on' ]] && ! image_exists "${KUBLER_DEPGRAPH_IMAGE}" && {\
        msg_error "docker image ${KUBLER_DEPGRAPH_IMAGE} is required locally, to resolve this:"; msg_info_sub;
        msg_info_sub "$ kubler build ${KUBLER_DEPGRAPH_IMAGE}";
        msg_info_sub; msg_info_sub "or"; msg_info_sub;
        msg_info_sub "$ docker pull ${KUBLER_DEPGRAPH_IMAGE}"; msg_info_sub;
        msg_info_sub "or use --as-raw-dot/-r which doesn't require a docker image"; msg_info_sub;
        die; }

    dotstring="${dotstring}\n}"

    dot_exec+=( 'graph-easy' '--from' 'dot' )
    if [[ "${_arg_as_ascii}" == 'on' ]]; then
        dot_exec+=( '--as_ascii' )
    elif [[ "${_arg_as_boxart}"  == 'on' ]]; then
        dot_exec+=( '--as_boxart' )
    else
        dot_exec=( 'dot' '-Tpng' )
    fi

    if [[ "${_arg_as_raw_dot}" == 'on' && -n "${output_file}" ]]; then
        echo -e "${dotstring}" > "${output_file}"
    elif [[ "${_arg_as_raw_dot}" == 'on' ]]; then
        echo -e "${dotstring}"
    elif [[ -n "${output_file}" ]]; then
        echo -e "${dotstring}" | "${DOCKER}" run --rm -i "${KUBLER_DEPGRAPH_IMAGE}" "${dot_exec[@]}" > "${output_file}"
    else
        echo -e "${dotstring}" | "${DOCKER}" run --rm -i "${KUBLER_DEPGRAPH_IMAGE}" "${dot_exec[@]}"
    fi
}

main "$@"
