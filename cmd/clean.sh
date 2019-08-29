#!/usr/bin/env bash
# Copyright (c) 2014-2019, Erik Dannenberg <erik.dannenberg@xtrade-gmbh.de>
# All rights reserved.

# Arguments:
# n: namespace_dirs - absolute paths
function rm_build_artifacts() {
    local namespace_dirs
    namespace_dirs=( "$@" )
    find -L "${namespace_dirs[@]}" \
        \( -name rootfs.tar -o -name Dockerfile -o -name PACKAGES.md \
           -o -name "${_BUILD_TEST_FAILED_FILE}" -o -name "${_HEALTHCHECK_FAILED_FILE}" \
           -o -name "${_COMPOSE_TEST_FAILED_FILE}" \) -delete
    return $?
}

# Delete all existing Docker images for given namespace_id
#
# Arguments:
# 1: namespace_id
function rm_docker_namespace_images {
    local namespace_id docker_out
    namespace_id="$1"
    [[ "${namespace_id}" != */ ]] && namespace_id="${namespace_id}/"
    namespace_id="${namespace_id}*"
    docker_out="$("${DOCKER}" images "${namespace_id}" -q)"
    # shellcheck disable=SC2086
    [[ -n "${docker_out}" ]] && "${DOCKER}" rmi -f ${docker_out}
    return $?
}

function main() {
    local namespace_dirs ns_dir ns_id
    namespace_dirs=( "${_NAMESPACE_DIR}" )
    [[ "${_NAMESPACE_TYPE}" != 'local' ]] && namespace_dirs+=( "${_KUBLER_NAMESPACE_DIR}" )

    # shellcheck disable=SC2154
    [[ "${_arg_nuke_from_orbit}" == 'on' ]] && \
        _arg_build_artifacts='on' && _arg_prune_dangling_images='on' && _arg_all_images='on' && _arg_build_artifacts='on'

    # use -b as default if nothing else was passed
    [[ "${_arg_build_artifacts}" == 'off' && "${_arg_prune_dangling_images}" == 'off' \
        && "${_arg_all_images}" == 'off' && "${#_arg_image_ns[@]}" -eq 0 ]] && _arg_build_artifacts='on'

    if [[ "${_arg_build_artifacts}" == 'on' ]]; then
        add_status_value "build artifacts"
        _status_msg="Delete rootfs.tar, generated Dockerfile and PACKAGES.md files"
        pwrap rm_build_artifacts "${namespace_dirs[@]}" || die
        msg_ok 'done.'
    fi

    if [[ "${_arg_prune_dangling_images}" == 'on' ]]; then
        add_status_value "dangling images"
        source_build_engine 'docker'
        _status_msg="exec docker image prune"
        pwrap "${DOCKER}" image prune -f || die
        _status_msg="exec docker volume prune"
        pwrap "${DOCKER}" volume prune -f || die
        msg_ok 'done.'
    fi

    if [[ "${_arg_all_images}" == 'on' ]]; then
        # -I overrides -i
        _arg_image_ns=()
        for ns_dir in "${namespace_dirs[@]}"; do
            if [[ "${_NAMESPACE_TYPE}" != 'single' || "${ns_dir}" == "${_KUBLER_NAMESPACE_DIR}" ]]; then
                pushd "${ns_dir}" 1> /dev/null || die
                for ns_id in */; do
                    _arg_image_ns+=( "${ns_id}" )
                done
                popd 1> /dev/null || die
            else
                _arg_image_ns+=( "$(basename -- "${ns_dir}")" )
            fi
        done
    fi

    if [[ "${#_arg_image_ns[@]}" -gt 0 ]]; then
        source_build_engine 'docker'
        add_status_value "built images"
        for ns_id in "${_arg_image_ns[@]}"; do
            ns_id="${ns_id%/}"
            _status_msg="exec docker rmi -f ${ns_id}/*"
            pwrap rm_docker_namespace_images "${ns_id}"
        done
        if [[ "${_arg_nuke_from_orbit}" == 'on' ]]; then
            #stop_container "${_PORTAGE_CONTAINER}"
            # shellcheck disable=SC2034
            _status_msg="exec docker container prune"
            pwrap "${DOCKER}" container prune -f || die
            # shellcheck disable=SC2034
            _status_msg="exec docker rmi -f ${_STAGE3_NAMESPACE}/*"
            pwrap rm_docker_namespace_images "${_STAGE3_NAMESPACE}"
        fi
        msg_ok 'done.'
    fi
}

main "$@"
