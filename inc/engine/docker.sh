#!/bin/bash

DOCKER_IO=$(command -v docker.io)
DOCKER="${DOCKER:-${DOCKER_IO:-docker}}"

# Is docker functional?
validate_engine() {
    REQUIRED_BINARIES+=" docker"
    has_required_binaries
    DOCKER_VERSION=$(${DOCKER} "version") || die "--> error: failed to query the docker daemon:\n${DOCKER_VERSION}"
}

# Check if given REPO has required files, etc.
#
# Arguments:
# 1: REPO
# 2: REPO_TYPE
validate_repo() {
    local REPO_EXPANDED=${1/\//\/${2}}
    [ ! -f ${REPO_EXPANDED}/Dockerfile.template ] && die "failed to read ${REPO_EXPANDED}/Dockerfile.template"
}

# Remove image from registry
#
# Arguments:
#
# 1: REPO
remove_image()
{
    local REPO="${1}"
    "${DOCKER}" rmi -f "$REPO:${DATE}" || die "failed to remove image $REPO:${DATE}"
}

# Get docker image size for given ${NAMESPACE}/${IMAGE}:${TAG}
#
# Arguments:
# 1: IMAGE (i.e. gentoobb/busybox)
# 2: TAG (=DATE)
get_image_size() {
    echo "$(${DOCKER} images ${1} | grep ${2} | awk '{print $(NF-1)" "$NF}')"
}

# Does "${NAMESPACE}/${REPO}:${DATE}" exist?
image_exists()
{
    local REPO="${1}"
    local REPO_TYPE="${2:-${IMAGE_PATH}}"
    [[ "${REPO}" == "${BUILDER_CORE}" ]] && REPO=${BUILDER_CORE}
    IMAGES=$("${DOCKER}" images "${REPO}") || die "error while checking for image ${REPO}:${DATE}"
    local MATCHES=$(echo "${IMAGES}" | grep "${DATE}")
    if [ -z "${MATCHES}" ]; then
        return 3
    fi
    if [ -n $FORCE_FULL_REBUILD ] && [[ "${FORCE_FULL_REBUILD}" == "true" ]]; then
        remove_image "$REPO"
        return 3
    elif $FORCE_BUILDER_REBUILD && [ "${REPO_TYPE}" == "${BUILDER_PATH}" ]; then
        remove_image "$REPO"
        return 3
    elif ($FORCE_REBUILD || $FORCE_ROOTFS_REBUILD) && [ "${REPO_TYPE}" != "${BUILDER_PATH}" ] && [ "$REPO" != "${NAMESPACE}/stage3-import" ] && [ "$REPO" != "${BUILDER_CORE}" ]; then
        remove_image "$REPO"
        return 3
    fi
    return 0
}

# Start a container from given IMAGE_REPO.
#
# Arguments:
# 1: IMAGE_REPO (i.e. gentoobb/busybox)
# 2: CONTAINER_HOST_NAME
# 3: DELETE_AFTER_RUN
run_image() {
    local IMAGE="${1}"
    # docker env options
    DOCKER_ENV=()
    for E in "${CONTAINER_ENV[@]}"; do
            DOCKER_ENV+=('-e' "${E}")
    done
    # docker mount options
    DOCKER_MOUNTS=()
    for V in "${CONTAINER_MOUNTS[@]}"; do
            DOCKER_MOUNTS+=('-v' "${V}")
    done
    # general docker args
    DOCKER_ARGS=("-it" "--hostname" "${2}")
    [[ "${3}" == "true" ]] && DOCKER_ARGS+=("--rm")
    # gogo
    "${DOCKER}" run "${DOCKER_ARGS[@]}" "${DOCKER_MOUNTS[@]}" "${DOCKER_ENV[@]}" "${IMAGE}" "${CONTAINER_CMD[@]}" ||
        die "failed to run image ${IMAGE}"
}

# Generate Dockerfile from Dockerfile.template
#
# Arguments:
# 1: Path to Dockerfile.template
generate_dockerfile()
{
    local SED_PARAM=()
    # also make variables starting with BOB_ available in Dockerfile.template
    for bob_var in ${!BOB_*}; do
        SED_PARAM+=(-e "s|\${${bob_var}}|${!bob_var}|")
    done

    sed "${SED_PARAM[@]}" \
        -e 's|${DEF_BUILD_CONTAINER}|'"${DEF_BUILD_CONTAINER}"'|' \
        -e 's/${NAMESPACE}/'"${NAMESPACE}"'/' \
        -e 's/${TAG}/'"${DATE}"'/' \
        -e 's/${MAINTAINER}/'"${AUTHOR}"'/' "${1}/Dockerfile.template" > "${1}/Dockerfile" || \
            die "error while generating ${1}/Dockerfile"
}

# Returns given TAG value from DOCKERFILE or exit signal 3 if TAG was not found
#
# Arguments:
# 1: TAG (i.e. FROM)
# 2: DOCKERFILE_PATH
get_dockerfile_tag() {
    [ ! -f "${2}/Dockerfile" ] && die "failed to read ${2}/Dockerfile"
    dockerf=$(grep ^${1} ${2}/Dockerfile)
    regex="^${1} (.*)"
    [[ ${dockerf} =~ $regex ]] && echo "${BASH_REMATCH[1]}" || exit 3
}

# Returns builder name given BUILDER_REPO is based on, or exit signal 3 if not defined
get_parent_builder() {
    local REPO="${1}"
    local REPO_EXPANDED=${REPO/\//\/${BUILDER_PATH}}
    generate_dockerfile "${REPO_EXPANDED}"
    FROM=$(get_dockerfile_tag "FROM" "${REPO_EXPANDED}")
    [[ $? == 1 ]] && die "${FROM}"
    [[ "${FROM}" != "" ]] && echo ${FROM} || exit 3
}

# Returns image given IMAGE_REPO is based on by parsing FROM, or exit signal 3 if not defined
get_parent_image() {
    local REPO="${1}"
    local REPO_TYPE="${2:-${IMAGE_PATH}}"
    FROM=$(get_dockerfile_tag "FROM" ${REPO/\//\/$REPO_TYPE})
    [[ $? == 1 ]] && die "${FROM}"
    [[ "${FROM}" != "" ]] && echo ${FROM} || exit 3
}

# Returns builder given IMAGE_REPO needs for building the rootfs, or exit signal 3 if not defined
get_image_builder() {
    local REPO="${1}"
    local REPO_TYPE="${2:-${IMAGE_PATH}}"
    local REPO_EXPANDED=${REPO/\//\/${REPO_TYPE}}
    generate_dockerfile "${REPO_EXPANDED}"
    BUILD_FROM=$(get_dockerfile_tag "#BUILD_FROM" "${REPO_EXPANDED}")
    [[ $? == 1 ]] && die "${BUILD_FROM}"
    [[ "${BUILD_FROM}" != "" ]] && echo ${BUILD_FROM} || exit 3
}

# Returns build container name for given REPO, implements "virtual" build container juggling for images
# 
# Arguments:
# 1: REPO
# 2: REPO_TYPE
get_build_container() {
    local REPO="${1}"
    local REPO_TYPE="${2:-${IMAGE_PATH}}"
    local REPO_EXPANDED=${REPO/\//\/${REPO_TYPE}}
    # determine build container
    local BUILD_CONTAINER=${DEF_BUILD_CONTAINER}
    BUILD_FROM=$(get_image_builder ${REPO} ${REPO_TYPE})
    [[ $? == 1 ]] && die "${BUILD_FROM}"
    [[ "${BUILD_FROM}" == "" ]] && BUILD_FROM="false"
    PARENT_REPO=$(get_parent_image ${REPO} ${REPO_TYPE}) 
    [[ $? == 1 ]] && die "Error parsing parent image for ${REPO}"
    local PARENT_IMAGE=${PARENT_REPO##*/}
    local CURRENT_IMAGE=${REPO##*/}

    if [[ "$BUILD_FROM" != "false" ]]; then
        BUILD_CONTAINER="${BUILD_FROM}"
    elif [[ "${REPO_TYPE}" == "${IMAGE_PATH}" ]]; then
        [[ "${PARENT_IMAGE}" != "scratch" ]] && image_exists "${BUILD_CONTAINER}-${PARENT_IMAGE}" "${BUILDER_PATH}" && \
            BUILD_CONTAINER="${BUILD_CONTAINER}-${PARENT_IMAGE}"
    elif [[ "${REPO_TYPE}" == "${BUILDER_PATH}" ]] && [[ "$BUILD_FROM" == "false" ]]; then
        [[ "${PARENT_REPO}" == "${REPO}" ]] && BUILD_CONTAINER=${BUILDER_CORE}
    fi
    [[ "${PARENT_REPO}" == "${BUILD_CONTAINER}" ]] && [[ "${BUILD_FROM}" == "false" ]] && BUILD_CONTAINER=${BUILDER_CORE}

    echo "${BUILD_CONTAINER}"
}

# If they don't already exist:
import_stage3()
{
    msg "build ${NAMESPACE_ROOT}/stage3-import"
    image_exists "${NAMESPACE_ROOT}/stage3-import" && return 0

    download_stage3 || die "failed to download stage3 files"

    # import stage3 image from Gentoo mirrors
    msg "import ${NAMESPACE_ROOT}/stage3-import:${DATE}"
    bzcat < "$DL_PATH/${STAGE3}" | bzip2 | "${DOCKER}" import - "${NAMESPACE_ROOT}/stage3-import:${DATE}" || die "failed to import"

    msg "tag ${NAMESPACE_ROOT}/stage3-import:latest"
    "${DOCKER}" tag -f "${NAMESPACE_ROOT}/stage3-import:${DATE}" "${NAMESPACE_ROOT}/stage3-import:latest" || die "failed to tag"
}

# Boostrap gentoobb/bob-core
build_core() {
    download_portage_snapshot
    import_stage3

    local CORE_BUILDER_PATH=${BUILDER_CORE/\//\/${BUILDER_PATH}}
    local PORTAGE_FAKE="portage-fake.tar.xz"

    # copy portage snapshot to bob-core/ so we can access it via dockerfile context, if missing create a "fake"
    # so the dockerfile copy command won't fail the build (webrsync will fetch latest snapshot)
    [ -f "${DL_PATH}/${PORTAGE}" ] && cp ${DL_PATH}/${PORTAGE}* ${CORE_BUILDER_PATH}/ ||
        touch ${CORE_BUILDER_PATH}/${PORTAGE_FAKE}
    # copy build-root.sh and emerge defaults so we can access it via dockerfile context
    cp ${PROJECT_ROOT}/bob-core/{build-root.sh,make.conf,portage-defaults.sh} ${CORE_BUILDER_PATH}/

    generate_dockerfile ${CORE_BUILDER_PATH}
    build_image "${BUILDER_CORE}" "${BUILDER_PATH}"

    # clean up
    rm ${CORE_BUILDER_PATH}/{build-root.sh,make.conf,portage-defaults.sh}
    [ -f ${CORE_BUILDER_PATH}/${PORTAGE} ] && rm -f ${CORE_BUILDER_PATH}/${PORTAGE}*
    [ -f ${CORE_BUILDER_PATH}/${PORTAGE_FAKE} ] && rm ${CORE_BUILDER_PATH}/${PORTAGE_FAKE}
}

# Produces a build container image for given BUILDER_REPO
build_builder() {
    build_image "${1}" "${BUILDER_PATH}"
}

# Called when using the -n flag of build.sh, thin wrapper to build_image()
build_image_no_deps() {
    generate_dockerfile ${1/\//\/${IMAGE_PATH}}
    build_image ${1}
}

# If it doesn't already exist:
#
#
# Forcibly tag "${NAMESPACE}/${REPO}:${DATE}" with "latest"
#
# Arguments:
#
# 1: REPO
# 2: REPO_TYPE (images/|builder/)
build_image()
{
    REPO="${1}"
    REPO_TYPE="${2:-${IMAGE_PATH}}"
    REPO_EXPANDED=${REPO/\//\/${REPO_TYPE}}
    msg "build repo ${REPO}"
    image_exists "${REPO}" "${REPO_TYPE}" && return 0

    if ([ ! -f $REPO_EXPANDED/rootfs.tar ] || $FORCE_ROOTFS_REBUILD) && \
        [ "${REPO}" != ${BUILDER_CORE} ]; then

        msg "building rootfs"

        BUILD_CONTAINER=$(get_build_container ${REPO} ${REPO_TYPE}) || die "${BUILD_CONTAINER}"

        # determine build container commit id
        local BUILDER_COMMIT_ID=""
        BUILD_FROM=$(get_image_builder ${REPO} ${REPO_TYPE})
        [[ $? == 1 ]] && die "${BUILD_FROM}"
        [[ "${BUILD_FROM}" == "" ]] && BUILD_FROM="false"
        PARENT_REPO=$(get_parent_image ${REPO} ${REPO_TYPE}) 
        [[ $? == 1 ]] && die "Error parsing parent image for ${REPO}"
        local CURRENT_IMAGE=${REPO##*/}

        if [[ "$BUILD_FROM" != "false" ]]; then
            BUILDER_COMMIT_ID="${BUILD_FROM##*/}-${CURRENT_IMAGE}"
        elif [[ "${REPO_TYPE}" == "${IMAGE_PATH}" ]]; then
            BUILDER_COMMIT_ID="${DEF_BUILD_CONTAINER##*/}-${CURRENT_IMAGE}"
        fi

        [[ "${PARENT_REPO}" == "${BUILD_CONTAINER}" ]] && [[ "${BUILD_FROM}" == "false" ]] && BUILDER_COMMIT_ID="${REPO##*/}"
        [[ "${PARENT_REPO}" == "${REPO}" ]] && BUILDER_COMMIT_ID="${CURRENT_IMAGE}"

        # mounts for build container
        local CONTAINER_MOUNTS=("$(dirname $(realpath -s $0))/$REPO_EXPANDED:/config"
"$(realpath -s ../tmp/distfiles):/distfiles"
"$(realpath -s ../tmp/packages):/packages"
)

        # pass variables starting with BOB_ to build container as ENV
        for bob_var in ${!BOB_*}; do
            CONTAINER_ENV+=("${bob_var}=${!bob_var}")
        done

        local CONTAINER_CMD=("build-root" ${REPO_EXPANDED})

        msg "run ${BUILD_CONTAINER}:${DATE}"
        run_image "${BUILD_CONTAINER}:${DATE}" "${REPO}" "false" || die "failed to build rootfs for $REPO_EXPANDED"

        RUN_ID="$(${DOCKER} ps -a | grep -m1 ${BUILD_CONTAINER}:${DATE} | awk '{print $1}')"

        msg "commit ${RUN_ID} ${NAMESPACE}/${BUILDER_COMMIT_ID}:${DATE}"
        "${DOCKER}" commit "${RUN_ID}" "${NAMESPACE}/${BUILDER_COMMIT_ID}:${DATE}" ||
            die "failed to commit ${NAMESPACE}/${BUILDER_COMMIT_ID}:${DATE}"

        "${DOCKER}" rm "${RUN_ID}" || die "failed to remove container ${RUN_ID}"

        msg "tag ${NAMESPACE}/${BUILDER_COMMIT_ID}:latest"
        "${DOCKER}" tag -f "${NAMESPACE}/${BUILDER_COMMIT_ID}:${DATE}" "${NAMESPACE}/${BUILDER_COMMIT_ID}:latest" ||
            die "failed to tag ${BUILDER_COMMIT_ID}"
    fi

    REPO_ID=$REPO
    [[ "$REPO" == ${BUILDER_CORE} ]] && REPO_ID=${BUILDER_CORE}

    msg "build ${REPO}:${DATE}"
    "${DOCKER}" build ${BUILD_OPTS} -t "${REPO_ID}:${DATE}" "${REPO_EXPANDED}" || die "failed to build ${REPO_EXPANDED}"

    msg "tag ${REPO}:latest"
    "${DOCKER}" tag -f "${REPO_ID}:${DATE}" "${REPO_ID}:latest" || die "failed to tag ${REPO_EXPANDED}"

    add_documentation_header "${REPO}" "${REPO_TYPE}" || die "failed to generate PACKAGES.md for ${REPO_EXPANDED}"
}

# Handle docker registry login
#
# Arguments:
# 1: NAMESPACE (i.e. gentoobb)
# 2: REPOSITORY_URL
push_auth() {
    local NAMESPACE="${1}"
    local REPOSITORY_URL="${2}"
    if [[ -z "${REPOSITORY_URL}" ]]; then
        DOCKER_LOGIN="${DOCKER_LOGIN:-${NAMESPACE}}"
        echo "pushing to docker.io/u/${DOCKER_LOGIN}"
        LOGIN_ARGS="-u ${DOCKER_LOGIN}"
        if [ ! -z ${DOCKER_PW} ]; then
            LOGIN_ARGS+=" -p ${DOCKER_PW}"
        fi
        if [ ! -z ${DOCKER_EMAIL} ]; then
            LOGIN_ARGS+=" -e ${DOCKER_EMAIL}"
        fi
        ${DOCKER} login $LOGIN_ARGS || exit 1
    else
        echo "pushing to ${REPOSITORY_URL}"
    fi
}

# Push image to official or private docker registry, creates required tagging for private registries
#
# Arguments:
# 1: IMAGE_ID (i.e. gentoobb/busybox)
# 2: REPOSITORY_URL
push_image() {
    local IMAGE_ID="${1}"
    local REPOSITORY_URL="${2}"
    PUSH_ARGS="${IMAGE_ID}"
    if [[ ! -z "${REPOSITORY_URL}" ]]; then
        IMAGE_DOCKER_ID=$("${DOCKER}" images "${IMAGE_ID}" | grep "${DATE}" | awk '{print $3}')
        PUSH_ARGS="${REPOSITORY_URL}/${IMAGE_ID}"
        echo "${DOCKER}" tag -f "${IMAGE_DOCKER_ID}" ${PUSH_ARGS}
        "${DOCKER}" tag -f "${IMAGE_DOCKER_ID}" "${PUSH_ARGS}" || exit 1
    fi
    echo "pushing ${PUSH_ARGS}"
    "${DOCKER}" push "${PUSH_ARGS}" || exit 1
}
