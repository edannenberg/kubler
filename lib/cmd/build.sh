#!/usr/bin/env bash

_required_binaries=" bzip2 grep id wget"
[[ "${_arg_skip_gpg_check}" != "on" ]] && _required_binaries+=" gpg"
[[ $(command -v sha512sum) ]] && _required_binaries+=" sha512sum" || _required_binaries+=" shasum"

# Populate _build_order and _build_order_builder by checking image dependencies
#
# Arguments:
#
# 1: images
function generate_build_order()
{
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
            ! string_has_word "${_build_order}" ${image_id} && _build_order+=" ${image_id}"
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
    for excluded_image in "${_arg_exclude[@]}";do
        _build_order="${_build_order/${excluded_image}/}"
    done
    read _build_order <<< ${_build_order}
}

# Check image dependencies and populate _build_order, _required_builder and _required_engines. Recursive.
#
# Arguments:
#
# 1: image_id
# 2: previous_image_id
function check_image_dependencies()
{
    local image_id previous_image
    image_id="$1"
    previous_image="$2"
    expand_image_id "${image_id}" "${_IMAGE_PATH}"
    if [ "${image_id}" != "scratch" ]; then
        source_image_conf "${__expand_image_id}"

        # collect required engines
        ! string_has_word "${_required_engines}" "${CONTAINER_ENGINE}" && _required_engines+=" ${CONTAINER_ENGINE}"

        # collect required build containers
        if [[ ! -z "${BUILDER}" ]];then
             ! string_has_word "${_required_builder}" "${BUILDER}" && _required_builder+=" ${BUILDER}"
        else
            # add default build container of current namespace
            ! string_has_word "${_required_builder}" "${DEFAULT_BUILDER}" && _required_builder+=" ${DEFAULT_BUILDER}"
        fi

        if [[ ! -z "${IMAGE_PARENT}" ]]; then
            # skip further checking if already processed
            if ! string_has_word "${_build_order}" ${image_id}; then
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
function check_builder_dependencies()
{
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

function main()
{
    local engine_id engines builder_id builders image_id images bob_var
    cd "${_script_dir}/${_NAMESPACE_PATH}"

    # --interactive build
    if [[ "${_arg_interactive}" == "on" ]]; then
        [[ "${_arg_target_id}" == "*" ]] && die "Error, --interactive does not support wildcards, only co."
        [[ "${_arg_target_id}" != *"/"*  ]] && die "Error, --interactive expects an image, but only got a namespace."
        expand_image_id "${_arg_target_id}" "${_IMAGE_PATH}"
        source_image_conf "${__expand_image_id}"

        get_build_container "${_arg_target_id}" "${_IMAGE_PATH}"
        [[ $? -eq 1 ]] && die "Error while executing get_build_container(): ${builder_id}"
        builder_id="${__get_build_container}"

        image_exists "${builder_id}" "${_IMAGE_PATH}" || die "Error couldn't find image ${builder_id}"

        # pass variables starting with BOB_ to build container as ENV
        for bob_var in ${!BOB_*}; do
            _container_env+=("${bob_var}=${!bob_var}")
        done

        generate_dockerfile "${__expand_image_id}"

        _container_mounts=(
            "${_script_dir}/tmp/distfiles:/distfiles"
            "${_script_dir}/tmp/packages:/packages"
            "${_script_dir}/tmp/oci-registry:/oci-registry"
            "$(realpath ${__expand_image_id}):/config"
        )
        _container_mount_portage="true"
        _container_cmd=("/bin/bash")

        msg "using: ${CONTAINER_ENGINE} / builder: ${builder_id}"
        echo -e "\nrunning interactive build container with ${__expand_image_id} mounted as /config\nartifacts from previous builds: /backup-rootfs\n"
        echo -e "to start the build: $ build-root ${_arg_target_id}"
        echo -e "*** if you plan to run emerge manually, source /etc/profile first ***\n"

        run_image "${builder_id}" "${builder_id}" "true"
        exit $?
    fi

    # --no-deps build
    if [[ "${_arg_no_deps}" == "on" ]]; then
        for image_id in "${_arg_target_id[@]}"; do
            [[ "${image_id}" == "*" ]] && die "Error, --no-deps does not support wildcards, specify one or more image names."
            expand_image_id "${image_id}" "${_IMAGE_PATH}"
            source_image_conf "${__expand_image_id}"
            validate_image "${image_id}" "${_IMAGE_PATH}"
            build_image_no_deps "${image_id}"
        done
        exit $?
    fi

    msg "*** generate build order"

    expand_requested_target_ids "${_arg_target_id[@]}"
    generate_build_order "${__expand_requested_target_ids}"
    msgf "required engines:" "${_required_engines:1}"
    msgf "required stage3:" "${_required_cores:1}"
    msgf "required builders:" "${_build_order_builder}"
    msgf "build sequence:" "${_build_order}"
    [[ -n ${_arg_exclude} ]] && msgf "excluded:" "${_arg_exclude[@]}"

    engines=($_required_engines)
    for engine_id in "${engines[@]}"; do
       source "${_script_dir}/lib/engine/${engine_id}.sh"
       validate_engine
    done

    msg "*** gogo!"

    builders=($_build_order_builder)
    for builder_id in "${builders[@]}"; do
        expand_image_id "${builder_id}" "${_BUILDER_PATH}"
        source_image_conf "${__expand_image_id}"
        validate_image "${builder_id}" "${_BUILDER_PATH}"
        build_builder "${builder_id}"
    done

    images=($_build_order)
    for image_id in "${images[@]}"; do
        expand_image_id "${image_id}" "${_IMAGE_PATH}"
        source_image_conf "${__expand_image_id}"
        validate_image "${image_id}" "${_IMAGE_PATH}"
        build_image "${image_id}"
    done
}

main "$@"
