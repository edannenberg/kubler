#!/usr/bin/env bash

function main() {
    local image_id current_ns
    cd "${_NAMESPACE_PATH}"

    expand_requested_target_ids "${_arg_target_id[@]}"

    msg "--> push: ${__expand_requested_target_ids:1}"
    for image_id in ${__expand_requested_target_ids}; do
        current_ns="${image_id%%/*}"
        expand_image_id "${image_id}" "${_IMAGE_PATH}"

        source_image_conf "${__expand_image_id}"
        source_push_conf "${image_id}"

        if ! image_exists "${image_id}"; then
            echo "--> skipping ${image_id}:${IMAGE_TAG}, image is not build yet"
            continue
        fi

        if [[ "${_last_push_auth_ns}" != ${current_ns} ]]; then
            push_auth "${current_ns}" "${_arg_registry_url}" || die "Error while logging into registry"
            _last_push_auth_ns=${current_ns}
        fi

        push_image "${image_id}" "${_arg_registry_url}"
    done
}

main "$@"
