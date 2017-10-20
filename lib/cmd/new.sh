#!/usr/bin/env bash
# Copyright (c) 2014-2017, Erik Dannenberg <erik.dannenberg@xtrade-gmbh.de>
# All rights reserved.

# Arguments:
# 1: Namespace base directory
# 2: Namespace name
# 3: Namespace type
function add_namespace() {
    local ns_base_dir ns_name ns_type ns_dir def_type def_name def_mail def_engine def_mail def_image_tag regex
    ns_base_dir="$1"
    ns_name="$2"
    ns_type="$3"
    ns_dir="${ns_base_dir}/${ns_name}"
    [[ -d "${ns_dir}" ]] && die "${ns_dir} already exists, aborting."
    [[ "${ns_type}" == 'single' ]] && die "${ns_base_dir} namespace is of type single, aborting."

    def_type='multi'
    def_name='John Doe'
    def_mail='john.doe@net'
    def_engine='docker'
    def_image_tag="$(date +%Y%m%d)"

    regex='(.+)\s<(.+)>'
    [[ "${AUTHOR}" =~ $regex ]] && def_name="${BASH_REMATCH[1]}" && def_mail="${BASH_REMATCH[2]}"
    [[ -n "${BUILD_ENGINE}" ]] && def_engine="${BUILD_ENGINE}"

    msg '\n<enter> to accept default value\n'

    msg "New namespace location:  ${ns_dir}"

    if [[ "${ns_type}" == 'none' ]]; then
        msg "--> What type of namespace? To allow multiple namespaces choose 'multi', else 'single'.
    The only upshot of 'single' mode is saving one directory level, the downside is loss of cross-namespace access."
        read -r -p "Type (${def_type}): " _tmpl_ns_type

        [[ -z "${_tmpl_ns_type}" ]] && _tmpl_ns_type="${def_type}"
        [[ "${_tmpl_ns_type}" != 'single' && "${_tmpl_ns_type}" != 'multi' ]] && die "Unknown type, \"${_tmpl_ns_type}\""
        msg "--> Initial image tag, a.k.a. version?"
        read -r -p "Image Tag (${def_image_tag}): " _tmpl_image_tag
        [[ -z "${_tmpl_image_tag}" ]] && _tmpl_image_tag="${def_image_tag}"
    else
        msg "Namespace Type:          ${ns_type}"
    fi

    msg '\n--> Who maintains the new namespace?'
    read -r -p "Name (${def_name}): " _tmpl_author
    [[ -z "${_tmpl_author}" ]] && _tmpl_author="${def_name}"

    read -r -p "EMail (${def_mail}): " _tmpl_author_email
    [[ -z "${_tmpl_author_email}" ]] && _tmpl_author_email="${def_mail}"

    msg '--> What type of images would you like to build?'
    read -r -p "Engine (${def_engine}): " _tmpl_engine
    [[ -z "${_tmpl_engine}" ]] && _tmpl_engine="${def_engine}"

    _tmpl_namespace="${ns_name}"

    [[ ! -f "${_LIB_DIR}/engine/${_tmpl_engine}.sh" ]] && die "\\nUnknown engine: ${_tmpl_engine}"

    local real_ns_dir default_conf
    real_ns_dir="${ns_dir}"

    if [[ "${ns_type}" == 'none' && "${_tmpl_ns_type}" == 'multi' ]]; then
        real_ns_dir="${ns_dir}/${ns_name}"
        mkdir "${ns_dir}"
        _sub_tmpl_target="${real_ns_dir}"
    fi

    cp -r "${_LIB_DIR}/template/${_tmpl_engine}/namespace" "${real_ns_dir}" || die


    if [[ "${ns_type}" == 'none' ]]; then
        if [[ "${_tmpl_ns_type}" == 'multi' ]]; then
            # link kubler namespace per default for multi namespaces
            ln -s "${_KUBLER_NAMESPACE_DIR}/kubler" "${ns_dir}"/
            mv "${real_ns_dir}/${_KUBLER_CONF}.single" "${real_ns_dir}/${_KUBLER_CONF}"
        else
            rm "${real_ns_dir}/${_KUBLER_CONF}.single"
        fi
        mkdir "${real_ns_dir}"/images
        default_conf='multi'
    else
        # ..else use default single conf file when inside an existing top level namespace
        rm "${ns_dir}/${_KUBLER_CONF}.multi"
        default_conf='single'
    fi
    mv "${real_ns_dir}/${_KUBLER_CONF}.${default_conf}" "${ns_dir}/${_KUBLER_CONF}"

    _template_target="${ns_dir}"
    _post_msg="*** Successfully created \"${ns_name}\" namespace at ${ns_dir}

Configuration file: ${ns_dir}/${_KUBLER_CONF}

To manage the new namespace with GIT you may want to run:

    git init ${real_ns_dir}"

    if [[ "${ns_type}" == 'none' && "${_tmpl_ns_type}" == 'single' ]]; then
        _post_msg="${_post_msg}\\n\\n!!! As this is a new single namespace you need to create a new builder first:\\n
    cd ${ns_dir}/
    ${_KUBLER_BIN} new builder bob"
    fi

    _post_msg="${_post_msg}\\n\\nTo create images in the new namespace run:

    cd ${ns_dir}/
    ${_KUBLER_BIN} new image ${ns_name}/<image_name>
"
}

# Arguments
# 1: Namespace
# 2: Image or builder name
function get_ns_conf() {
    __get_ns_conf=
    local ns_name image_name ns_conf_file
    ns_name="$1"
    image_name="$2"

    if [[ -z "${ns_name}" || -z "${image_name}" ]] && [[ "${_NAMESPACE_TYPE}" != 'single' ]]; then
        # shellcheck disable=SC2154
        die "${_arg_name} should have format <namespace>/<image_name>"
    fi

    ns_conf_file="${_NAMESPACE_DIR}/${ns_name}/${_KUBLER_CONF}"
    [ -f "${ns_conf_file}" ] || die "Couldn't read ${ns_conf_file}

You can create a new namespace by running: ${_KUBLER_BIN} new namespace ${ns_name}
"
    __get_ns_conf="${ns_conf_file}"
}

# Arguments
# 1: Namespace
# 2: Build engine used by the namespace
# 3: Image name
function add_image() {
    local ns_name build_engine image_name image_base_path image_path
    ns_name="$1"
    build_engine="$2"
    image_name="$3"

    msg '\n<enter> to accept default value\n'

    msg 'Extend an existing image? Fully qualified image id (i.e. kubler/busybox) if yes or scratch'
    read -r -p 'Parent Image (scratch): ' _tmpl_image_parent
    [ -z "${_tmpl_image_parent}" ] && _tmpl_image_parent='scratch'

    image_base_path="${_NAMESPACE_DIR}/${ns_name}/images"
    image_path="${image_base_path}/${image_name}"

    [ -d "${image_path}" ] && die "${image_path} already exists, aborting!"
    [ ! -d "${image_base_path}" ] && mkdir -p "${image_base_path}"

    cp -r "${_LIB_DIR}/template/${build_engine}/image" "${image_path}" || die

    _template_target="${image_path}"
    _post_msg="Successfully created image \"${image_name}\" in namespace \"${ns_name}\" at ${image_path}\\n"
}


# Arguments
# 1: Namespace
# 2: Build engine used by the namespace
# 3: Builder name
function add_builder() {
    local ns_name build_engine builder_name builder_base_path builder_path
    ns_name="$1"
    build_engine="$2"
    builder_name="$3"

    msg '\n<enter> to accept default value\n'

    msg 'Extend an existing builder? Fully qualified image id (i.e. kubler/bob) if yes or else stage3'
    read -r -p 'Parent Image (stage3): ' _tmpl_builder_type
    [ -z "${_tmpl_builder_type}" ] && _tmpl_builder_type='stage3'

    _tmpl_builder="${_tmpl_builder_type}"
    # shellcheck disable=SC2016,SC2034
    [[ "${_tmpl_builder_type}" == "stage3" ]] && _tmpl_builder='\${_current_namespace}/bob'

    builder_base_path="${_NAMESPACE_DIR}/${ns_name}/builder"
    builder_path="${builder_base_path}/${builder_name}"

    [ -d "${builder_path}" ] && die "${builder_path} already exists, aborting!"
    [ ! -d "${builder_base_path}" ] && mkdir -p "${builder_base_path}"

    cp -r "${_LIB_DIR}/template/${build_engine}/builder" "${builder_path}" || die

    _template_target="${builder_path}"
    _post_msg="Successfully created ${_arg_name} builder at ${builder_path}\\n"
}

function main() {
    local sed_args tmpl_var tmpl_file
    local target_id="${_arg_name}"
    _sub_tmpl_target=
    # shellcheck disable=SC2154
    [[ "${target_id}" != *"/"* && "${_arg_template_type}" != 'namespace' && -n "${_NAMESPACE_DEFAULT}" ]] \
        && target_id="${_NAMESPACE_DEFAULT}/${_arg_name}"
    _tmpl_namespace="${target_id%%/*}"
    _tmpl_image_name="${target_id##*/}"

    case "${_arg_template_type}" in
        namespace)
            add_namespace "${_NAMESPACE_DIR}" "${target_id}" "${_NAMESPACE_TYPE}"
            ;;
        image)
            get_ns_conf "${_tmpl_namespace}" "${_tmpl_image_name}"
            # shellcheck source=dock/kubler/kubler.conf
            source "${__get_ns_conf}"
            add_image "${_tmpl_namespace}" "${BUILD_ENGINE}" "${_tmpl_image_name}"
            ;;
        builder)
            get_ns_conf "${_tmpl_namespace}" "${_tmpl_image_name}"
            # shellcheck source=dock/kubler/kubler.conf
            source "${__get_ns_conf}"
            add_builder "${_tmpl_namespace}" "${BUILD_ENGINE}" "${_tmpl_image_name}"
            ;;
        *)
            show_help
            die "Unknown type \"${_arg_template_type}\", should be namespace, builder or image.."
            exit 1
            ;;
    esac

    # replace placeholder vars in template files with actual values
    sed_args=()
    for tmpl_var in ${!_tmpl_*}; do
        sed_args+=('-e' "s|\${${tmpl_var}}|${!tmpl_var}|g")
    done
    if [[ "${_arg_template_type}" == "builder" ]]; then
        if [[ "${_tmpl_builder_type}" == "stage3" ]]; then
            sed_args+=('-e' "s|^BUILDER|#BUILDER|g")
        else
            sed_args+=('-e' "s|^STAGE3|#STAGE3|g")
        fi
    fi

    target_paths="${_template_target}/*"
    [[ -n "${_sub_tmpl_target}" ]] && target_paths+=" ${_sub_tmpl_target}/*"

    for tmpl_file in ${target_paths}; do
        [[ -f "${tmpl_file}" ]] && replace_in_file "${tmpl_file}" sed_args[@]
    done

    msg "\\n${_post_msg}"
}

main "$@"
