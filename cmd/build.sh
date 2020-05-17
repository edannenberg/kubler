#!/usr/bin/env bash
# Copyright (c) 2014-2019, Erik Dannenberg <erik.dannenberg@xtrade-gmbh.de>
# All rights reserved.

_required_binaries=" bzip2 grep id jq wget"
# shellcheck disable=SC2154
[[ "${_arg_skip_gpg_check}" != "on" ]] && _required_binaries+=" gpg"
[[ -n "$(command -v sha512sum)" ]] && _required_binaries+=" sha512sum" || _required_binaries+=" shasum"

# Populate _build_order_images and _build_order_builders by checking image dependencies for given image target_ids
#
# Arguments:
# n: target_ids - fully qualified ids
function generate_build_order() {
    local target_ids image_id builder_id engine_id excluded_image
    target_ids=( "$@" )
    _build_order_images=()
    _required_images=()
    _required_builders=()
    _required_engines=()
    # add builder for interactive dep graph
    if [[ "${#_required_builders_interactive[@]}" -gt 0 ]]; then
        for builder_id in "${!_required_builders_interactive[@]}"; do
            _required_builders["${builder_id}"]="${_required_builders_interactive[${builder_id}]}"
        done
    fi
    # add engine for interactive dep graph
    if [[ "${#_required_engines_interactive[@]}" -gt 0 ]]; then
        for engine_id in "${!_required_engines_interactive[@]}"; do
            _required_engines["${engine_id}"]="${_required_engines_interactive[${engine_id}]}"
        done
    fi
    for image_id in "${target_ids[@]}"; do
        check_image_dependencies "${image_id}"
    done
    # generate builder build order
    _build_order_builders=()
    _required_cores=()
    for builder_id in "${!_required_builders[@]}"; do
        check_builder_dependencies "${builder_id}"
        if ! is_in_array "${builder_id}" "${_build_order_builders[@]}"; then
            expand_image_id "${builder_id}" "${_BUILDER_PATH}"
            # shellcheck disable=SC2154
            _required_builders["${builder_id}"]="${__expand_image_id}"
            _build_order_builders+=( "${builder_id}" )
        fi
    done
    # shellcheck disable=SC2154
    for excluded_image in "${_arg_exclude[@]}";do
        if [[ -n "${_required_images[${excluded_image}]+_}" ]]; then
            unset _required_images["${excluded_image}"]
            rm_array_value "${excluded_image}" "${_build_order_images[@]}"
            _build_order_images=( "${__rm_array_value[@]}" )
        fi
    done
}

# Check image dependencies and populate _required_images, _required_builders and _required_engines. Recursive.
#
# Arguments:
# 1: image_id
function check_image_dependencies() {
    local image_id current_image_path test_deps test_dep
    image_id="$1"
    
    if [[ "${image_id}" == 'scratch' ]]; then
        return
    fi
    
    expand_image_id "${image_id}" "${_IMAGE_PATH}"
    current_image_path="${__expand_image_id}"
    # shellcheck disable=SC2154
    source_image_conf "${current_image_path}"
    test_deps=("${POST_BUILD_DC_DEPENDENCIES[@]}")

    # collect required engines
    [[ -z "${_required_engines[${BUILD_ENGINE}]+_}" ]] && _required_engines["${BUILD_ENGINE}"]="${BUILD_ENGINE}"

    # collect required build containers
    if [[ -n "${BUILDER}" ]];then
         if [[ -z "${_required_builders[${BUILDER}]+_}" ]]; then
            expand_image_id "${BUILDER}" "${_BUILDER_PATH}"
            _required_builders["${BUILDER}"]="${__expand_image_id}"
         fi
    else
        # add default build container of current namespace
        if [[ -z "${_required_builders[${DEFAULT_BUILDER}]+_}" ]]; then
            expand_image_id "${DEFAULT_BUILDER}" "${_BUILDER_PATH}"
            _required_builders["${DEFAULT_BUILDER}"]="${__expand_image_id}"
        fi
    fi

    # skip further checking if already processed
    if is_in_array "${image_id}" "${_build_order_images[@]}"; then
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
    _required_images["${image_id}"]="${current_image_path}"
    _build_order_images+=( "${image_id}" )
}

# Check builder dependencies and populate _build_order_builder and _required_cores. Recursive.
#
# Arguments:
#
# 1: builder_id
# 2: previous_builder_id
function check_builder_dependencies() {
    local builder_id previous_builder_id
    builder_id="$1"
    previous_builder_id="$2"
    expand_image_id "${builder_id}" "${_BUILDER_PATH}"
    source_image_conf "${__expand_image_id}"
    # is a stage3 defined for this builder?
    [[ -n "${STAGE3_BASE}" ]] && [[ -z "${_required_cores[${STAGE3_BASE}]+_}" ]] \
        && _required_cores["${STAGE3_BASE}"]="${STAGE3_BASE}"
    # skip further checking if already processed
    if ! string_has_word "${_build_order_builders[*]}" "${builder_id}"; then
        # check parent if this is not a stage3 builder
        [[ -z "${STAGE3_BASE}" ]] && check_builder_dependencies "${BUILDER}" "${builder_id}"
        # finally add the builder
        if [[ -n "${previous_builder_id}" ]]; then
            expand_image_id "${builder_id}" "${_BUILDER_PATH}"
            _required_builders["${builder_id}"]="${__expand_image_id}"
            _build_order_builders+=( "${builder_id}" )
        fi
    fi
}

# Arguments:
# 1: target_id
# 2: image_path
# 3: image_type
function run_interactive_builder() {
        local target_id image_path
        target_id="$1"
        image_path="$2"
        image_type="${3:-${_IMAGE_PATH}}"

        add_status_value "${target_id}"

        # shellcheck disable=SC2034
        BOB_IS_INTERACTIVE='true'

        source_image_conf "${image_path}"
        unset _use_parent_builder_mounts
        # shellcheck disable=SC2034
        [[ "${PARENT_BUILDER_MOUNTS}" == 'true' ]] && _use_parent_builder_mounts='true'
        get_build_container "${target_id}" "${image_type}"
        [[ $? -eq 1 ]] && die "Error while executing get_build_container(): ${builder_id}"
        # shellcheck disable=SC2154
        builder_id="${__get_build_container}"

        image_exists "${builder_id}" || die "Couldn't find image ${builder_id}"

        # shellcheck disable=SC2034
        BOB_CURRENT_TARGET="${target_id}"

        # pass variables starting with BOB_ to build container as ENV
        for bob_var in ${!BOB_*}; do
            _container_env+=("${bob_var}=${!bob_var}")
        done

        generate_dockerfile "${image_path}"

        _container_mounts=(
            "${KUBLER_DISTFILES_DIR}:/distfiles"
            "${KUBLER_PACKAGES_DIR}:/packages"
            "${image_path}:/config"
        )
        [[ ${#BUILDER_MOUNTS[@]} -gt 0 ]] && _container_mounts+=("${BUILDER_MOUNTS[@]}")
        [[ ${#BUILDER_DOCKER_ARGS[@]} -gt 0 ]] && _container_args+=("${BUILDER_DOCKER_ARGS[@]}")
        # shellcheck disable=SC2034
        _container_mount_portage='true'
        # shellcheck disable=SC2034
        _container_cmd=( '/bin/bash' )

        msg_info "using: ${BUILD_ENGINE} / builder: ${builder_id}"
        msg "\\nRunning interactive build container with ${image_path} mounted as /config"
        msg "Artifacts from previous builds: /backup-rootfs\\n"
        msg "You may run any helper function available in your image's build.sh, like update_use, etc."
        msg "Once you are finished tinkering, history | cut -c 8- may prove useful ;)\\n"
        msg "To start the build:\\n"
        msg "    $ kubler-build-root \\n\\nNote: Starting a build twice in the same container is not recommended\\n"
        msg "Search packages: eix <search-string> / Check use flags: emerge -pv <package-atom>\\n"

        run_image "${builder_id}:${IMAGE_TAG}" "${builder_id}" 'true' '' 'false'
}

function main() {
    local target_id target_path build_type engine_id builder_id image_id image_path bob_var init_msg

    cd "${_NAMESPACE_DIR}" || die "Failed to change dir to ${_NAMESPACE_DIR}"

    add_status_value 'init'
    init_msg='generate build graph'

    # -i and -n equals -I
    # shellcheck disable=SC2154
    [[ "${_arg_interactive}" == 'on' && "${_arg_no_deps}" == 'on' ]]  && _arg_interactive_no_deps='on'

    # shellcheck disable=SC2154
    if [[ "${_arg_verbose_build}" == 'off' ]]; then
        BOB_EMERGE_DEFAULT_OPTS="${BOB_EMERGE_DEFAULT_OPTS} --quiet-build"
    else
        # shellcheck disable=SC2034
        _arg_verbose='on'
    fi

    # shellcheck disable=SC2154
    [[ "${_arg_clear_everything}" == 'on' ]] && _arg_clear_build_container='on'
    # shellcheck disable=SC2034
    [[ "${_arg_clear_build_container}" == 'on' ]] && _arg_force_full_image_build='on'

    # prepare a --interactive build
    # shellcheck disable=SC2154
    [[ "${_arg_interactive_no_deps}" == 'on' ]] && _arg_interactive='on'
    if [[ "${_arg_interactive}" == 'on' ]]; then
        target_id="${_arg_target_id}"

        if [[ "${target_id}" != *'/'* || "${target_id}" == *'/' ]]; then
            if [[ -n "${_NAMESPACE_DEFAULT}" ]]; then
                target_id="${_NAMESPACE_DEFAULT}/${target_id}"
            else
                die "--interactive expects an image id, but only got a namespace."
            fi
        fi
        build_type="${_IMAGE_PATH}"
        expand_image_id "${target_id}" "${build_type}"
        if [[ $? -eq 3 ]]; then
            # builder image_id is allowed for interactive runs, so let's retry with that
            expand_image_id "${target_id}" "${_BUILDER_PATH}" || die "Couldn't find image or builder ${target_id}"
            build_type="${_BUILDER_PATH}"
        fi
        target_path="${__expand_image_id}"
        source_image_conf "${target_path}"
        validate_image "${target_id}" "${target_path}"

        if [[ "${_arg_interactive_no_deps}" == 'on' ||  "${build_type}" != "${_IMAGE_PATH}" ]]; then
            run_interactive_builder "${target_id}" "${target_path}" "${build_type}"
            trap ' ' EXIT
            exit $?
        fi
        declare -A _required_builders_interactive _required_engines_interactive

        # modify target_id args and required builders/engines for dep graph
        _required_engines_interactive["${BUILD_ENGINE}"]="${BUILD_ENGINE}"
        if [[ -n "${BUILDER}" ]]; then
            expand_image_id "${BUILDER}" "${_BUILDER_PATH}"
            _required_builders_interactive["${BUILDER}"]="${__expand_image_id}"
            _arg_target_id=()
        elif [[ -n "${IMAGE_PARENT}" && "${IMAGE_PARENT}" != 'scratch' ]]; then
            _arg_target_id=( "${IMAGE_PARENT}" )
        else
            expand_image_id "${DEFAULT_BUILDER}" "${_BUILDER_PATH}"
            _required_builders_interactive["${DEFAULT_BUILDER}"]="${__expand_image_id}"
            _arg_target_id=()
        fi
        init_msg+=" for interactive build of ${target_id}"
    fi

    # --no-deps build
    # shellcheck disable=SC2154
    if [[ "${_arg_no_deps}" == 'on' ]]; then
        for image_id in "${_arg_target_id[@]}"; do
            [[ "${image_id}" == "*" ]] && die "--no-deps does not support wildcards, only fully qualified ids."
            if [[ "${image_id}" != *"/"* || "${image_id}" == *'/' ]]; then
                if [[ -n "${_NAMESPACE_DEFAULT}" ]]; then
                    image_id="${_NAMESPACE_DEFAULT}/${image_id}"
                    [[ "${image_id}" == *'/' ]] && image_id="${image_id::-1}"
                else
                    die "--no-deps expects a fully qualified image_id, but only got namespace \"${image_id}\""
                fi
            fi
            expand_image_id "${image_id}" "${_IMAGE_PATH}" || die "Couldn't find a image dir for ${image_id}"
            source_image_conf "${__expand_image_id}"
            validate_image "${image_id}" "${__expand_image_id}"
            build_image_no_deps "${image_id}" "${__expand_image_id}"
        done
        trap ' ' EXIT
        exit $?
    fi

    msg_info "${init_msg}"

    declare -a _build_order_images _build_order_builders
    declare -A _required_images _required_builders _required_cores _required_engines

    expand_requested_target_ids "${_arg_target_id[@]}"
    # shellcheck disable=SC2154
    generate_build_order "${__expand_requested_target_ids[@]}"

    msgf "required engines:" "${!_required_engines[*]}"
    msgf "required stage3:" "${!_required_cores[*]}"
    msgf "required builders:" "${_build_order_builders[*]}"
    [[ "${#_build_order_images[@]}" -gt 0 ]] && msgf "build sequence:" "${_build_order_images[*]}"
    [[ -n ${_arg_exclude} ]] && msgf "excluded:" "${_arg_exclude[*]}"

    for engine_id in "${!_required_engines[@]}"; do
        source_build_engine "${engine_id}"
        validate_engine
    done

    msg_ok 'done.'

    for builder_id in "${_build_order_builders[@]}"; do
        image_path="${_required_builders[${builder_id}]}"
        source_image_conf "${image_path}"
        validate_image "${builder_id}" "${image_path}"
        build_builder "${builder_id}" "${image_path}"
        # shellcheck disable=SC2154
        [[ "${_arg_verbose}" == 'off' ]] && file_exists_and_truncate "${_KUBLER_LOG_DIR}/${_arg_command}.log"
    done

    for image_id in "${_build_order_images[@]}"; do
        image_path="${_required_images[${image_id}]}"
        source_image_conf "${image_path}"
        validate_image "${image_id}" "${image_path}"
        build_image "${image_id}" "${image_path}"
        [[ "${_arg_verbose}" == 'off' ]] && file_exists_and_truncate "${_KUBLER_LOG_DIR}/${_arg_command}.log"
    done

    # shellcheck disable=SC2154
    [[ "${_arg_interactive}" == 'on' ]] && run_interactive_builder "${target_id}" "${target_path}"
}

main "$@"
