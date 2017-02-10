#!/bin/bash
#
# Copyright (C) 2014-2015 Erik Dannenberg <erik.dannenberg@bbe-consulting.de>
#
# Based on https://github.com/wking/dockerfile/blob/master/build.sh
#
# --- original license and (C):
#
# Copyright (C) 2013-2014 W. Trevor King <wking@tremily.us>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

PROJECT_ROOT=$(dirname $(realpath $0))
DL_PATH="${DL_PATH:-${PROJECT_ROOT}/tmp/downloads}"

# read global build.conf
[[ ! -f "${PROJECT_ROOT}/build.conf" ]] && echo "error: could not find ${PROJECT_ROOT}/build.conf" && exit 1
source ./build.conf

IMAGE_TAG_ROOT="${IMAGE_TAG?Error \$IMAGE_TAG is not defined.}"
NAMESPACE_ROOT="${NAMESPACE:-gentoobb}"

BUILD_OPTS="${BUILD_OPTS:-}"

SKIP_GPG="${SKIP_GPG:-false}"
EXCLUDE="${EXCLUDE:-}"

REQUIRED_BINARIES="awk bzip2 grep id wget"
[ "${SKIP_GPG}" != "false" ] && REQUIRED_BINARIES+=" gpg"
[[ $(command -v sha512sum) ]] && REQUIRED_BINARIES+=" sha512sum" || REQUIRED_BINARIES+=" shasum"

[ ! -f "${PROJECT_ROOT}/inc/core.sh" ] && echo "error: Could not find ${PROJECT_ROOT}/inc/core.sh" && exit 1
source "${PROJECT_ROOT}/inc/core.sh"

# Populate BUILD_ORDER by checking image dependencies
#
# Arguments:
#
# 1: REPOS
generate_build_order()
{
    # generate image build order
    REQUIRED_BUILDER=""
    REQUIRED_ENGINES=""
    for REPO in $1; do
        check_image_dependencies ${REPO}
        if [ -z "$BUILD_ORDER" ]; then
            BUILD_ORDER="${REPO}"
        else
            ! string_has_word "${BUILD_ORDER}" ${REPO} && BUILD_ORDER+=" ${REPO}"
        fi
    done
    # generate builder build order
    BUILD_ORDER_BUILDER=""
    REQUIRED_CORES=""
    for BUILDER_ID in $REQUIRED_BUILDER; do
        check_builder_dependencies ${BUILDER_ID}
        if [ -z "$BUILD_ORDER_BUILDER" ]; then
            BUILD_ORDER_BUILDER="${BUILDER_ID}"
        else
            ! string_has_word "${BUILD_ORDER_BUILDER}" ${BUILDER_ID} && BUILD_ORDER_BUILDER+=" ${BUILDER_ID}"
        fi
    done
    # remove excluded repos
    IFS=', ' read -a EXCLUDE_ARRAY <<< "$EXCLUDE"
    for excluded_repo in "${EXCLUDE_ARRAY[@]}";do
        BUILD_ORDER=${BUILD_ORDER/$excluded_repo/}
    done
    read BUILD_ORDER <<< $BUILD_ORDER
}

# Check image dependencies and populate BUILD_ORDER/REQUIRED_BUILDER/REQUIRED_ENGINES. Recursive.
#
# Arguments:
#
# 1: REPO
# 2: PREV_REPO
check_image_dependencies()
{
    local REPO_EXPANDED="${1}"
    # add image path if missing
    [[ $REPO_EXPANDED != *"/${IMAGE_PATH}"* ]] && REPO_EXPANDED=${REPO_EXPANDED/\//\/${IMAGE_PATH}}
    if [ "${1}" != "scratch" ]; then
        source_image_conf $REPO_EXPANDED

        # collect required engines
        ! string_has_word "${REQUIRED_ENGINES}" ${CONTAINER_ENGINE} && REQUIRED_ENGINES+=" ${CONTAINER_ENGINE}"

        # collect required build containers
        IMAGE_BUILDER=$(get_image_builder "${1}" "${IMAGE_PATH}")
        [[ $? == 1 ]] && die "error executing get_image_builder(): ${IMAGE_BUILDER}"
        if [[ "${IMAGE_BUILDER}" != "" ]];then
             ! string_has_word "${REQUIRED_BUILDER}" ${IMAGE_BUILDER} && REQUIRED_BUILDER+=" ${IMAGE_BUILDER}"
        else
            # add default build container of current namespace
            ! string_has_word "${REQUIRED_BUILDER}" ${DEFAULT_BUILDER} && REQUIRED_BUILDER+=" ${DEFAULT_BUILDER}"
        fi

        PARENT_IMAGE=$(get_parent_image "${1}" "${IMAGE_PATH}")
        [[ $? == 1 ]] && die "error executing get_parent_image(): ${PARENT_IMAGE}"
        if [[ "${PARENT_IMAGE}" != "" ]]; then
            # skip further checking if already processed
            if ! string_has_word "${BUILD_ORDER}" ${1}; then
                # add parent image dependencies
                check_image_dependencies $PARENT_IMAGE $1
                [[ "${2}" != "" ]] && BUILD_ORDER+=" ${1}"
            fi
        fi
    fi
}

# Check builder dependencies and populate BUILD_ORDER_BUILDER. Recursive.
#
# Arguments:
#
# 1: BUILDER_REPO
# 2: PREV_BUILDER_REPO
check_builder_dependencies() {
    local REPO_EXPANDED="${1}"
    # add builder path if missing
    [[ $REPO_EXPANDED != *"/${BUILDER_PATH}"* ]] && REPO_EXPANDED=${REPO_EXPANDED/\//\/${BUILDER_PATH}}
    source_image_conf "${REPO_EXPANDED}"
    [[ ! -z "${STAGE3_BASE}" ]] && ! string_has_word "${REQUIRED_CORES}" "${STAGE3_BASE}" && REQUIRED_CORES+=" ${STAGE3_BASE}"
    # skip further checking if already processed
    if ! string_has_word "${BUILD_ORDER_BUILDER}" ${1}; then
        if [[ -z "${STAGE3_BASE}" ]]; then
            PARENT_BUILDER=$(get_build_container "${1}" "${BUILDER_PATH}")
            [[ $? == 1 ]] && die "error executing get_parent_builder(): ${PARENT_BUILDER}"
            check_builder_dependencies ${PARENT_BUILDER} ${1}
        fi
        [[ "${2}" != "" ]] && BUILD_ORDER_BUILDER+=" ${1}"
    fi
}

build()
{
    if ($BUILD_WITHOUT_DEPS && [ "${1}" == "*" ]); then
        die "error: -n does not support wildcards, specify one or more repo names."
    fi

    if $BUILD_WITHOUT_DEPS; then
        cd $REPO_PATH
        for REPO in $1; do
            local REPO_EXPANDED=${REPO/\//\/${IMAGE_PATH}}
            source_image_conf ${REPO_EXPANDED}
            validate_repo ${REPO} ${IMAGE_PATH}
            build_image_no_deps ${REPO}
        done
        exit 0
    fi

    msg "generate build order"
    cd $REPO_PATH
    REPOS=$(expand_requested_repos "${1}") || die "failed to expand requested images, typo in namespace or image name?"
    generate_build_order "${REPOS}"
    msgf "required engines:" "${REQUIRED_ENGINES:1}"
    msgf "required stage3:" "${REQUIRED_CORES:1}"
    msgf "required builders:" "${BUILD_ORDER_BUILDER}"
    msgf "build sequence:" "${BUILD_ORDER}"
    [[ -n ${EXCLUDE} ]] && msgf "excluded:" "${EXCLUDE}"

    e=($REQUIRED_ENGINES)
    for ENGINE in "${e[@]}"; do
       source "${PROJECT_ROOT}/inc/engine/${ENGINE}.sh"
       validate_engine
    done

    b=($BUILD_ORDER_BUILDER)
    for REPO in "${b[@]}"; do
        local REPO_EXPANDED=${REPO/\//\/${BUILDER_PATH}}
        source_image_conf ${REPO_EXPANDED}
        validate_repo ${REPO} ${BUILDER_PATH}
        build_builder "${REPO}"
    done

    b=($BUILD_ORDER)
    for REPO in "${b[@]}"; do
        local REPO_EXPANDED=${REPO/\//\/${IMAGE_PATH}}
        source_image_conf ${REPO_EXPANDED}
        validate_repo ${REPO} ${IMAGE_PATH}
        build_image "${REPO}"
    done
}

# Update STAGE3_DATE in build.conf for all builders in all namespaces
update_stage3_date() {
    cd "${REPO_PATH}"
    for CURRENT_NS in */; do
        msg $CURRENT_NS
        local BPATH=${PROJECT_ROOT}/$REPO_PATH/${CURRENT_NS}${BUILDER_PATH}
        if [ -d "${BPATH}" ]; then
            cd $BPATH
            for CURRENT_B in  */; do
                local UPDATE_STATUS=""
                cd $PROJECT_ROOT/$REPO_PATH
                source_image_conf $CURRENT_NS/$BUILDER_PATH/$CURRENT_B
                if [[ ! -z ${STAGE3_BASE} ]]; then
                    local RFILES="$(wget -qO- ${ARCH_URL})"
                    local REGEX="${STAGE3_BASE//+/\\+}-([0-9]{8})\.tar\.bz2"
                    if [[ $RFILES =~ $REGEX ]]; then
                        local S3DATE_REMOTE="${BASH_REMATCH[1]}"
                        if [ "$STAGE3_DATE" -lt "$S3DATE_REMOTE" ]; then
                            sed -r -i s/^STAGE3_DATE=\"?\{0,1\}[0-9]*\"?/STAGE3_DATE=\"${S3DATE_REMOTE}\"/g \
                                "${BPATH}${CURRENT_B}build.conf"
                            UPDATE_STATUS="updated ${STAGE3_DATE} -> ${S3DATE_REMOTE}"
                        else
                            UPDATE_STATUS="up-to-date ${STAGE3_DATE}"
                        fi
                    else
                        UPDATE_STATUS="could not parse remote STAGE3 DATE from ${ARCH_URL}"
                    fi
                fi
                printf "      %-20s %s\n" "${CURRENT_B}" "${UPDATE_STATUS}"
            done
        else
            echo "      no build containers"
        fi
    done
}

print_add_help()
{
    msg "Create a namespace or image from templates. Syntax: \n
         ./build.sh add namespace <name>
         ./build.sh add builder <namespace>/<builder_name>
         ./build.sh add image <namespace>/<image_name>"
}

add_from_template()
{
    local type="${1}"
    local name="${2}"
    if [ -z "$type" ] || [ -z "$name" ]; then
        print_add_help && die
    fi

    tmpl_namespace=${name%%/*}
    tmpl_image_name=${name##*/}

    case $type in
        namespace)
                local ns_path="./dock/${name}"
                [ -d "${ns_path}" ] && die "${ns_path} already exists, aborting!"

                echo -e ''
                msg '<enter> to accept default value\n'

                msg 'Who maintains the new namespace?'
                read -p 'Name (John Doe): ' tmpl_author
                [ -z "${tmpl_author}" ] && tmpl_author='John Doe'

                read -p 'EMail (john@doe.net): ' tmpl_author_email
                [ -z "${tmpl_author_email}" ] && tmpl_author_email='john@doe.net'

                msg 'What type of images would you like to build?'
                read -p 'Engine (docker): ' tmpl_engine
                [ -z "${tmpl_engine}" ] && tmpl_engine='docker'

                tmpl_namespace="${name}"

                [ ! -f ./inc/engine/${tmpl_engine}.sh ] && die "\nError, unknown engine: ${tmpl_engine}"

                cp -r "./inc/template/${tmpl_engine}/namespace" "${ns_path}" || die

                # replace placeholder vars in template files with actual values
                local sed_args=()
                for tmpl_var in ${!tmpl_*}; do
                    sed_args+=('-e' "s|\${${tmpl_var}}|${!tmpl_var}|g")
                done
                for nsfile in ./dock/${name}/*; do
                    replace_in_file "${nsfile}" sed_args[@]
                done

                echo -e ''
                msg "Successfully added ${name} namespace at ./dock/${name}

If you want to manage the new namespace with git you may want to run:

git init ./dock/${name}

To add new images run:

./build.sh add image ${name}/foo
"
                ;;
        image)
                if [ -z "${tmpl_namespace}" ] || [ -z "${tmpl_image_name}" ]; then
                    die "Error: ${name} should have format <namespace>/<image>"
                fi

                [ -f "./dock/${tmpl_namespace}/build.conf" ] && source "./dock/${tmpl_namespace}/build.conf" \
                    || die "Error: could not read ./dock/${tmpl_namespace}/build.conf

You can create a new namespace by running: ./build.sh add namespace ${tmpl_namespace}
"

                local image_base_path="./dock/${tmpl_namespace}/images"
                local image_path="${image_base_path}/${tmpl_image_name}"

                [ -d "${image_path}" ] && die "${image_path} already exists, aborting!"
                [ ! -d "${image_base_path}" ] && mkdir -p "${image_base_path}"

                echo -e ''
                msg '<enter> to accept default value\n'

                msg 'Do you want to extend an existing image? Full image id (i.e. gentoobb/busybox) or scratch'
                read -p 'Parent Image (scratch): ' tmpl_image_parent
                [ -z "${tmpl_image_parent}" ] && tmpl_image_parent='scratch'

                cp -r "./inc/template/${CONTAINER_ENGINE}/image" "${image_path}" || die

                # replace placeholder vars in template files with actual values
                local sed_args=()
                for tmpl_var in ${!tmpl_*}; do
                    sed_args+=('-e' "s|\${${tmpl_var}}|${!tmpl_var}|g")
                done
                for imgfile in ${image_path}/*; do
                    replace_in_file "${imgfile}" sed_args[@]
                done

                echo -e ''
                msg "Successfully added ${name} image at ${image_path}\n"
                ;;
        builder)
                echo "not yet implemented, you may want to copy a builder in ./dock/gentoobb/builder/ in the meantime."
                ;;
        *)
                msg "unknown type: ${type}, should be namespace,builder or image.."
                print_add_help && die
                ;;
    esac
}

clean_project_artifacts()
{
    msg "removing all rootfs.tar files"
    find "${PROJECT_ROOT}/${REPO_PATH}" -name rootfs.tar -exec rm {} \;
    msg "removing all PACKAGES.md files"
    find "${PROJECT_ROOT}/${REPO_PATH}" -name PACKAGES.md -exec rm {} \;
}

# List images that are not build yet
missing()
{
    cd $REPO_PATH
    for NS in ${1}; do
        for REPO in ${NS}/images/*; do
            source_namespace_conf ${REPO}
            ! image_exists "${REPO/${IMAGE_PATH}/}" && msg "${REPO/${IMAGE_PATH}/}"
        done
    done
}

has_required_binaries

while getopts ":fFcCnsh" opt; do
  case $opt in
    f)
      FORCE_REBUILD=true
      ;;
    F)
      FORCE_ROOTFS_REBUILD=true
      ;;
    c)
      FORCE_BUILDER_REBUILD=true
      ;;
    C)
      FORCE_FULL_REBUILD=true
      ;;
    n)
      BUILD_WITHOUT_DEPS=true
      ;;
    s)
      SKIP_GPG=true
      ;;
    h)
      ACTION="help"
  esac
done
shift $(( $OPTIND -1 ))

if [ -z "$ACTION" ]; then
    ACTION="${1:-build}"
fi
shift
REMAINING_ARGS="${@:-"*"}"

case "${ACTION}" in
    add) add_from_template $REMAINING_ARGS;;
    clean) clean_project_artifacts;;
    build) build "$REMAINING_ARGS";;
    update) update_stage3_date;;
    missing) missing "$REMAINING_ARGS";;
    help) msg "usage: ${0} [-n, -f, -F, -c, -C, -h] {add|build|update|missing} [repo ...]
    -f force repo rebuild
    -F also rebuild repo rootfs tar ball
    -c rebuild building/core containers
    -C also rebuild stage3 import containers, a.k.a everything
    -n do not build repo dependencies for given repo(s)
    -s skip gpg validation on downloaded files
    -h help" ;;
*) die "invalid action '${ACTION}'" ;;
esac
