#!/usr/bin/env bash
#
# Copyright (c) 2014-2017, Erik Dannenberg <erik.dannenberg@xtrade-gmbh.de>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
# following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following
#    disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
# following disclaimer in the documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

DOCKER_IO=$(command -v docker.io)
DOCKER="${DOCKER:-${DOCKER_IO:-docker}}"
DOCKER_BUILD_OPTS="${DOCKER_BUILD_OPTS:-}"

_container_mount_portage="false"

# Is this engine functional? Called once per engine in current image dependency graph.
function validate_engine() {
    local docker_version
    _required_binaries+=" docker"
    has_required_binaries
    docker_version=$(${DOCKER} "version") || die "Failed to query the docker daemon:\n${docker_version}"
}

# Has given image_id all requirements to start the build? Called once per image in current image dependency graph.
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
# 2: image_type ($_IMAGE_PATH or $_BUILDER_PATH)
function validate_image() {
    local image_id image_type
    image_id="$1"
    image_type="$2"
    expand_image_id "${image_id}" "${image_type}"
    file_exists_or_die "${__expand_image_id}/Dockerfile.template"
}

# Generate Dockerfile from Dockerfile.template
#
# Arguments:
# 1: image_path (i.e. kubler/images/busybox)
function generate_dockerfile() {
    local image_path sed_param bob_var
    image_path="$1"
    sed_param=()
    # also make variables starting with BOB_ available in Dockerfile.template
    for bob_var in ${!BOB_*}; do
        sed_param+=(-e "s|\${${bob_var}}|${!bob_var}|")
    done
    sed "${sed_param[@]}" \
        -e 's|${IMAGE_PARENT}|'"${IMAGE_PARENT}"'|g' \
        -e 's|${DEFAULT_BUILDER}|'"${DEFAULT_BUILDER}"'|g' \
        -e 's/${NAMESPACE}/'"${_current_namespace}"'/g' \
        -e 's/${TAG}/'"${IMAGE_TAG}"'/g' \
        -e 's/${MAINTAINER}/'"${AUTHOR}"'/g' \
        "${image_path}/Dockerfile.template" > "${image_path}/Dockerfile" \
            || die "error while generating ${image_path}/Dockerfile"
}

# Returns given tag value from dockerfile or exit signal 3 if tag was not found.
# Returns "true" if TAG was found but has no value.
#
# Arguments:
# 1: tag (i.e. FROM)
# 2: image_path (i.e. kubler/images/busybox)
function get_dockerfile_tag() {
    __get_dockerfile_tag=
    local tag image_path dockerfile grep_out regex
    tag="$1"
    image_path="$2"
    dockerfile="${image_path}/Dockerfile"
    file_exists_or_die "${dockerfile}"
    grep_out=$(grep ^${tag} "${dockerfile}")
    regex="^${tag} ?(.*)?"
    if [[ "${grep_out}" =~ $regex ]]; then
        if [ ${BASH_REMATCH[1]} ]; then
            __get_dockerfile_tag="${BASH_REMATCH[1]}"
        else
            exit 3
        fi
    fi
}

# Remove image from local image store
#
# Arguments:
#
# 1: image_id
# 2: image_tag
function remove_image() {
    local image_id image_tag
    image_id="$1"
    image_tag="${2:-${IMAGE_TAG}}"
    "${DOCKER}" rmi -f "${image_id}:${image_tag}" || die "failed to remove image ${image_id}:${image_tag}"
}

# Build the image for given image_id
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
# 2: image_type - $_IMAGE_PATH or $_BUILDER_PATH, defaults to $_IMAGE_PATH
function build_image() {
    local image_id image_type image_expanded builder_id builder_commit_id current_image bob_var run_id
    image_id="${1}"
    image_type="${2:-${_IMAGE_PATH}}"
    expand_image_id "${image_id}" "${image_type}"
    image_expanded="${__expand_image_id}"

    msg "--> build image ${image_id}"
    image_exists "${image_id}" "${image_type}"
    local exists_return=$?
    [[ ${exists_return} -eq 0 ]] && return 0
    # if the builder image does not exist we need to ensure there is no pre-existing rootfs.tar
    if [[ ${exists_return} -eq 3 && "${image_type}" == "${_BUILDER_PATH}" ]]; then
        [[ -f "${image_expanded}/rootfs.tar" ]] && rm "${image_expanded}/rootfs.tar"
    fi

    generate_dockerfile "${image_expanded}"

    # build rootfs?
    if [[ ! -f "${image_expanded}/rootfs.tar" || "${_arg_force_full_image_build}" == 'on' ]] && \
       [[ "${image_type}" == "${_IMAGE_PATH}" || "${image_id}" != "${_current_namespace}"/*-core ]]; then

        msg "--> phase 1: building root fs"

        get_build_container "${image_id}" "${image_type}"
        builder_id="${__get_build_container}"

        # determine build container commit id
        builder_commit_id=""
        current_image=${image_id##*/}
        if [[ ! -z "${BUILDER}" ]]; then
            builder_commit_id="${BUILDER##*/}-${current_image}"
        elif [[ "${image_type}" == "${_IMAGE_PATH}" ]]; then
            builder_commit_id="${DEFAULT_BUILDER##*/}-${current_image}"
        fi

        if [[ "${image_type}" == "${_BUILDER_PATH}" ]]; then
            [[ "${builder_id}" == "${image_id}" && "${image_id}" != "${_current_namespace}"/*-core ]] && \
                builder_id="${image_id}-core"
            builder_commit_id="${image_id##*/}"
        fi

        local config_dir
        # mounts for build container
        get_absolute_path "${image_expanded}"
        config_dir="${__get_absolute_path}"
        _container_mounts=("${config_dir}:/config"
                           "${_KUBLER_DIR}/tmp/distfiles:/distfiles"
                           "${_KUBLER_DIR}/tmp/packages:/packages"
                          )

        # pass variables starting with BOB_ to build container as ENV
        for bob_var in ${!BOB_*}; do
            _container_env+=("${bob_var}=${!bob_var}")
        done

        _container_cmd=("/root/build-root.sh" "${image_expanded}")
        _container_mount_portage="true"

        msg "using ${builder_id}:${IMAGE_TAG}"

        run_id="${image_id//\//-}-${RANDOM}"
        run_image "${builder_id}:${IMAGE_TAG}" "${image_id}" "false" "${run_id}" || die "failed to build rootfs for ${image_expanded}"

        _container_mount_portage="false"

        msg "commit ${run_id} as ${_current_namespace}/${builder_commit_id}:${IMAGE_TAG}"
        "${DOCKER}" commit "${run_id}" "${_current_namespace}/${builder_commit_id}:${IMAGE_TAG}" ||
            die "failed to commit ${_current_namespace}/${builder_commit_id}:${IMAGE_TAG}"

        "${DOCKER}" rm "${run_id}" || die "failed to remove container ${run_id}"

        msg "tag ${_current_namespace}/${builder_commit_id}:latest"
        "${DOCKER}" tag "${_current_namespace}/${builder_commit_id}:${IMAGE_TAG}" "${_current_namespace}/${builder_commit_id}:latest" ||
            die "failed to tag ${builder_commit_id}"
    fi

    msg "--> phase 2: build ${image_id}:${IMAGE_TAG}"
    "${DOCKER}" build ${DOCKER_BUILD_OPTS} -t "${image_id}:${IMAGE_TAG}" "${image_expanded}" || die "failed to build ${image_expanded}"

    msg "tag ${image_id}:latest"
    "${DOCKER}" tag "${image_id}:${IMAGE_TAG}" "${image_id}:latest" || die "failed to tag ${image_expanded}"

    add_documentation_header "${image_id}" "${image_type}" || die "failed to generate PACKAGES.md for ${image_expanded}"
}

# Check if container exists for given container_name, exit with signal 3 if it does not
#
# Arguments:
# 1: container_name
function container_exists() {
    local container_name
    container_name="$1"
    "${DOCKER}" inspect "${container_name}" > /dev/null 2>&1 || return 3
    return 0
}

# Check if image exits for given image_id, exits with signal 3 if not.
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
# 2: image_type ($_IMAGE_PATH or $_BUILDER_PATH)
# 3: image_tag - optional, default: ${IMAGE_TAG}
# 4: ignore_build_opts - only check with docker, ignore build options like -c, optional, default: false
function image_exists() {
    local image_id image_type image_tag images
    image_id="${1}"
    image_type="${2:-${IMAGE_PATH}}"
    image_tag="${3:-${IMAGE_TAG}}"
    ignore_build_opts="$4"
    # image exists?
    "${DOCKER}" inspect "${image_id}:${image_tag}" > /dev/null 2>&1 || return 3
    [[ -n "${ignore_build_opts}" ]] && return 0
    # ok, lets check the rebuild flags
    if [[ "${_arg_clear_everything}" == 'on' && "${image_id}" != "${_STAGE3_NAMESPACE}/portage" ]]; then
        # -C => nuke everything except portage
        remove_image "${image_id}" "${image_tag}"
        return 3
    elif [[ "${_arg_clear_build_container}" == 'on' && "${image_type}" == "${_BUILDER_PATH}" ]]; then
        # -c => rebuild builder if not stage3 or portage image
        if [[ "${image_id}" != "${_STAGE3_NAMESPACE}/${STAGE3_BASE//+/-}" && "${image_id}" != "${_PORTAGE_IMAGE}" ]]; then
            remove_image "${image_id}" "${image_tag}"
            return 3
        fi
    elif [[ "${_arg_force_image_build}" == 'on' || "${_arg_force_full_image_build}" == 'on' ]]; then
        # -f, -F => rebuild image if not a builder
        [[ "${image_type}" != "${_BUILDER_PATH}" ]] && remove_image "${image_id}" "${image_tag}" && return 3
    fi
    # fine, guess the image really does exist :P
    return 0
}

# Sets __get_image_size for given image_id, required for generating PACKAGES.md header
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
# 2: image_tag (a.k.a. version)
function get_image_size() {
    __get_image_size=
    local image_id image_tag image_size
    image_id="$1"
    image_tag="$2"
    image_size="$(${DOCKER} images "${image_id}:${image_tag}" --format '{{.Size}}')"
    [[ $? -ne 0 ]] && die "Couldn't determine image size for ${image_id}:${image_tag}: ${image_size}"
    __get_image_size="${image_size}"
}

# Start a container from given image_id.
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
# 2: container_host_name
# 3: remove container after it exists, optional, default: true
# 4: container_name, optional, keep in mind that this needs to be unique for all existing containers on the host
function run_image() {
    local image_id container_host_name auto_rm container_name docker_env denv docker_mounts dmnt
    image_id="$1"
    container_host_name="$2"
    auto_rm="${3:-true}"
    container_name="$4"
    # docker env options
    docker_env=()
    for denv in "${_container_env[@]}"; do
        docker_env+=('-e' "${denv}")
    done
    # docker mount options
    docker_mounts=()
    for dmnt in "${_container_mounts[@]}"; do
        docker_mounts+=('-v' "${dmnt}")
    done
    # general docker args
    docker_args=("-it" "--hostname" "${container_host_name//\//-}")
    [[ "${auto_rm}" == "true" ]] && docker_args+=("--rm")
    [[ ! -z "${container_name}" ]] && docker_args+=("--name" "${container_name//\//-}")
    [[ "${BUILD_PRIVILEGED}" == "true" ]] && docker_args+=("--privileged")
    [[ "${_container_mount_portage}" == "true" ]] && docker_args+=("--volumes-from" "${_PORTAGE_IMAGE//\//-}")
    # gogo
    "${DOCKER}" run "${docker_args[@]}" "${docker_mounts[@]}" "${docker_env[@]}" "${image_id}" "${_container_cmd[@]}" ||
        die "Failed to run image ${image_id}"
}

# Docker import a portage snapshot as given portage_image_id
#
# Arguments:
# 1: portage_image_id (i.e. bob/portage)
# 2: image_tag (a.k.a. version)
function import_portage_tree() {
    local image_id image_tag portage_tmp_file
    image_id="$1"
    image_tag="$2"
    image_exists "${image_id}" "${_BUILDER_PATH}" "${image_tag}" && return 0

    download_portage_snapshot || die "Failed to download portage snapshot"

    msg "--> bootstrap ${image_id}"
    portage_tmp_file="${_KUBLER_DIR}/lib/bob-portage/${_portage_file}"
    cp "${DOWNLOAD_PATH}/${_portage_file}" "${_KUBLER_DIR}/lib/bob-portage/"
    export BOB_CURRENT_PORTAGE_FILE=${_portage_file}

    generate_dockerfile "${_KUBLER_DIR}/lib/bob-portage/"
    "${DOCKER}" build -t "${image_id}:${PORTAGE_DATE}" "${_KUBLER_DIR}/lib/bob-portage/" || die "failed to tag"
    rm ${_KUBLER_DIR}/lib/bob-portage/Dockerfile "${portage_tmp_file}"
    "${DOCKER}" tag "${image_id}:${PORTAGE_DATE}" "${image_id}:latest" || die "failed to tag"
}


# Docker import a stage3 tar ball for given stage3_image_id
#
# Arguments:
# 1: stage3_image_id (i.e. bob/${STAGE3_BASE})
function import_stage3() {
    local image_id
    image_id="${1//+/-}"
    image_exists "${image_id}" "${_BUILDER_PATH}" "${STAGE3_DATE}" && return 0

    download_stage3 || die "failed to download stage3 files"

    msg "--> import ${image_id}:${STAGE3_DATE} using ${_stage3_file}"
    bzcat < "${DOWNLOAD_PATH}/${_stage3_file}" | bzip2 | "${DOCKER}" import - "${image_id}:${STAGE3_DATE}" || die "failed to import ${_stage3_file}"

    msg "tag ${image_id}:latest"
    "${DOCKER}" tag "${image_id}:${STAGE3_DATE}" "${image_id}:latest" || die "failed to tag"
}

# This function is called once per stage3 build container and should
# bootstrap a stage3 with portage plus helper files from /bob-core.
#
# Arguments:
# 1: builder_id (i.e. kubler/bob)
function build_core() {
    local builder_id core_id
    builder_id="$1"
    import_portage_tree "${_PORTAGE_IMAGE}" "${PORTAGE_DATE}"

    # ensure the portage container is created
    container_exists "${_PORTAGE_CONTAINER}"
    [[ $? -eq 3 ]] &&
        msg "--> create portage container, this may take a few moments.. " && \
        "${DOCKER}" run '--name' "${_PORTAGE_CONTAINER}" "${_PORTAGE_IMAGE}" true

    BOB_CURRENT_STAGE3_ID="${_STAGE3_NAMESPACE}/${STAGE3_BASE//+/-}"
    import_stage3 "${BOB_CURRENT_STAGE3_ID}"

    core_id="${builder_id}-core"
    image_exists "${core_id}" "${_BUILDER_PATH}" && return 0
    expand_image_id "${core_id}" "${_BUILDER_PATH}"
    mkdir -p "${__expand_image_id}"

    # copy build-root.sh and emerge defaults so we can access it via dockerfile context
    cp -r "${_KUBLER_DIR}"/lib/bob-core/{*.sh,etc,Dockerfile.template} "${__expand_image_id}/"

    generate_dockerfile "${__expand_image_id}"
    build_image "${builder_id}-core" "${_BUILDER_PATH}"

    # clean up
    rm -r ${__expand_image_id}
}

# Produces a build container image for given builder_id
# Implement this if you want support for multiple build containers.
#
# Arguments:
# 1: builder_id (i.e. kubler/bob)
function build_builder() {
    local builder_id
    builder_id="$1"
    # bootstrap a stage3 image if defined in build.conf
    [[ ! -z "${STAGE3_BASE}" ]] && build_core "${builder_id}"
    build_image "${builder_id}" "${_BUILDER_PATH}"
}

# Called when using --no-deps, in most cases a thin wrapper to build_image()
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
function build_image_no_deps() {
    local image_id
    image_id="$1"
    build_image "${image_id}"
}

# Sets __get_build_container to the builder_id required for building given image_id or signal 3 if not found/implemented.
#
# Arguments:
# 1: image_id
# 2: image_type ($_IMAGE_PATH or $_BUILDER_PATH), default: $_IMAGE_PATH
function get_build_container() {
    __get_build_container=
    local image_id image_type build_container build_from parent_image current_image builder_image
    image_id="${1}"
    image_type="${2:-${_IMAGE_PATH}}"
    # set default
    build_container="${DEFAULT_BUILDER}"
    # get parent image basename
    parent_image="${IMAGE_PARENT##*/}"
    if [[ ! -z "${BUILDER}" ]]; then
        # BUILDER was set for this image, override default and start with given base builder from this image on
        build_container="${BUILDER}"
    elif [[ "${image_type}" == "${_IMAGE_PATH}" ]]; then
        builder_image="${build_container##*/}"
        [[ "${parent_image}" != "scratch" ]] \
        && image_exists "${_current_namespace}/${builder_image}-${parent_image}" "${_BUILDER_PATH}" "${IMAGE_TAG}" true \
            && build_container="${_current_namespace}/${builder_image}-${parent_image}"
    elif [[ "${image_type}" == "${_BUILDER_PATH}" ]]; then
        build_container="${image_id}-core"
    fi

    __get_build_container="${build_container}"
}

# Handle image repository auth, called once per namespace if pushing
#
# Arguments:
# 1: namespace (i.e. kubler)
# 2: repository_url
function push_auth() {
    local namespace repository_url login_args
    namespace="$1"
    repository_url="$2"
    if [[ -z "${repository_url}" ]]; then
        DOCKER_LOGIN="${DOCKER_LOGIN:-${namespace}}"
        msg "--> using docker.io/u/${DOCKER_LOGIN}"
        login_args="-u ${DOCKER_LOGIN}"
        if [ ! -z ${DOCKER_PW} ]; then
            login_args+=" -p ${DOCKER_PW}"
        fi
        "${DOCKER}" login ${login_args} || exit 1
    else
        echo "--> using ${repository_url}"
    fi
}

# Push image to a repository
#
# Arguments:
# 1: image_id (i.e. kubler/busybox)
# 2: repository_url
function push_image() {
    local image_id repository_url push_id docker_image_id
    image_id="$1"
    repository_url="$2"
    push_id="${image_id}"
    if [[ ! -z "${repository_url}" ]]; then
        docker_image_id="$("${DOCKER}" images "${image_id}:${image_tag}" --format '{{.ID}}')"
        [[ $? -ne 0 ]] && die "Couldn't determine image id for ${image_id}:${image_tag}: ${docker_image_id}"
        push_id="${repository_url}/${image_id}"
        msg "${DOCKER}" tag "${docker_image_id}" "${push_id}"
        "${DOCKER}" tag "${docker_image_id}" "${push_id}" || exit 1
    fi
    echo "--> pushing ${push_id}"
    "${DOCKER}" push "${push_id}" || exit 1
}
