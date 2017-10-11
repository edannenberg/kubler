#!/usr/bin/env bash
# Copyright (c) 2014-2017, Erik Dannenberg <erik.dannenberg@xtrade-gmbh.de>
# All rights reserved.

_required_binaries=" bzip2 grep id wget"
# shellcheck disable=SC2154
[[ "${_arg_skip_gpg_check}" != "on" ]] && _required_binaries+=" gpg"
[[ $(command -v sha512sum) ]] && _required_binaries+=" sha512sum" || _required_binaries+=" shasum"

# Populate _build_order and _build_order_builder by checking image dependencies
#
# Arguments:
#
# 1: images - fully qualified ids, space separated
function generate_build_order() {
    local images image_id builder_id excluded_image
    images="$1"
    # generate image build order
    _required_builder=""
    _required_engines=""
    for image_id in ${images}; do
        check_image_dependencies "${image_id}"
        if [ -z "$_build_order" ]; then
            _build_order="${image_id}"
        else
            ! string_has_word "${_build_order}" "${image_id}" && _build_order+=" ${image_id}"
        fi
    done
    # generate builder build order
    _build_order_builder=""
    _required_cores=""
    for builder_id in ${_required_builder}; do
        check_builder_dependencies "${builder_id}"
        if [ -z "$_build_order_builder" ]; then
            _build_order_builder="${builder_id}"
        else
            ! string_has_word "${_build_order_builder}" "${builder_id}" && _build_order_builder+=" ${builder_id}"
        fi
    done
    # shellcheck disable=SC2154
    for excluded_image in "${_arg_exclude[@]}";do
        _build_order="${_build_order/${excluded_image}/}"
    done
    read -r _build_order <<< "${_build_order}"
}

# Check image dependencies and populate _build_order, _required_builder and _required_engines. Recursive.
#
# Arguments:
#
# 1: image_id
# 2: previous_image_id
function check_image_dependencies() {
    local image_id previous_image
    image_id="$1"
    previous_image="$2"
    expand_image_id "${image_id}" "${_IMAGE_PATH}"
    if [ "${image_id}" != "scratch" ]; then
        # shellcheck disable=SC2154
        source_image_conf "${__expand_image_id}"

        # collect required engines
        ! string_has_word "${_required_engines}" "${BUILD_ENGINE}" && _required_engines+=" ${BUILD_ENGINE}"

        # collect required build containers
        if [[ ! -z "${BUILDER}" ]];then
             ! string_has_word "${_required_builder}" "${BUILDER}" && _required_builder+=" ${BUILDER}"
        else
            # add default build container of current namespace
            ! string_has_word "${_required_builder}" "${DEFAULT_BUILDER}" && _required_builder+=" ${DEFAULT_BUILDER}"
        fi

        if [[ ! -z "${IMAGE_PARENT}" ]]; then
            # skip further checking if already processed
            if ! string_has_word "${_build_order}" "${image_id}"; then
                # check parent image dependencies
                check_image_dependencies "${IMAGE_PARENT}" "${image_id}"
                # finally add the image
                [[ "${previous_image}" != "" ]] && _build_order+=" ${image_id}"
            fi
        fi
    fi
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
    [[ ! -z "${STAGE3_BASE}" ]] && ! string_has_word "${_required_cores}" "${STAGE3_BASE}" \
        && _required_cores+=" ${STAGE3_BASE}"
    # skip further checking if already processed
    if ! string_has_word "${_build_order_builder}" "${builder_id}"; then
        # check parent if this is not a stage3 builder
        [[ -z "${STAGE3_BASE}" ]] && check_builder_dependencies "${BUILDER}" "${builder_id}"
        # finally add the builder
        [[ ! -z "${previous_builder_id}" ]] && _build_order_builder+=" ${builder_id}"
    fi
}

function main() {
    local target_id build_type engine_id engines builder_id builders image_id images bob_var

    cd "${_NAMESPACE_DIR}" || die "Failed to change dir to ${_NAMESPACE_DIR}"

    # shellcheck disable=SC2154
    [[ "${_arg_verbose_build}" == 'off' ]] && BOB_EMERGE_DEFAULT_OPTS="${BOB_EMERGE_DEFAULT_OPTS} --quiet-build"

    # --interactive build
    # shellcheck disable=SC2154
    if [[ "${_arg_interactive}" == 'on' ]]; then
        # shellcheck disable=SC2034
        BOB_IS_INTERACTIVE='true'
        # shellcheck disable=SC2154
        target_id="${_arg_target_id}"
        [[ "${target_id}" == "*" ]] && die "--interactive does not support wildcards, only fully qualified ids."
        if [[ "${target_id}" != *"/"*  ]]; then
            if [[ -n "${_NAMESPACE_DEFAULT}" ]]; then
                target_id="${_NAMESPACE_DEFAULT}/${target_id}"
            else
                die "--interactive expects an image, but only got a namespace."
            fi
        fi
        build_type="${_IMAGE_PATH}"
        expand_image_id "${target_id}" "${build_type}"
        if [[ ! -d "${__expand_image_id}" ]]; then
            expand_image_id "${target_id}" "${_BUILDER_PATH}"
            [[ ! -d "${__expand_image_id}" ]] && die "Couldn't find image or builder ${target_id}"
            build_type="${_BUILDER_PATH}"
        fi
        source_image_conf "${__expand_image_id}"

        get_build_container "${target_id}" "${build_type}"
        [[ $? -eq 1 ]] && die "Error while executing get_build_container(): ${builder_id}"
        builder_id="${__get_build_container}"

        image_exists "${builder_id}" || die "Couldn't find image ${builder_id}"

        BOB_CURRENT_TARGET="${target_id}"

        # pass variables starting with BOB_ to build container as ENV
        for bob_var in ${!BOB_*}; do
            _container_env+=("${bob_var}=${!bob_var}")
        done

        generate_dockerfile "${__expand_image_id}"

        get_absolute_path "${__expand_image_id}"
        _container_mounts=(
            "${_KUBLER_DIR}/tmp/distfiles:/distfiles"
            "${_KUBLER_DIR}/tmp/packages:/packages"
            "${_KUBLER_DIR}/tmp/oci-registry:/oci-registry"
            "${__get_absolute_path}:/config"
        )
        _container_mount_portage='true'
        _container_cmd=('/bin/bash')

        msg "using: ${BUILD_ENGINE} / builder: ${builder_id}"
        msg "\\nRunning interactive build container with ${_NAMESPACE_DIR}/${__expand_image_id} mounted as /config"
        msg "Artifacts from previous builds: /backup-rootfs\\n"
        msg "You may run any helper function available in your image's build.sh, like update_use, etc."
        msg "Once you are finished tinkering, history | cut -c 8- may prove useful ;)\\n"
        msg "To start the build:\\n"
        msg "    $ kubler-build-root \\n\\nNote: Starting a build twice in the same container is not recommended\\n"
        msg "Search packages: eix <search-string> / Check use flags: emerge -pv <package-atom>\\n"

        run_image "${builder_id}" "${builder_id}" 'true'
        exit $?
    fi

    # --no-deps build
    # shellcheck disable=SC2154
    if [[ "${_arg_no_deps}" == 'on' ]]; then
        for image_id in "${_arg_target_id[@]}"; do
            [[ "${image_id}" == "*" ]] && die "--no-deps does not support wildcards, only fully qualified ids."
            if [[ "${image_id}" != *"/"*  ]]; then
                if [[ -n "${_NAMESPACE_DEFAULT}" ]]; then
                    image_id="${_NAMESPACE_DEFAULT}/${image_id}"
                else
                    die "--no-deps expects a fully qualified image_id, but only got namespace \"${image_id}\""
                fi
            fi
            expand_image_id "${image_id}" "${_IMAGE_PATH}"
            source_image_conf "${__expand_image_id}"
            validate_image "${image_id}" "${_IMAGE_PATH}"
            build_image_no_deps "${image_id}"
        done
        exit $?
    fi

    msg "*** generate build order"

    expand_requested_target_ids "${_arg_target_id[@]}"
    # shellcheck disable=SC2154
    generate_build_order "${__expand_requested_target_ids}"
    msgf "required engines:" "${_required_engines:1}"
    msgf "required stage3:" "${_required_cores:1}"
    msgf "required builders:" "${_build_order_builder}"
    msgf "build sequence:" "${_build_order}"
    [[ -n ${_arg_exclude} ]] && msgf "excluded:" "${_arg_exclude[@]}"

    IFS=" " read -r -a engines <<< "${_required_engines}"
    for engine_id in "${engines[@]}"; do
       # shellcheck source=lib/engine/docker.sh
       source "${_LIB_DIR}/engine/${engine_id}.sh"
       validate_engine
    done

    msg "*** gogo!"

    IFS=" " read -r -a builders <<< "${_build_order_builder}"
    for builder_id in "${builders[@]}"; do
        expand_image_id "${builder_id}" "${_BUILDER_PATH}"
        source_image_conf "${__expand_image_id}"
        validate_image "${builder_id}" "${_BUILDER_PATH}"
        build_builder "${builder_id}"
    done

    IFS=" " read -r -a images <<< "${_build_order}"
    for image_id in "${images[@]}"; do
        expand_image_id "${image_id}" "${_IMAGE_PATH}"
        source_image_conf "${__expand_image_id}"
        validate_image "${image_id}" "${_IMAGE_PATH}"
        build_image "${image_id}"
    done
}

main "$@"
