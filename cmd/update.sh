#!/usr/bin/env bash
# Copyright (c) 2014-2019, Erik Dannenberg <erik.dannenberg@xtrade-gmbh.de>
# All rights reserved.

# Arguments:
# 1: namespace_id
# 2: builder_path
function update_builders() {
    __update_builders=
    local builder_path current_ns current_builder update_status s3date_remote update_count max_cap
    current_ns="$1"
    builder_path="$2"
    update_count=0
    add_status_value 'stage3'
    add_status_value "${current_ns}" 'true'
    if [[ -d "${builder_path}" ]] && ! dir_is_empty "${builder_path}"; then
        cd "${builder_path}" || die "Failed to change dir to ${builder_path}"
        for current_builder in */; do
            update_status=
            add_status_value 'stage3'
            add_status_value "${current_ns}" 'true'
            add_status_value "${current_builder::-1}" 'true'
            source_image_conf "${current_ns}/${_BUILDER_PATH}${current_builder}"
            if [[ -n "${STAGE3_BASE}" ]]; then
                fetch_stage3_archive_name || die "Couldn't find a stage3 file for ${ARCH_URL}"
                get_stage3_archive_regex "${STAGE3_BASE}"
                # shellcheck disable=SC2154
                if [[ "${__fetch_stage3_archive_name}" =~ ${__get_stage3_archive_regex} ]]; then
                    max_cap="${#BASH_REMATCH[@]}"
                    s3date_remote="${BASH_REMATCH[$((max_cap-3))]}"
                    # add time string if captured
                    [[ -n "${BASH_REMATCH[$((max_cap-2))]}" ]] && s3date_remote+="${BASH_REMATCH[$((max_cap-2))]}"
                    # shellcheck disable=SC2153
                    if is_newer_stage3_date "${STAGE3_DATE}" "${s3date_remote}"; then
                        sed -E -i'' s/^STAGE3_DATE=\(\"\|\'\)?[0-9]*\(T[0-9]*Z\)?\(\"\|\'\)?/STAGE3_DATE=\'"${s3date_remote}"\'/g \
                            "${builder_path}${current_builder}build.conf"
                        update_status="updated ${STAGE3_DATE} -> ${s3date_remote} - ${STAGE3_BASE}"
                        ((update_count++))
                    else
                        update_status="up-to-date ${STAGE3_DATE} - ${STAGE3_BASE}"
                    fi
                else
                    die "Failed to parse remote STAGE3 DATE from ${ARCH_URL}"
                fi
            else
                update_status="n/a - extends ${BUILDER}"
            fi
            msg_info "${update_status}"
        done
    else
        msg_info "no build containers"
    fi
    __update_builders=${update_count}
}

# Update STAGE3_DATE in build.conf for all builders in all namespaces
function update_stage3_date() {
    local ns_paths current_ns_dir builder_path
    ns_paths=( "${_KUBLER_NAMESPACE_DIR}" )
    [[ "${_NAMESPACE_DIR}" != "${_KUBLER_NAMESPACE_DIR}" && "${_NAMESPACE_TYPE}" != 'single' ]] \
        && ns_paths+=( "${_NAMESPACE_DIR}" )
    update_count=0
    for current_ns_dir in "${ns_paths[@]}"; do
        pushd "${current_ns_dir}" 1> /dev/null || die
        local ns
        for ns in "${current_ns_dir}"/*/; do
            current_ns="$(basename -- "${ns}")"
            add_status_value 'stage3'
            add_status_value "${current_ns}" 'true'
            builder_path="${ns}/${_BUILDER_PATH}"
            update_builders "${current_ns}" "${builder_path}"
            update_count=$((update_count + __update_builders))
        done
        popd 1> /dev/null || die
    done

    if [[ "${_NAMESPACE_TYPE}" == 'single' ]]; then
        current_ns="$(basename -- "${_NAMESPACE_DIR}")"
        add_status_value 'stage3'
        add_status_value "${current_ns}" 'true'
        update_builders "${current_ns}" "${_NAMESPACE_DIR}/${_BUILDER_PATH}"
    fi
    add_status_value "stage3"
    if [[ ${update_count} -eq 0 ]]; then
        msg_ok 'all stage3 dates are up to date.'
    else
        msg_warn "Found updates for ${update_count} stage3 file(s), to rebuild run:\\n
    $ ${_KUBLER_BIN}${_KUBLER_BIN_HINT} clean
    $ ${_KUBLER_BIN}${_KUBLER_BIN_HINT} build -C some_namespace\\n"
    fi
}

# Arguments:
# 1: builder_id - optional, default "kubler/bob"
function update_portage() {
    local builder_id
    builder_id="${1:-${DEFAULT_BUILDER}}"
    cd "${_NAMESPACE_DIR}" || die "Failed to change dir to ${_NAMESPACE_DIR}"
    expand_image_id "${builder_id}" "${_BUILDER_PATH}"
    # shellcheck disable=SC2154
    source_image_conf "${__expand_image_id}"
    image_exists "${builder_id}" \
        || { msg "Warning, skipped sync. Couldn't find a builder image to work with, tried \"${builder_id}\""; return 0; }
    # pass variables starting with BOB_ to build container as ENV
    for bob_var in ${!BOB_*}; do
        _container_env+=("${bob_var}=${!bob_var}")
    done
    # shellcheck disable=SC2034
    _container_mount_portage='true'
    # shellcheck disable=SC2034
    _container_cmd=("portage-git-sync")
    msg_info "run emerge --sync using ${builder_id}"
    run_image "${builder_id}" "portage-sync-worker"
}

function main() {
    # clone kubler-images repo if non-existing and enabled
    if [[ "${KUBLER_DISABLE_KUBLER_NS}" != 'true' ]]; then
        add_status_value 'kubler-images'
        clone_or_update_git_repo "${_KUBLER_NS_GIT_URL}" "${_KUBLER_NAMESPACE_DIR}" 'kubler'
    fi

    # shellcheck disable=SC2154
    if [[ "${KUBLER_PORTAGE_GIT}" == 'true' ]]; then
        add_status_value 'portage'
        msg_info "sync container"
        # shellcheck disable=SC2154
        update_portage "${_arg_builder_image}"
    fi
    add_status_value 'stage3'
    msg_info "check all namespaces for new releases"
    update_stage3_date
}

main "$@"
