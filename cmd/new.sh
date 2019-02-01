#!/usr/bin/env bash
# Copyright (c) 2014-2019, Erik Dannenberg <erik.dannenberg@xtrade-gmbh.de>
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
    local ns_name ns_dir ns_type ns_engine regex kubler_bin_hint real_ns_dir default_conf
    ns_name="$1"
    [[ "${ns_name}" == 'kubler' ]] && die "\"kubler\" is a reserved namespace, aborting."
    ns_dir="${_NAMESPACE_DIR}/${ns_name}"
    real_ns_dir="${ns_dir}"
    get_absolute_path "${ns_dir}"
    # shellcheck disable=SC2154
    ns_dir="${__get_absolute_path}"
    [[ -e "${ns_dir}" ]] && die "${ns_dir} already exists, aborting."
    [[ "${_NAMESPACE_TYPE}" == 'single' ]] && die "${_NAMESPACE_DIR} namespace is of type single, aborting."

    local def_author def_mail def_engine
    def_author='John Doe'
    def_mail='john@doe.net'
    def_engine='docker'

    # use author and engine from kubler.conf/env as defaults if avail.
    regex='(.+)\s<(.+)>'
    [[ "${AUTHOR}" =~ $regex ]] && def_author="${BASH_REMATCH[1]}" && def_mail="${BASH_REMATCH[2]}"
    [[ -n "${BUILD_ENGINE}" ]] && def_engine="${BUILD_ENGINE}"

    msg_info_sub
    msg_info_sub '<enter> to accept default value'
    msg_info_sub

    if [[ "${_NAMESPACE_TYPE}" == 'none' ]]; then
        msg_info_sub "Working dir type? Choices:"
        msg_info_sub "  single - You can't add further namespaces to the created working dir, it only holds images"
        msg_info_sub "  multi  - Creates a working dir that can hold multiple namespaces"
        ask 'Type' 'single'
        # shellcheck disable=SC2154
        ns_type="${__ask}"
        add_template_filter_var '_tmpl_ns_type' "${ns_type}"

        [[ "${ns_type}" != 'single' && "${ns_type}" != 'multi' ]] && die "Unknown type: \"${ns_type}\""

        if [[ "${_NAMESPACE_TYPE}" == 'none' && "${ns_type}" == 'multi' ]]; then
            msg_info_sub
            msg_info_sub "Top level directory name for new namespace '${ns_name}'? The directory is created at ${_NAMESPACE_DIR}/"
            ask 'Namespaces Dir' 'kubler-images'
            ns_dir="${_NAMESPACE_DIR}/${__ask}"
            [[ -e "${ns_dir}" ]] && die "Directory ${ns_dir} already exists, aborting. If you intended to create the new namespace at this location use: \\n
    ${_KUBLER_BIN} --working-dir=${ns_dir} new namespace ${ns_name}"
            real_ns_dir="${ns_dir}/${ns_name}"
        fi

        msg_info_sub
        msg_info "Initial image tag, a.k.a. version?"
        ask 'Image Tag' "${_TODAY}"
        add_template_filter_var '_tmpl_image_tag' "${__ask}"
        add_template_sed_replace '^IMAGE_TAG' '#IMAGE_TAG'
        msg_info_sub
    else
        msg_info_sub
        msg_warn "Namespace Type:          ${_NAMESPACE_TYPE}"
    fi

    msg_warn "New namespace location:  ${real_ns_dir}"
    msg_info_sub

    msg_info 'Who maintains the new namespace?'
    ask 'Name' "${def_author}"
    add_template_filter_var '_tmpl_author' "${__ask}"

    ask 'EMail' "${def_mail}"
    add_template_filter_var '_tmpl_author_email' "${__ask}"
    msg_info_sub

    msg_info 'Used build engine?'
    ask 'Engine' "${def_engine}"
    ns_engine="${__ask}"
    add_template_filter_var '_tmpl_engine' "${ns_engine}"

    [[ ! -f "${_KUBLER_DIR}/engine/${ns_engine}.sh" ]] && die "Unknown engine: ${ns_engine}"

    [[ "${_NAMESPACE_TYPE}" == 'none' && "${ns_type}" == 'multi' ]] && mkdir "${ns_dir}"

    cp -r "${_KUBLER_DIR}/template/${ns_engine}/namespace" "${real_ns_dir}" || die

    kubler_bin_hint="${_KUBLER_BIN}${_KUBLER_BIN_HINT}"
    if [[ "${_NAMESPACE_TYPE}" == 'none' ]]; then
        if [[ "${ns_type}" == 'multi' ]]; then
            mv "${real_ns_dir}/${_KUBLER_CONF}.single" "${real_ns_dir}/${_KUBLER_CONF}"
        else
            rm "${real_ns_dir}/${_KUBLER_CONF}.single"
        fi
        # default multi conf file can also be used for new single namespaces..
        default_conf='multi'
        if [[ -z "${_KUBLER_BIN_HINT}" ]];then
            kubler_bin_hint="cd ${ns_dir}\\n    $ ${kubler_bin_hint}"
        else
            kubler_bin_hint="${_KUBLER_BIN} --working-dir ${ns_dir}"
        fi
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

    msg_info_sub
    msg_ok "Successfully created \"${ns_name}\" namespace at ${ns_dir}"
    msg_info_sub
    msg_warn "Configuration file: ${real_ns_dir}/${_KUBLER_CONF}"
    msg_info_sub
    msg_warn "To manage the new namespace with GIT you may want to run:"
    msg_info_sub
    msg_info_sub "$ git init ${real_ns_dir}"
    msg_info_sub
    msg_warn "To create images in the new namespace run:"
    msg_info_sub
    msg_info_sub "$ ${kubler_bin_hint} new image ${ns_name}/<image_name>"
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

    [ -e "${image_path}" ] && die "${image_path} already exists, aborting!"
    [ ! -d "${image_base_path}" ] && mkdir -p "${image_base_path}"

    __init_image_base_dir="${image_path}"
}

# Arguments
# 1: namespace
# 2: image_name
function add_image() {
    local namespace image_name image_parent image_builder image_path test_type
    namespace="$1"
    image_name="$2"

    msg_info_sub
    msg_info_sub '<enter> to accept default value'
    msg_info_sub
    msg_info_sub 'Extend an existing Kubler managed image? Fully qualified image id (i.e. kubler/busybox) or scratch'
    ask 'Parent Image' 'scratch'
    image_parent="${__ask}"

    image_builder="${DEFAULT_BUILDER}"
    if [[ "${image_parent}" == 'scratch' ]]; then
        msg_info_sub
        msg_info_sub "Which builder should be used? Press <enter> to use the default builder of namespace ${namespace}"
        ask 'Builder Id' "${DEFAULT_BUILDER}"
        image_builder="${__ask}"
        [[ "${target_id}" != *"/"* ]] && die "${target_id} should have format <namespace>/<builder_name>"
        [[ "${image_builder}" != "${DEFAULT_BUILDER}" ]] && add_template_sed_replace '^#BUILDER=' 'BUILDER='
    elif [[ "${image_parent}" != *"/"* || "${image_parent}" == *"/" ]]; then
        die "\"${image_parent}\" should have format <namespace>/<image_name>"
    fi

    if [[ "${BUILD_ENGINE}" == 'docker' ]]; then
        msg_info_sub
        msg_info_sub 'Add templates for tests? Possible choices:'
        msg_info_sub "  hc  - Add a stub for Docker's HEALTH-CHECK, recommended for images that run daemons"
        msg_info_sub '  bt  - Add a stub for a custom build-test.sh script, a good choice if HEALTH-CHECK is not suitable'
        msg_info_sub '  yes - Add stubs for both test types'
        msg_info_sub '  no  - :('
        ask 'Tests' 'hc'
        test_type="${__ask}"
        [[ "${test_type}" != 'hc' && "${test_type}" != 'bt' && "${test_type}" != 'yes' && "${test_type}" != 'no' ]] \
            && die "'${test_type}' is not a valid choice."
        if [[ "${test_type}" == 'bt' || "${test_type}" == 'no' ]]; then
            add_template_sed_replace '^HEALTHCHECK ' '#HEALTHCHECK '
            add_template_sed_replace '^POST_BUILD_HC=' '#POST_BUILD_HC='
        fi
    fi

    init_image_base_dir "${namespace}" "${image_name}" "${_IMAGE_PATH}"
    image_path="${__init_image_base_dir}"

    cp -r "${_KUBLER_DIR}/template/${BUILD_ENGINE}/image" "${image_path}" || die

    add_template_filter_var '_tmpl_image_parent' "${image_parent}"
    add_template_filter_var '_tmpl_image_builder' "${image_builder}"

    replace_template_placeholders "${image_path}"

    local hc_test_file bt_test_file
    hc_test_file="${image_path}"/docker-healthcheck.sh
    bt_test_file="${image_path}"/build-test.sh
    case "${test_type}" in
        hc)
            rm "${bt_test_file}"
            chmod +x "${hc_test_file}"
            ;;
        bt)
            rm "${hc_test_file}"
            chmod +x "${bt_test_file}"
            ;;
        no)
            rm "${hc_test_file}" "${bt_test_file}"
            ;;
        yes)
            chmod +x "${hc_test_file}" "${bt_test_file}"
            ;;
    esac

    msg_info_sub
    msg_ok "Successfully created new image at ${image_path}"
    msg_info_sub
}

# Arguments
# 1: namespace
# 2: builder_name
function add_builder() {
    local namespace builder_name builder_parent builder_path is_stage3_builder
    namespace="$1"
    builder_name="$2"

    msg_info_sub
    msg_info_sub '<enter> to accept default value'
    msg_info_sub
    msg_info_sub 'Extend existing Kubler builder image? Fully qualified image id (i.e. kubler/bob) or stage3'
    ask 'Parent Image' 'stage3'
    builder_parent="${__ask}"

    # shellcheck disable=SC2016,SC2034
    if [[ "${builder_parent}" == "stage3" ]]; then
        builder_parent='\${NAMESPACE}/bob'
        add_template_sed_replace '^BUILDER' '#BUILDER'
        is_stage3_builder='true'
    else
        [[ "${builder_parent}" != *"/"* || "${builder_parent}" == *"/" ]] \
            && die "\"${builder_parent}\" should have format <namespace>/<image_name>"
        add_template_sed_replace '^STAGE3' '#STAGE3'
    fi

    init_image_base_dir "${namespace}" "${builder_name}" "${_BUILDER_PATH}"
    builder_path="${__init_image_base_dir}"

    cp -r "${_KUBLER_DIR}/template/${BUILD_ENGINE}/builder" "${builder_path}" || die

    local build_sh_use build_sh_rm
    build_sh_use='build_ext.sh'
    build_sh_rm='build_stage3.sh'
    if [[ "${is_stage3_builder}" == 'true' ]]; then
        build_sh_use='build_stage3.sh'
        build_sh_rm='build_ext.sh'
    fi
    [[ -f "${builder_path}"/"${build_sh_use}" ]] && mv "${builder_path}"/"${build_sh_use}" "${builder_path}"/build.sh
    [[ -f "${builder_path}"/"${build_sh_rm}" ]] && rm "${builder_path}"/"${build_sh_rm}"

    add_template_filter_var '_tmpl_builder' "${builder_parent}"
    replace_template_placeholders "${builder_path}"

    msg_info_sub
    msg_ok "Successfully created new builder at ${builder_path}"
    msg_info_sub
    if [[ -n "${is_stage3_builder}" ]]; then
        msg_warn "Configure the STAGE3_BASE in ${builder_path}/build.conf then run:"
        msg_info_sub
        msg_info_sub "$ ${_KUBLER_BIN}${_KUBLER_BIN_HINT} update"
        msg_info_sub
    fi
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

    [[ "${target_id}" =~ [A-Z] ]] \
            && die "Invalid ${_arg_template_type} name '${target_id}', should be lower case only."

    if [[ "${_arg_template_type}" != 'namespace' ]]; then
        [[ "${target_id}" != *"/"* || "${target_id}" == *"/" ]] \
            && die "\"${target_id}\" should have format <namespace>/<image_name>"
        [[ "${_NAMESPACE_TYPE}" == 'none' ]] \
            && die "${_NAMESPACE_DIR} is not a valid Kubler namespace dir"
    fi

    add_template_filter_var '_tmpl_namespace' "${target_namespace}"

    if [[ "${_arg_template_type}" == 'image' || "${_arg_template_type}" == 'builder' ]]; then
        get_ns_include_path "${target_namespace}"
        # shellcheck disable=SC2154
        source_namespace_conf "${__get_ns_include_path}"
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
