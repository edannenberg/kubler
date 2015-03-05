#!/bin/bash
#
# Author: Erik Dannenberg <erik.dannenberg@bbe-consulting.de>
#

###
### REQUIRED
###

# Is dummy engine functional?
validate_engine() {
    #REQUIRED_BINARIES+=" some-command some-other-command"
    #has_required_binaries
    msg "validate dummy engine"
}

# Check if given REPO has required files, etc.
#
# Arguments:
# 1: REPO (i.e. gentoobb/busybox)
# 2: REPO_TYPE ($IMAGE_PATH or $BUILDER_PATH)
validate_repo() {
    local REPO_EXPANDED=${1/\//\/${2}}
    #[ ! -f ${REPO_EXPANDED}/Somefile ] && die "failed to read ${REPO_EXPANDED}/Somefile"
    msg "validate dummy repo: ${REPO_EXPANDED}"
}

# Produces the final image.
#
# Arguments:
# 1: IMAGE_REPO (i.e. gentoobb/busybox)
build_image() {
    msg "building dummy image: ${1}"
    # finish PACKAGES.md when using build-root.sh once the build is done:
    #add_documentation_header "${1}" "${IMAGE_PATH}" || die "failed to generate PACKAGES.md for ${1}"
}

# Exits with signal 0 if given IMAGE_REPO has a built and ready to run image or signal 3 if not.
#
# Arguments:
# 1: IMAGE_REPO (i.e. gentoobb/busybox)
image_exists() {
    return 3
}

# Returns image size for given IMAGE_REPO, required for generating PACKAGES.md header
#
# Arguments:
# 1: IMAGE_REPO (i.e. gentoobb/busybox)
# 2: DATE/TAG
get_image_size() {
    echo "xxMB"
}

# Start a container from given IMAGE_REPO.
#
# Arguments:
# 1: IMAGE_REPO (i.e. gentoobb/busybox)
# 2: CONTAINER_HOST_NAME
run_image() {
    msg "running dummy image: ${1} with"
    msg " mounts: ${CONTAINER_MOUNTS[@]}"
    msg " env: ${CONTAINER_ENV[@]}"
    msg " cmd: ${CONTAINER_CMD[@]}"
}

###
### OPTIONAL (to implement that is, deleting any stubs is asking for trouble)
###

# This function is called only once per run. Usually used to bootstrap the initial rootfs build container by
# preparing a stage3 with portage plus the files from /bob-core.
build_core() {
    #download_stage3
    msg "building dummy core"
}

# Produces a build container image for given BUILDER_REPO
# Implement this if you want support for multiple build containers.
#
# Arguments:
# 1: BUILDER_REPO (i.e. gentoobb/bob)
build_builder() {
    msg "building dummy builder: ${DEF_BUILD_CONTAINER}"
}

# Called when using the -n flag of build.sh, in most cases a thin wrapper to build_image()
#
# Arguments:
# 1: IMAGE_REPO (i.e. gentoobb/busybox)
build_image_no_deps() {
    # some initial steps
    # ..
    # build the image
    build_image "${1}"
}

# Returns parent build container name of given BUILDER_REPO or signal 3 if not found/implemented.
# Implement this if you have dependencies between your build containers. Used to generate BUILDER_BUILD_ORDER.
# (i.e. builder A is based builder B)
#
# Arguments:
# 1: BUILDER_REPO (i.e. gentoobb/bob)
# 2: REPO_TYPE ($IMAGE_PATH or $BUILDER_PATH)
get_parent_builder() {
    exit 3
}

# Returns build container required to build given IMAGE_REPO or signal 3 if not found/implemented.
# Implement this if you have multiple build containers besides the core builder. Used to generate REQUIRED_BUILDERS.
# (i.e. Image A needs build container B, Image C needs build container D)
#
# Arguments:
# 1: IMAGE_REPO (i.e. gentoobb/busybox)
# 2: REPO_TYPE ($IMAGE_PATH or $BUILDER_PATH)
get_image_builder() {
    exit 3
}

# Returns build container required to build given REPO or signal 3 if not found/implemented.
# Wrapper for get_image_builder() in case of more complex builder name logic. (see docker.sh for example)
# 
# Arguments:
# 1: REPO
# 2: REPO_TYPE ($IMAGE_PATH or $BUILDER_PATH)
get_build_container() {
    get_image_builder ${1} ${2}
}

# Returns parent image container name of given IMAGE_REPO or signal 3 if not found/implemented.
# Implement this if you have dependencies between your image containers. Used to generate BUILD_ORDER.
# (i.e. image A is based on image B)
#
# Arguments:
# 1: IMAGE_REPO (i.e. gentoobb/busybox)
# 2: REPO_TYPE ($IMAGE_PATH or $BUILDER_PATH)
get_parent_image() {
    exit 3
}

# Handle image repository auth
#
# Arguments:
# 1: NAMESPACE (i.e. gentoobb)
# 2: REPOSITORY_URL
push_auth() {
    msg "logging into dummy repository"
}

# Push image to a repository
#
# Arguments:
# 1: IMAGE_ID (i.e. gentoobb/busybox)
# 2: REPOSITORY_URL
push_image() {
    msg "pushing ${1} to dummy repository at ${2}"
}
