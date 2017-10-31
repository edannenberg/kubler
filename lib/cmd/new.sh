#!/usr/bin/env bash
# Copyright (c) 2014-2017, Erik Dannenberg <erik.dannenberg@xtrade-gmbh.de>
# All rights reserved.

# Adds given var_name and it's replacement to global assoc. array _template_values
#
# Arguments:
# 1: var_name
# 2: replacement
function add_template_filter_var() {
    local var_name replacement
    var_name="$1"
    replacement="$2"
    _template_values["${var_name}"]="${replacement}"
}

# Adds given match and replacement to global assoc. array _template_sed_args.
#
# Arguments:
# 1: match
# 2: replacement
function add_template_sed_replace() {
    local match replacement
    match="$1"
    replacement="$2"
    _template_sed_args+=('-e' "s|${match}|${replacement}|g")
}

# Replace all keys of global assoc. array _template_values with theirs respective values for each file in given
# target_dir(s)
#
# Arguments:
# n: target_dir
function replace_template_placeholders() {
    local target_dirs var_name tmpl_file
    IFS=" " read -r -a target_dirs <<< "$@"

    for var_name in "${!_template_values[@]}"; do
        add_template_sed_replace "\${${var_name}}" "${_template_values[$var_name]}"
    done
    for tmpl_file in "${target_dirs[@]}"/*; do
        [[ -f "${tmpl_file}" ]] && replace_in_file "${tmpl_file}" _template_sed_args[@]
    done
}

# Arguments:
# 1: ns_name
function add_namespace() {
    local ns_name ns_dir ns_type ns_engine regex
    ns_name="$1"
    ns_dir="${_NAMESPACE_DIR}/${ns_name}"
    get_absolute_path "${ns_dir}"
    # shellcheck disable=SC2154
    ns_dir="${__get_absolute_path}"
    [[ -d "${ns_dir}" ]] && die "${ns_dir} already exists, aborting."
    [[ "${_NAMESPACE_TYPE}" == 'single' ]] && die "${_NAMESPACE_DIR} namespace is of type single, aborting."

    local def_author def_mail def_engine
    def_author='John Doe'
    def_mail='john@doe.net'
    def_engine='docker'

    # use author and engine from kubler.conf/env as defaults if avail.
    regex='(.+)\s<(.+)>'
    [[ "${AUTHOR}" =~ $regex ]] && def_author="${BASH_REMATCH[1]}" && def_mail="${BASH_REMATCH[2]}"
    [[ -n "${BUILD_ENGINE}" ]] && def_engine="${BUILD_ENGINE}"

    msg '\n<enter> to accept default value\n'

    msg "New namespace location:  ${ns_dir}"

    if [[ "${_NAMESPACE_TYPE}" == 'none' ]]; then
        msg "--> What type of namespace? To allow multiple namespaces choose 'multi', else 'single'.
    The only upshot of 'single' mode is saving one directory level, the downside is loss of cross-namespace access."
        ask 'Type' 'multi'
        # shellcheck disable=SC2154
        ns_type="${__ask}"
        add_template_filter_var '_tmpl_ns_type' "${ns_type}"

        [[ "${ns_type}" != 'single' && "${ns_type}" != 'multi' ]] && die "\\nUnknown type: \"${ns_type}\""

        msg "--> Initial image tag, a.k.a. version?"
        ask 'Image Tag' "${_TODAY}"
        add_template_filter_var '_tmpl_image_tag' "${__ask}"
    else
        msg "Namespace Type:          ${_NAMESPACE_TYPE}"
    fi

    msg '\n--> Who maintains the new namespace?'
    ask 'Name' "${def_author}"
    add_template_filter_var '_tmpl_author' "${__ask}"

    ask 'EMail' "${def_mail}"
    add_template_filter_var '_tmpl_author_email' "${__ask}"

    msg '--> What type of images would you like to build?'
    ask 'Engine' "${def_engine}"
    ns_engine="${__ask}"
    add_template_filter_var '_tmpl_engine' "${ns_engine}"

    [[ ! -f "${_LIB_DIR}/engine/${ns_engine}.sh" ]] && die "\\nUnknown engine: ${ns_engine}"

    local real_ns_dir default_conf
    real_ns_dir="${ns_dir}"
    if [[ "${_NAMESPACE_TYPE}" == 'none' && "${ns_type}" == 'multi' ]]; then
        real_ns_dir="${ns_dir}/${ns_name}"
        mkdir "${ns_dir}"
    fi

    cp -r "${_LIB_DIR}/template/${ns_engine}/namespace" "${real_ns_dir}" || die

    if [[ "${_NAMESPACE_TYPE}" == 'none' ]]; then
        if [[ "${ns_type}" == 'multi' ]]; then
            # link kubler namespace per default for multi namespaces
            ln -s "${_KUBLER_NAMESPACE_DIR}/kubler" "${ns_dir}"/
            mv "${real_ns_dir}/${_KUBLER_CONF}.single" "${real_ns_dir}/${_KUBLER_CONF}"
        else
            rm "${real_ns_dir}/${_KUBLER_CONF}.single"
        fi
        # default multi conf file can also be used for new single namespaces..
        default_conf='multi'
    else
        # ..else use default single conf file when inside an existing namespace
        default_conf='single'
        rm "${ns_dir}/${_KUBLER_CONF}.multi"
    fi
    mkdir "${real_ns_dir}"/"${_IMAGE_PATH}"
    mv "${real_ns_dir}/${_KUBLER_CONF}.${default_conf}" "${ns_dir}/${_KUBLER_CONF}"

    replace_template_placeholders "${ns_dir}"
    [[ "${_NAMESPACE_TYPE}" == 'none' && "${ns_type}" == 'multi' ]] && \
        replace_template_placeholders "${real_ns_dir}"

     msg "*** Successfully created \"${ns_name}\" namespace at ${ns_dir}

Configuration file: ${ns_dir}/${_KUBLER_CONF}

To manage the new namespace with GIT you may want to run:

    git init ${real_ns_dir}"

    if [[ "${_NAMESPACE_TYPE}" == 'none' && "${ns_type}" == 'single' ]]; then
        msg "\\n\\n!!! As this is a new single namespace you need to create a new builder first:\\n
    ${_KUBLER_BIN}${_KUBLER_BIN_HINT} new builder ${ns_name}/bob"
    fi

    msg "\\n\\nTo create images in the new namespace run:

    ${_KUBLER_BIN}${_KUBLER_BIN_HINT} new image ${ns_name}/<image_name>
"
}

# Arguments
# 1: namespace
# Return value: absolute path of kubler.conf for given namespace
function get_ns_conf() {
    __get_ns_conf=
    local namespace ns_conf_file
    namespace="$1"

    ns_conf_file="${_NAMESPACE_DIR}/"
    [[ "${_NAMESPACE_TYPE}" != 'single' ]] && ns_conf_file+="${namespace}/"
    ns_conf_file+="${_KUBLER_CONF}"
    [ -f "${ns_conf_file}" ] || die "Couldn't find ${ns_conf_file}

Check spelling of \"${namespace}\" or create a new namespace by running:

    ${_KUBLER_BIN} new namespace ${namespace}
"
    __get_ns_conf="${ns_conf_file}"
}

# Create empty dir for given image and return the absolute path
#
# Arguments:
# 1: namespace
# 2: image_name
# 3: image_type
# Return value: absolute path of created image dir
function init_image_base_dir() {
    __init_image_base_dir=
    local namespace image_name image_type image_base_path image_path
    namespace="$1"
    image_name="$2"
    image_type="$3"

    image_base_path="${_NAMESPACE_DIR}/"
    [[ "${_NAMESPACE_TYPE}" != 'single' ]] && image_base_path+="${namespace}/"
    image_base_path+="${image_type}"
    # not really required, just for the nicer output as // etc are removed
    get_absolute_path "${image_base_path}"
    image_base_path="${__get_absolute_path}"

    image_path="${image_base_path}/${image_name}"

    [ -d "${image_path}" ] && die "${image_path} already exists, aborting!"
    [ ! -d "${image_base_path}" ] && mkdir -p "${image_base_path}"

    __init_image_base_dir="${image_path}"
}

# Arguments
# 1: namespace
# 2: image_name
function add_image() {
    local namespace image_name image_parent image_path
    namespace="$1"
    image_name="$2"

    msg '\n<enter> to accept default value\n'

    msg '--> Extend an existing image? Fully qualified image id (i.e. kubler/busybox) if yes or scratch'
    ask 'Parent Image' 'scratch'
    image_parent="${__ask}"

    init_image_base_dir "${namespace}" "${image_name}" "${_IMAGE_PATH}"
    image_path="${__init_image_base_dir}"

    cp -r "${_LIB_DIR}/template/${BUILD_ENGINE}/image" "${image_path}" || die

    add_template_filter_var '_tmpl_image_parent' "${image_parent}"

    replace_template_placeholders "${image_path}"

    msg "*** Successfully created image \"${image_name}\" in namespace \"${namespace}\" at ${image_path}\\n"
}

# Arguments
# 1: namespace
# 2: builder_name
function add_builder() {
    local namespace builder_name builder_parent builder_path update_hint
    namespace="$1"
    builder_name="$2"

    msg '\n<enter> to accept default value\n'

    msg '--> Extend an existing builder? Fully qualified image id (i.e. kubler/bob) if yes or else stage3'
    ask 'Parent Image' 'stage3'
    builder_parent="${__ask}"

    # shellcheck disable=SC2016,SC2034
    if [[ "${builder_parent}" == "stage3" ]]; then
        builder_parent='\${NAMESPACE}/bob'
        add_template_sed_replace '^BUILDER' '#BUILDER'
        update_hint="You should check for latest stage3 files by running:\\n
    ${_KUBLER_BIN} update --no-sync
        "
    else
        add_template_sed_replace '^STAGE3' '#STAGE3'
    fi

    init_image_base_dir "${namespace}" "${builder_name}" "${_BUILDER_PATH}"
    builder_path="${__init_image_base_dir}"

    cp -r "${_LIB_DIR}/template/${BUILD_ENGINE}/builder" "${builder_path}" || die

    add_template_filter_var '_tmpl_builder' "${builder_parent}"
    replace_template_placeholders "${builder_path}"

    msg "*** Successfully created \"${builder_name}\" builder at ${builder_path}\\n${update_hint}"
}

function main() {
    local target_id target_namespace target_image_name
    declare -A _template_values
    _template_sed_args=()
    # shellcheck disable=SC2154
    target_id="${_arg_name}"

    # shellcheck disable=SC2154
    [[ "${target_id}" != *"/"* && "${_arg_template_type}" != 'namespace' && -n "${_NAMESPACE_DEFAULT}" ]] \
        && target_id="${_NAMESPACE_DEFAULT}/${_arg_name}"

    target_namespace="${target_id%%/*}"
    target_image_name="${target_id##*/}"

    if [[ "${_arg_template_type}" != 'namespace' ]]; then
        [[ "${target_id}" != *"/"* ]] && die "\"${target_id}\" should have format <namespace>/<image_name>"
        [[ "${_NAMESPACE_TYPE}" == 'none' ]] \
            && die "${_NAMESPACE_DIR} is not a valid Kubler namespace dir"
    fi

    add_template_filter_var '_tmpl_namespace' "${target_namespace}"

    if [[ "${_arg_template_type}" == 'image' || "${_arg_template_type}" == 'builder' ]]; then
        get_ns_conf "${target_namespace}"
        # shellcheck source=dock/kubler/kubler.conf
        source "${__get_ns_conf}"
        add_template_filter_var '_tmpl_image_name' "${target_image_name}"
    fi

    case "${_arg_template_type}" in
        namespace)
            add_namespace "${target_id}"
            ;;
        image)
            add_image "${target_namespace}" "${target_image_name}"
            ;;
        builder)
            add_builder "${target_namespace}" "${target_image_name}"
            ;;
        *)
            show_help
            die "Unknown type \"${_arg_template_type}\", should be namespace, builder or image.."
            exit 1
            ;;
    esac
}

main "$@"
