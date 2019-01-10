#!/usr/bin/env bash
# Copyright (c) 2014-2019, Erik Dannenberg <erik.dannenberg@xtrade-gmbh.de>
# All rights reserved.

function main() {
    local image_id current_ns
    # shellcheck disable=SC2154
    expand_requested_target_ids "${_arg_target_id[@]}"
    # shellcheck disable=SC2154
    for image_id in "${__expand_requested_target_ids[@]}"; do
        current_ns="${image_id%%/*}"
        expand_image_id "${image_id}" "${_IMAGE_PATH}"
        # shellcheck disable=SC2154
        source_image_conf "${__expand_image_id}"
        source_push_conf "${image_id}"

        if ! image_exists "${image_id}"; then
            add_status_value "${image_id}"
            msg_warn "skipped, image is not build yet."
            continue
        fi

        if [[ "${_last_push_auth_ns}" != "${current_ns}" ]]; then
            # shellcheck disable=SC2154
            push_auth "${current_ns}" "${_arg_registry_url}" || die "Error while logging into registry"
            _last_push_auth_ns="${current_ns}"
        fi

        push_image "${image_id}" "${_arg_registry_url}"
    done
}

main "$@"
