#!/usr/bin/env bash

# Arguments:
# 1: namespace_name
function add_namespace() {
    local namespace_name ns_path
    namespace_name="$1"
    ns_path="./${_NAMESPACE_PATH}/${namespace_name}"
    [[ -d "${ns_path}" ]] && die "${ns_path} already exists, aborting!"

    msg '\n<enter> to accept default value\n'

    msg 'Who maintains the new namespace?'
    read -p 'Name (John Doe): ' _tmpl_author
    [[ -z "${_tmpl_author}" ]] && _tmpl_author='John Doe'

    read -p 'EMail (john@doe.net): ' _tmpl_author_email
    [[ -z "${_tmpl_author_email}" ]] && _tmpl_author_email='john@doe.net'

    msg 'What type of images would you like to build?'
    read -p 'Engine (docker): ' _tmpl_engine
    [[ -z "${_tmpl_engine}" ]] && _tmpl_engine='docker'

    _tmpl_namespace="${_arg_name}"

    [[ ! -f "./lib/engine/${_tmpl_engine}.sh" ]] && die "\nError, unknown engine: ${_tmpl_engine}"

    cp -r "./lib/template/${_tmpl_engine}/namespace" "${ns_path}" || die

    _template_target="${ns_path}"
    _post_msg="Successfully created ${_arg_name} namespace at ./dock/${_arg_name}

If you want to manage the new namespace with git you may want to run:

git init ./${_NAMESPACE_PATH}/${_arg_name}

To add new images run:

${0} new image ${_arg_name}/foo
"
}

function get_ns_conf() {
    __get_ns_conf=
    local ns_conf_file image_type

    if [ -z "${_tmpl_namespace}" ] || [ -z "${_tmpl_image_name}" ]; then
        die "Error: ${_arg_name} should have format <namespace>/<image>"
    fi

    ns_conf_file="./${_NAMESPACE_PATH}/${_tmpl_namespace}/build.conf"
    [ -f "${ns_conf_file}" ] || die "Error: could not read ${ns_conf_file}

You can create a new namespace by running: ${0} new namespace ${_tmpl_namespace}
"
    __get_ns_conf="${ns_conf_file}"
}

# Arguments:
# 1: image_name
function add_image() {
    local image_name image_base_path image_path
    image_name="$1"

    get_ns_conf "${_IMAGE_PATH}"
    source "${__get_ns_conf}"

    msg '\n<enter> to accept default value\n'

    msg 'Extend an existing image? Full image id (i.e. gentoobb/busybox) or scratch'
    read -p 'Parent Image (scratch): ' _tmpl_image_parent
    [ -z "${_tmpl_image_parent}" ] && _tmpl_image_parent='scratch'

    image_base_path="./${_NAMESPACE_PATH}/${_tmpl_namespace}/images"
    image_path="${image_base_path}/${_tmpl_image_name}"

    [ -d "${image_path}" ] && die "${image_path} already exists, aborting!"
    [ ! -d "${image_base_path}" ] && mkdir -p "${image_base_path}"

    cp -r "./lib/template/${BUILD_ENGINE}/image" "${image_path}" || die

    _template_target="${image_path}"
    _post_msg="Successfully created ${_arg_name} image at ${image_path}\n"
}

# Arguments:
# 1: builder_name
function add_builder() {
    local builder_name
    builder_name="$1"

    get_ns_conf "${_BUILDER_PATH}"
    source "${__get_ns_conf}"

    msg '\n<enter> to accept default value\n'

    msg 'Extend an existing builder? Full image id (i.e. gentoobb/bob) or stage3'
    read -p 'Parent Image (stage3): ' _tmpl_builder_type
    [ -z "${_tmpl_builder_type}" ] && _tmpl_builder_type='stage3'

    _tmpl_builder="${_tmpl_builder_type}"
    [[ "${_tmpl_builder_type}" == "stage3" ]] && _tmpl_builder='\${NAMESPACE}/bob'

    image_base_path="./${_NAMESPACE_PATH}/${_tmpl_namespace}/builder"
    image_path="${image_base_path}/${_tmpl_image_name}"

    [ -d "${image_path}" ] && die "${image_path} already exists, aborting!"
    [ ! -d "${image_base_path}" ] && mkdir -p "${image_base_path}"

    cp -r "./lib/template/${BUILD_ENGINE}/builder" "${image_path}" || die

    _template_target="${image_path}"
    _post_msg="Successfully created ${_arg_name} builder at ${image_path}\n"
}

function main() {
    local sed_args tmpl_var tmpl_file

    _tmpl_namespace="${_arg_name%%/*}"
    _tmpl_image_name="${_arg_name##*/}"

    case "${_arg_template_type}" in
        namespace)
            add_namespace "${_arg_name}"
            ;;
        image)
            add_image "${_arg_name}"
            ;;
        builder)
            add_builder "${_arg_name}"
            ;;
        *)
            show_help
            die "Error, unknown type: ${_arg_template_type}, should be namespace, builder or image.."
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
    for tmpl_file in "${_template_target}"/*; do
        replace_in_file "${tmpl_file}" sed_args[@]
    done

    msg "\n${_post_msg}"
}

main "$@"
