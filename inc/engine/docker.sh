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
    IMAGES=$("${DOCKER}" images "${REPO}") || die "error while checking for image ${REPO}:${DATE}"
    local MATCHES=$(echo "${IMAGES}" | grep "${DATE}")
    if [ -z "${MATCHES}" ]; then
        return 3
    fi
    if [ -n $FORCE_FULL_REBUILD ] && [[ "${FORCE_FULL_REBUILD}" == "true" ]]; then
        remove_image "$REPO"
        return 3
    elif $FORCE_BUILDER_REBUILD && [ "${REPO_TYPE}" == "${BUILDER_PATH}" ] && [[ "${REPO}" != ${NAMESPACE}/*-stage3 ]] && [[ "${REPO}" != ${NAMESPACE}/*-core ]]; then
        remove_image "$REPO"
        return 3
    elif ($FORCE_REBUILD || $FORCE_ROOTFS_REBUILD) && [ "${REPO_TYPE}" != "${BUILDER_PATH}" ]; then
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
    DOCKER_ARGS=("-it" "--hostname" "${2//\//-}")
    [[ "${3}" == "true" ]] && DOCKER_ARGS+=("--rm")
    [[ "${BUILD_PRIVILEGED}" == "true" ]] && DOCKER_ARGS+=("--privileged")
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

# Returns given TAG value from DOCKERFILE or exit signal 3 if TAG was not found.
# Returns "true" if TAG was found but has no value.
#
# Arguments:
# 1: TAG (i.e. FROM)
# 2: DOCKERFILE_PATH
get_dockerfile_tag() {
    [ ! -f "${2}/Dockerfile" ] && die "failed to read ${2}/Dockerfile"
    dockerf=$(grep ^${1} ${2}/Dockerfile)
    regex="^${1} ?(.*)?"
    if [[ ${dockerf} =~ $regex ]]; then
        if [ ${BASH_REMATCH[1]} ]; then
            echo "${BASH_REMATCH[1]}" || exit 3
        else
            echo "true" || exit 3
        fi
    fi
}

# Returns builder name given BUILDER_REPO is based on, or exit signal 3 if not defined
get_parent_builder() {
    [[ "${BUILDER}" != "" ]] && echo ${BUILDER} || exit 3
}

# Returns image given IMAGE_REPO is based on by parsing FROM, or exit signal 3 if not defined
get_parent_image() {
    [[ "${IMAGE_PARENT}" != "" ]] && echo ${IMAGE_PARENT} || exit 3
}

# Returns builder given IMAGE_REPO needs for building the rootfs, or exit signal 3 if not defined
get_image_builder() {
    [[ ! -z "${STAGE3_BASE}" ]] && echo "${1}" && exit 0
    [[ "${BUILDER}" != "" ]] && echo ${BUILDER} || exit 3
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
    local BUILD_CONTAINER=${DEFAULT_BUILDER}
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
    fi

    echo "${BUILD_CONTAINER}"
}

# Docker import a stage3 tar ball for given STAGE3_REPO_ID
#
# Arguments:
# 1: STAGE3_REPO_ID (i.e. gentoobb/bob-stage3)
import_stage3()
{
    local IMAGE_NAME="${1}"
    msg "build ${IMAGE_NAME}"
    image_exists "${IMAGE_NAME}" "${BUILDER_PATH}" && [[ ! "${FORCE_FULL_REBUILD}" == true ]] && return 0

    download_stage3 || die "failed to download stage3 files"

    # import stage3 image from Gentoo mirrors
    msg "import ${IMAGE_NAME}:${DATE} using ${STAGE3}"
    bzcat < "$DL_PATH/${STAGE3}" | bzip2 | "${DOCKER}" import - "${IMAGE_NAME}:${DATE}" || die "failed to import stage3"

    msg "tag ${IMAGE_NAME}:latest"
    "${DOCKER}" tag "${IMAGE_NAME}:${DATE}" "${IMAGE_NAME}:latest" || die "failed to tag"
}

# Bootstrap a fresh stage3 docker image for given BUILDER_REPO_ID
#
# Arguments:
# 1: BUILDER_REPO_ID
build_core() {
    local BUILDER_CORE="${1}-core"
    export BOB_CURRENT_STAGE3_ID="${1}-stage3"
    import_stage3 "${BOB_CURRENT_STAGE3_ID}"

    local CORE_BUILDER_PATH=${BUILDER_CORE/\//\/${BUILDER_PATH}}
    mkdir -p "${CORE_BUILDER_PATH}"

    # copy build-root.sh and emerge defaults so we can access it via dockerfile context
    cp ${PROJECT_ROOT}/bob-core/{build-root.sh,make.conf,portage-defaults.sh,Dockerfile.template} ${CORE_BUILDER_PATH}/

    generate_dockerfile ${CORE_BUILDER_PATH}
    build_image "${1}-core" "${BUILDER_PATH}"

    # clean up
    rm -r ${CORE_BUILDER_PATH}
}

# Produces a build container image for given BUILDER_REPO_ID
#
# Arguments:
# 1: BUILDER_REPO_ID
build_builder() {
    # bootstrap a stage3 image if defined in build.conf
    if [[ ! -z "${STAGE3_BASE}" ]]; then
       STAGE3="${STAGE3_BASE}-${STAGE3_DATE}.tar.bz2"
       STAGE3_CONTENTS="${STAGE3}.CONTENTS"
       STAGE3_DIGESTS="${STAGE3}.DIGESTS.asc"
       build_core "${1}"
    fi
    build_image "${1}" "${BUILDER_PATH}"
}

# Called when using the -n flag of build.sh, thin wrapper to build_image()
build_image_no_deps() {
    #generate_dockerfile ${1/\//\/${IMAGE_PATH}}
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

    generate_dockerfile "${REPO_EXPANDED}"

    if ([ ! -f $REPO_EXPANDED/rootfs.tar ] || $FORCE_ROOTFS_REBUILD) && \
       ([[ "${REPO_TYPE}" == "${IMAGE_PATH}" ]]  || [[ "${REPO}" != ${NAMESPACE}/*-core ]]); then

        msg "building rootfs"

        BUILD_CONTAINER=$(get_build_container ${REPO} ${REPO_TYPE}) || die "${BUILD_CONTAINER}"

        # determine build container commit id
        local BUILDER_COMMIT_ID=""
        local BUILD_FROM=$(get_image_builder ${REPO} ${REPO_TYPE})
        [[ $? == 1 ]] && die "${BUILD_FROM}"
        [[ "${BUILD_FROM}" == "" ]] && BUILD_FROM="false"
        PARENT_REPO=$(get_parent_image ${REPO} ${REPO_TYPE})
        [[ $? == 1 ]] && die "Error parsing parent image for ${REPO}"
        local CURRENT_IMAGE=${REPO##*/}

        if [[ "$BUILD_FROM" != "false" ]]; then
            BUILDER_COMMIT_ID="${BUILD_FROM##*/}-${CURRENT_IMAGE}"
        elif [[ "${REPO_TYPE}" == "${IMAGE_PATH}" ]]; then
            BUILDER_COMMIT_ID="${DEFAULT_BUILDER##*/}-${CURRENT_IMAGE}"
        fi

        if [[ "${REPO_TYPE}" == "${BUILDER_PATH}" ]]; then
            [[ "${BUILD_CONTAINER}" == "${REPO}" ]] && [[ "${REPO}" != ${NAMESPACE}/*-core ]] && \
                BUILD_CONTAINER="${REPO}-core"
            BUILDER_COMMIT_ID="${REPO##*/}"
        fi

        # mounts for build container
        local CONTAINER_MOUNTS=("$(dirname $(realpath $0))/$REPO_EXPANDED:/config"
"$(realpath ../tmp/distfiles):/distfiles"
"$(realpath ../tmp/packages):/packages"
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
        "${DOCKER}" tag "${NAMESPACE}/${BUILDER_COMMIT_ID}:${DATE}" "${NAMESPACE}/${BUILDER_COMMIT_ID}:latest" ||
            die "failed to tag ${BUILDER_COMMIT_ID}"
    fi

    REPO_ID=$REPO
    #[[ "$REPO" == ${BUILDER_CORE} ]] && REPO_ID=${BUILDER_CORE}

    msg "build ${REPO}:${DATE}"
    "${DOCKER}" build ${BUILD_OPTS} -t "${REPO_ID}:${DATE}" "${REPO_EXPANDED}" || die "failed to build ${REPO_EXPANDED}"

    msg "tag ${REPO}:latest"
    "${DOCKER}" tag "${REPO_ID}:${DATE}" "${REPO_ID}:latest" || die "failed to tag ${REPO_EXPANDED}"

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
        echo "${DOCKER}" tag "${IMAGE_DOCKER_ID}" ${PUSH_ARGS}
        "${DOCKER}" tag "${IMAGE_DOCKER_ID}" "${PUSH_ARGS}" || exit 1
    fi
    echo "pushing ${PUSH_ARGS}"
    "${DOCKER}" push "${PUSH_ARGS}" || exit 1
}
