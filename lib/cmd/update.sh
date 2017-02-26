#!/usr/bin/env bash

# Update STAGE3_DATE in build.conf for all builders in all namespaces
function update_stage3_date() {
    local current_ns builder_path current_builder update_status remote_files regex s3date_remote update_count
    update_count=0
    cd "${_script_dir}/${_NAMESPACE_PATH}"
    for current_ns in */; do
        msg "${current_ns}"
        builder_path="${_script_dir}/${_NAMESPACE_PATH}/${current_ns}${_BUILDER_PATH}"
        if [[ -d "${builder_path}" ]]; then
            cd "${builder_path}"
            for current_builder in  */; do
                update_status=""
                cd "${_script_dir}/${_NAMESPACE_PATH}"
                source_image_conf "${current_ns}/${_BUILDER_PATH}/${current_builder}"
                if [[ ! -z "${STAGE3_BASE}" ]]; then
                    remote_files="$(wget -qO- "${ARCH_URL}")"
                    regex="${STAGE3_BASE//+/\\+}-([0-9]{8})\.tar\.bz2"
                    if [[ "${remote_files}" =~ ${regex} ]]; then
                        s3date_remote="${BASH_REMATCH[1]}"
                        if [[ "${STAGE3_DATE}" -lt "${s3date_remote}" ]]; then
                            sed -r -i s/^STAGE3_DATE=\"?\{0,1\}[0-9]*\"?/STAGE3_DATE=\"${s3date_remote}\"/g \
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
                    update_status="n/a - extends from ${BUILDER}"
                fi
                msgf "${current_builder}" "${update_status}"
            done
        else
            echo "      no build containers"
        fi
    done
    [[ "${update_count}" -eq 0 ]] && echo "Everything was already up to date. No rebuild required." \
        || echo "Found updates for ${update_count} stage3 file(s), to rebuild run clean and then build -c"
}

# Arguments:
#
# 1: builder_id - optional, default "gentoobb/bob-musl"
function update_portage() {
    local builder_id
    builder_id="${1:-gentoobb/bob-musl}"
    cd "${_script_dir}/${_NAMESPACE_PATH}"
    expand_image_id "${builder_id}" "${_BUILDER_PATH}"
    source_image_conf "${__expand_image_id}"
    image_exists "${builder_id}" || { msg "Error, couldn't find builder: ${builder_id}, skipping"; return 0; }
    # pass variables starting with BOB_ to build container as ENV
    for bob_var in ${!BOB_*}; do
        _container_env+=("${bob_var}=${!bob_var}")
    done
    _container_mount_portage="true"
    _container_cmd=("portage-git-sync")
    msg "--> run emerge --sync using ${builder_id}"
    run_image "${builder_id}" "portage-sync-worker"
}

function main() {
    if [[ "${_arg_no_sync}" == "off" ]]; then
        msg "*** sync portage container"
        update_portage "${_arg_builder_image}"
    fi
    msg "*** check for stage3 updates"
    update_stage3_date
}

main "$@"
