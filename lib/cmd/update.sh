#!/usr/bin/env bash
# Copyright (c) 2014-2017, Erik Dannenberg <erik.dannenberg@xtrade-gmbh.de>
# All rights reserved.

# Compare given local and remote stage3 date, returns 0 if remote is newer or 1 if not
#
# Arguments:
# 1: stage3_date_local
# 2: stage3_date_remote
function is_newer_stage3_date {
    local stage3_date_local stage3_date_remote
    # parsing ISO8601 with the date command is a bit tricky due to differences on macOS
    # as a workaround we just remove any possible non-numeric chars and compare as integers
    stage3_date_local="${1//[!0-9]/}"
    stage3_date_remote="${2//[!0-9]/}"
    if [[ "${stage3_date_local}" -lt "${stage3_date_remote}" ]]; then
        return 0
    else
        return 1
    fi
}

# Arguments:
# 1: namespace_id
# 2: builder_path
function update_builders() {
    __update_builders=
    local builder_path current_ns current_builder update_status s3date_remote update_count
    current_ns="$1"
    builder_path="$2"
    update_count=0
    if [[ -d "${builder_path}" ]]; then
        cd "${builder_path}" || die "Failed to change dir to ${builder_path}"
        for current_builder in */; do
            update_status=
            cd "${_NAMESPACE_DIR}" || die "Failed to change dir to ${_NAMESPACE_DIR}"
            source_image_conf "${current_ns}/${_BUILDER_PATH}/${current_builder}"
            if [[ -n "${STAGE3_BASE}" ]]; then
                fetch_stage3_archive_name || die "Couldn't find a stage3 file for ${ARCH_URL}"
                get_stage3_archive_regex "${STAGE3_BASE}"
                # shellcheck disable=SC2154
                if [[ "${__fetch_stage3_archive_name}" =~ ${__get_stage3_archive_regex} ]]; then
                    s3date_remote="${BASH_REMATCH[1]}"
                    # add time string if captured
                    [[ -n "${BASH_REMATCH[2]}" ]] && s3date_remote+="${BASH_REMATCH[2]}"
                    if is_newer_stage3_date "${STAGE3_DATE}" "${s3date_remote}"; then
                        sed -r -i s/^STAGE3_DATE=\(\"\|\'\)?[0-9]*\(T[0-9]*Z\)?\(\"\|\'\)?/STAGE3_DATE=\'"${s3date_remote}"\'/g \
                            "${builder_path}${current_builder}build.conf"
                        update_status="updated ${STAGE3_DATE} -> ${s3date_remote} - ${STAGE3_BASE}"
                        ((update_count++))
                    else
                        update_status="up-to-date ${STAGE3_DATE} - ${STAGE3_BASE}"
                    fi
                else
                    update_status="error: couldn't parse remote STAGE3 DATE from ${ARCH_URL}"
                fi
            else
                update_status="n/a - extends ${BUILDER}"
            fi
            msgf "${current_builder}" "${update_status}"
        done
    else
        msg "--> no build containers"
    fi
    __update_builders=${update_count}
}

# Update STAGE3_DATE in build.conf for all builders in all namespaces
function update_stage3_date() {
    local current_ns builder_path
    update_count=0
    cd "${_NAMESPACE_DIR}" || die "Failed to change dir to ${_NAMESPACE_DIR}"
    if [[ "${_NAMESPACE_TYPE}" == 'single' ]]; then
        update_builders "${current_ns}" "${_NAMESPACE_DIR}/${_BUILDER_PATH}"
    else
        for current_ns in */; do
            msg "${current_ns}"
            builder_path="${_NAMESPACE_DIR}/${current_ns}${_BUILDER_PATH}"
            update_count=$((update_count+=__update_builders))
            update_builders "${current_ns}" "${builder_path}"
        done
    fi
    if [[ "${_NAMESPACE_TYPE}" != 'local' ]]; then
        msg "kubler"
        update_builders 'kubler' "${_KUBLER_NAMESPACE_DIR}/kubler/${_BUILDER_PATH}"
        update_count=$((update_count+=__update_builders))
    fi
    if [[ ${update_count} -eq 0 ]]; then
        msg '\nAll stage3 dates are up to date.'
    else
        msg "\\nFound updates for ${update_count} stage3 file(s), to rebuild run:\\n
    ${_KUBLER_BIN}${_KUBLER_BIN_HINT} clean
    ${_KUBLER_BIN}${_KUBLER_BIN_HINT} build -C some_namespace\\n"
    fi
}

# Arguments:
#
# 1: builder_id - optional, default "kubler/bob-musl"
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
    msg "--> run emerge --sync using ${builder_id}"
    run_image "${builder_id}" "portage-sync-worker"
}

function main() {
    # shellcheck disable=SC2154
    if [[ "${_arg_no_sync}" == 'off' ]]; then
        msg "*** sync portage container"
        # shellcheck disable=SC2154
        update_portage "${_arg_builder_image}"
    fi
    msg "*** check for stage3 updates"
    update_stage3_date
}

main "$@"
