#!/usr/bin/env bash
#
# Copyright (c) 2014-2019, Erik Dannenberg <erik.dannenberg@xtrade-gmbh.de>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
# following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following
#    disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
#    following disclaimer in the documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# declare some vars to satisfy shellcheck
declare _keep_headers _keep_static_libs _headers_from _static_libs_from _iconv_from

# lib dir name may vary for some stage3, musl for example only uses lib/ while glibc uses lib64/
# shellcheck disable=SC2046
_LIB="$(portageq envvar LIBDIR_$(portageq envvar ARCH))"
readonly _LIB
readonly _EMERGE_ROOT="/emerge-root"
readonly _CONFIG="/config"
readonly _ROOTFS_BACKUP="/backup-rootfs"
readonly _PACKAGE_INSTALLED="${_ROOTFS_BACKUP}/package.installed"
readonly _DOC_PACKAGE_INSTALLED="${_ROOTFS_BACKUP}/doc.package.installed"
readonly _DOC_PACKAGE_PROVIDED="${_ROOTFS_BACKUP}/doc.package.provided"
readonly _DOC_FOOTER_PURGED="${_ROOTFS_BACKUP}/doc.footer.purged"
readonly _DOC_FOOTER_INCLUDES="${_ROOTFS_BACKUP}/doc.footer.includes"
readonly _PORTAGE_LOGDIR="${_CONFIG}/log"

_emerge_bin="${BOB_EMERGE_BIN:-emerge}"
_emerge_opt="${BOB_EMERGE_OPT:-}"

BOB_KEEP_BUILD_LOG="${BOB_KEEP_BUILD_LOG:-false}"
BOB_UPDATE_WORLD="${BOB_UPDATE_WORLD:-false}"

# Arguments:
# 1: exit_message as string
# 2: exit_code as int, optional, default: 1
function die() {
    local exit_code
    exit_code="${2:-1}"
    echo -e 'fatal:' "$1" >&2
    exit "${exit_code}"
}

# Copy libgcc/libstdc++ libs
function copy_gcc_libs() {
    local lib_gcc lib_gomp lib_stdc lib
    mkdir -p "${_EMERGE_ROOT}/${_LIB}"
    lib_gcc="$(find /usr/lib/ -name libgcc_s.so.1)"
    lib_gomp="$(find /usr/lib/ -name libgomp.so.1)"
    lib_stdc="$(find /usr/lib/ -name libstdc++.so.6)"

    for lib in "${lib_gcc}" "${lib_gomp}" "${lib_stdc}"; do
        cp "${lib}" "${_EMERGE_ROOT}/${_LIB}/"
    done
}

# Fix profile symlink as we don't use default portage location, part of stage3 builder setup
#
# Arguments:
# 1: new_portage_path, optional, default: /var/sync
function fix_portage_profile_symlink() {
    local new_portage_path old_profile
    new_portage_path="${1:-/var/db/repos/gentoo}"
    old_profile="$(readlink -m /etc/portage/make.profile)"
    # strip old portage profiles base path
    old_profile="${old_profile#/usr/portage/}"
    # strip new base path used since 20190715
    old_profile="${old_profile#/var/db/repos/gentoo/}"
    new_portage_path="${new_portage_path}/${old_profile}"
    rm /etc/portage/make.profile
    echo "switching portage profile to: ${new_portage_path}"
    ln -sr "${new_portage_path}" /etc/portage/make.profile
}

# Clone a fork of hasufell/portage-gentoo-git-config and copy postsync hooks, part of stage3 builder setup
function install_git_postsync_hooks() {
    git clone https://github.com/srcshelton/portage-gentoo-git-config.git gitsync
    cp ./gitsync/repo.postsync.d/sync_* /etc/portage/repo.postsync.d/
    chmod +x /etc/portage/repo.postsync.d/sync_*
    rm -r ./gitsync
    # not required when using gentoo-mirror/gentoo.git
    chmod -x /etc/portage/repo.postsync.d/sync_gentoo_cache
}

# Setup eix and init db
function configure_eix() {
    eix-update
    # configure post-sync
    mkdir -p /etc/portage/postsync.d/
    ln -s /usr/bin/eix-postsync /etc/portage/postsync.d/50-eix-postsync
    ln -s /usr/bin/eix-diff /etc/portage/postsync.d/51-eix-diff
}

# Extract saved resources, like headers, from a parent image.
#
# Arguments:
# 1: resource_suffix, i.e. "headers" or "static_libs"
function extract_build_dependencies() {
    local resource_suffix resource_var parent_image parent_file
    resource_suffix="${1}"
    resource_var="_${resource_suffix}_from"
    if [ -n "${!resource_var}" ]; then
        for parent_image in ${!resource_var}; do
            parent_file="${_ROOTFS_BACKUP}/${parent_image/\//_}-${resource_suffix}.tar"
            [[ -f "${parent_file}" ]] && tar xpf "${parent_file}"
        done
    fi
}

# Find package version of given Gentoo package atom
#
# Arguments:
# 1: package_atom
function get_package_version() {
    __get_package_version=
    local package
    package="$1"
    nameversion="$(equery --quiet list "${package}")" \
        || die "Couldn't parse package version for ${package}"
    # shellcheck disable=SC2034
    __get_package_version="${nameversion}"
}

function generate_documentation_footer() {
    echo "#### Purged" > "${_DOC_FOOTER_PURGED}"
    write_checkbox_line "Headers" "${_keep_headers}" "${_DOC_FOOTER_PURGED}" "negate"
    write_checkbox_line "Static Libs" "${_keep_static_libs}" "${_DOC_FOOTER_PURGED}" "negate"
    if [[ -n "${_headers_from}" ]] || [[ -n "${_static_libs_from}" ]] || [[ -n "${_iconv_from}" ]]; then
        echo -e '\n#### Included' > "${_DOC_FOOTER_INCLUDES}"
        if [[ -n "${_headers_from}" ]]; then
            write_checkbox_line "Headers from ${_headers_from}" "checked" "${_DOC_FOOTER_INCLUDES}"
        fi
        if [[ -n "${_static_libs_from}" ]]; then
            write_checkbox_line "Static Libs from ${_static_libs_from}" "checked" "${_DOC_FOOTER_INCLUDES}"
        fi
        if [[ -n "${_iconv_from}" ]]; then
            write_checkbox_line "Glibc Iconv Encodings" "checked" "${_DOC_FOOTER_INCLUDES}"
        fi
    fi
}

function generate_documentation() {
    local doc_file table_header
    doc_file="${_CONFIG}/PACKAGES.md"
    table_header='Package | USE Flags\n--------|----------'
    echo "#### Installed" > "${doc_file}"
    if [[ -f "${_DOC_PACKAGE_INSTALLED}" ]]; then
        echo -e "${table_header}" >> "${doc_file}"
        sed -e "1d" < "${_DOC_PACKAGE_INSTALLED}" >> "${doc_file}"
    else
        echo "None." >> "${doc_file}"
    fi
    echo "#### Inherited" >> "${doc_file}"
    echo -e "${table_header}" >> "${doc_file}"
    if [[ -f "${_DOC_PACKAGE_PROVIDED}" ]]; then
        cat "${_DOC_PACKAGE_PROVIDED}" >> "${doc_file}"
    else
        echo "**FROM scratch** |" >> "${doc_file}"
    fi
    if [[ -f "${_DOC_FOOTER_PURGED}" ]]; then
        cat "${_DOC_FOOTER_PURGED}" >> "${doc_file}"
    fi
    if [[ -f "${_DOC_FOOTER_INCLUDES}" ]]; then
        cat "${_DOC_FOOTER_INCLUDES}" >> "${doc_file}"
    fi
    chown "${BOB_HOST_UID}":"${BOB_HOST_GID}" "${doc_file}"
}

# Appends a github markdown line with a checkbox and label to given file.
#
# Arguments:
# 1: checkbox label
# 2: is checked
# 3: out_file
# 4: negate checked state, when set the true/false eval of $2 is negated, optional
function write_checkbox_line() {
    local label checked out_file negate_checked_state state checkbox
    label="$1"
    checked="$2"
    out_file="$3"
    negate_checked_state="$4"
    if [[ -z "${checked}" || "${checked}" == "false" ]]; then
        state=0
    else
        state=1
    fi
    if [[ -n ${negate_checked_state} ]]; then
        if [[ "${state}" == 1 ]]; then
            state=0
        else
            state=1
        fi
    fi
    if [[ "${state}" == 1 ]]; then
        checkbox="- [x]"
    else
        checkbox="- [ ]"
    fi
    echo "${checkbox} ${label}" >> "${out_file}"
}

# Generates $_PACKAGE_INSTALLED from provided portage package atoms,
# should only get called from configure_rootfs_build() hook
#
# Arguments:
# n: packages (i.e. "sys-apps/busybox dev-vcs/git")
function generate_package_installed() {
    local packages current_emerge_opts emerge_ret
    packages=( "$@" )
    # disable binary package features temporarily to work around binpkg_multi_instance altering the version string
    current_emerge_opts="${EMERGE_DEFAULT_OPTS}"
    export EMERGE_DEFAULT_OPTS=""
    # generate installed package list
    set +e
    # shellcheck disable=SC2086,SC2068
    "${_emerge_bin}" ${_emerge_opt} --binpkg-respect-use=y -p ${packages[@]} \
        | eix '-|*' --format '<markedversions:NAMEVERSION>' > "${_PACKAGE_INSTALLED}"
    emerge_ret=$?
    [[ ${emerge_ret} -gt 1 ]] && echo "Error generating package.installed" && exit ${emerge_ret}
    set -e
    # enable binary package features again
    export EMERGE_DEFAULT_OPTS="${current_emerge_opts}"
}

# Append DOC_PACKAGE_INSTALLED from last build to $_DOC_PACKAGE_PROVIDED, overwrite $_DOC_PACKAGE_INSTALLED
# with header for current build. Should only get called from configure_bob() or configure_rootfs_build() hooks
#
# Arguments:
# 1: image_name (only used in header)
function init_docs() {
    local image_name
    image_name="${1}"
    touch -a "${_DOC_PACKAGE_PROVIDED}"
    [[ -f "${_DOC_PACKAGE_INSTALLED}" ]] && \
        echo -e "$(cat "${_DOC_PACKAGE_INSTALLED}")\\n$(cat "${_DOC_PACKAGE_PROVIDED}")" > "${_DOC_PACKAGE_PROVIDED}"

    echo "**FROM ${image_name}** |" > "${_DOC_PACKAGE_INSTALLED}"
}

# Generates $_DOC_PACKAGE_INSTALLED from provided portage package atoms,
# should only get called from configure_rootfs_build() hook
#
# Arguments:
# n: packages (i.e. "shell/bash dev-vcs/git")
function generate_doc_package_installed() {
    local packages current_emerge_opts
    packages=( "$@" )
    # disable binary package features temporarily to work around binpkg_multi_instance altering the version string
    current_emerge_opts="${EMERGE_DEFAULT_OPTS}"
    export EMERGE_DEFAULT_OPTS=""
    # generate installed package list with use flags
    # shellcheck disable=SC2086,SC2068
    "${_emerge_bin}" ${_emerge_opt} --binpkg-respect-use=y -p ${packages[@]} \
        | perl -nle 'print "$1 | `$3`" if /\[.*\] (.*) to \/.*\/( USE=")?([a-z0-9\- (){}]*)?/' \
        | sed /^virtual/d | sort -u >> "${_DOC_PACKAGE_INSTALLED}"
    # enable binary package features again
    export EMERGE_DEFAULT_OPTS="${current_emerge_opts}"
}

# Adds a package entry in $_DOC_PACKAGE_INSTALLED to document non-Portage package installs.
# You should only use this function from the finish_rootfs_build() hook.
#
# Arguments:
# 1: package group (for example "gem" if you installed ruby gems)
# 2: package-version
# 3: optional string that appears in the use flags column
function log_as_installed() {
    echo "*${1}*: ${2} | ${3}" >> "${_DOC_PACKAGE_INSTALLED}"
}

# Thin wrapper for modern (2023, 0.99.x) app-portage/flaggie, a tool for managing portage keywords and use flags
#
# Examples:
#
# global use flags: update_use -readline +ncurses
# per package: update_use app-shells/bash +readline -ncurses
# same syntax for keywords: update_use app-shells/bash +~amd64
# target package versions as usual, remember to use quotes for < or >: update_use '>=app-text/docbook-sgml-utils-0.6.14-r1' +jadetex
# reset use/keyword to default: update_use app-shells/bash %readline %ncurses %~amd64
# reset all use flags: update_use app-shells/bash %
function update_use() {
    # shellcheck disable=SC2068
    flaggie --no-diff ${@}
}

# Just for better readability of build.sh
function update_keywords() {
    # shellcheck disable=SC2068
    update_use ${@}
}

function mask_package() {
    echo "$1" >> /etc/portage/package.mask/bob
}

function unmask_package() {
    echo "$1" >> /etc/portage/package.unmask/bob
}

# Unmask given use flag for given package atom
#
# 1: package atom (i.e. app-shells/bash)
# 2: use flag to be unmasked, ommit the leading dash (i.e. just 'gentoo-vm' instead of '-gentoo-vm')
function unmask_use () {
    echo "$1" -"$2" >> /etc/portage/profile/package.use.mask
}

# Fake package install by adding it to package.provided
# Usually called from configure_rootfs_build() hook.
#
# Arguments:
# 1: package atom (i.e. app-shells/bash)
# n: more package atoms
function provide_package() {
    # disable binary package features temporarily to work around binpkg_multi_instance altering the version string
    local current_emerge_opts package
    current_emerge_opts="${EMERGE_DEFAULT_OPTS}"
    export EMERGE_DEFAULT_OPTS=""
    [[ ! -f /etc/portage/profile/package.provided ]] && touch /etc/portage/profile/package.provided
    # shellcheck disable=SC2068
    for package in ${@}; do
        ! grep -q "${package}" /etc/portage/profile/package.provided || continue
        "${_emerge_bin}" --binpkg-respect-use=y -p "${package}" | \
            eix '-|*' --format '<markedversions:NAMEVERSION>' | \
            grep "${package}" >> /etc/portage/profile/package.provided
    done
    # enable binary package features again
    export EMERGE_DEFAULT_OPTS="${current_emerge_opts}"
}

# Mark package atom for reinstall.
# Usually called from configure_rootfs_build() hook.
#
# Arguments:
# 1: package atom (i.e. app-shells/bash)
# n: more package atoms
function unprovide_package() {
    local pkg_provided package
    pkg_provided="/etc/portage/profile/package.provided"
    if [[ -f "${pkg_provided}"  ]]; then
        # shellcheck disable=SC2068
        for package in ${@}; do
            sed -i'' /^"${package//\//\\\/}"/d "${pkg_provided}"
        done
    fi
}

# Remove packages that were only needed at build time, also cleans ${DOC_PACKAGE_INSTALLED}
# Usually called from finish_rootfs_build() hook.
#
# Arguments:
# 1: package atom (i.e. app-shells/bash)
# n: more package atoms
function uninstall_package() {
    local package
    # shellcheck disable=SC2068
    emerge -C ${@}
    # shellcheck disable=SC2068
    for package in ${@}; do
        # reflect uninstall in docs
        sed -i'' /^"${package//\//\\\/}"/d "${_DOC_PACKAGE_INSTALLED}"
    done
}

# Add given patch to Portage's patch dir (/etc/portage/patches)
#
# Arguments:
# 1: package_atom (i.e. app-shells/bash, you may also append the slot or a specific version)
# 2: patch_url
# 3: patch_name - optional, default: use last fragment of patch_url
function add_patch() {
    local package_atom patch_url patch_name patch_dir
    package_atom="$1"
    patch_url="$2"
    patch_name="$3"
    patch_dir="/etc/portage/patches/${package_atom}"
    [ ! -d "${patch_dir}" ] && mkdir -p "${patch_dir}"
    [ -z "${patch_name}" ] && patch_name="${patch_url##*/}"
    [[ "${patch_name}" != *.patch && "${patch_name}" != *.diff ]] && patch_name+='.patch'
    download_file "${patch_url}" "${patch_name}"
    cp "${__download_file}" "${patch_dir}"
}

# Check if given search_id is an installed portage overlay repo_id.
# Returns exit code 0 if true or 3 if not.
#
# Arguments:
# 1: search_id
function is_installed_overlay() {
    local search_id repo_id
    search_id="$1"
    while read -r repo_id; do
        [[ "${search_id}" == "${repo_id}" ]] && return 0
    done < <(eselect repository list -i | awk '{if(NR>1)print $2}')
    return 3
}

# Add Gentoo overlay to repos.conf/ and sync it, thin wrapper for eselect repository module.
# Example usage: add_overlay musl
#
# Arguments:
#
# 1: repo_id - reference used in repos.conf
# 2: repo_url - optional, default: assume repo_id is in eselect repository list
# 3: repo_mode - optional, default: git
function add_overlay() {
    local repo_id repo_url repo_mode
    repo_id="$1"
    repo_url="$2"
    repo_mode="${3:-git}"
    # skip if there already is an installed overlay for given repo_id
    is_installed_overlay "${repo_id}" && return 0
    if [[ -z "${repo_url}" ]]; then
      eselect repository enable "${repo_id}"
    else
      eselect repository add "${repo_id}" "${repo_mode}" "${repo_url}"
    fi
    emaint sync -r "${repo_id}"
}

function install_oci_deps() {
    local acserver_path
    export GOPATH='/go'
    export PATH="${PATH}:${GOPATH}/bin"
    # install acbuild
    git clone https://github.com/containers/build
    cd build/ && ./build
    cp ./bin/acbuild* /usr/local/bin/
    cd ..
    rm -r build/
    # install acserver
    acserver_path="${GOPATH}/src/github.com/appc/acserver"
    git clone https://github.com/appc/acserver.git "${acserver_path}"
    cd "${acserver_path}"
    ./gomake
    cp ./dist/acserver-v0-linux-amd64/acserver /usr/bin
}

# Download file at given url to /distfiles as given file_name if it doesn't exist yet. If no file_name is given the last
# fragment of given url is used. Any further args are passed to curl as is. Curl execution is trapped and partially
# downloaded files are removed on abort.
# Returns used file_name including absolute path.
#
# Arguments:
#
# 1: url
# 2: file_name,- optional, default: use last fragment of url, you may also pass an empty string for default behaviour
# n: curl_args - optional, all further args are passed to curl
# Return value: absolute path of downloaded file_name
function download_file() {
    __download_file=
    local url file_name file_abs curl_args
    url="$1"
    shift
    file_name=
    if [[ "$#" -gt 0 ]]; then
        [[ -n "$1" ]] && file_name="$1"
        shift
        [[ "$#" -gt 0 ]] && curl_args=("$@")
    fi

    [[ -z "${file_name}" ]] && file_name="${url##*/}"

    file_abs="/distfiles/${file_name}"
    if [[ ! -f "${file_abs}" ]]; then
        trap 'handle_download_error "${file_abs}"' EXIT
        curl -L "${url}" "${curl_args[@]}" --output "${file_abs}" || exit $?
        trap - EXIT
    fi
    __download_file="${file_abs}"
}

# Arguments:
# 1: file - full path of downloaded file
# 2: error_message - optional
function handle_download_error() {
    local file msg
    file="$1"
    msg="${2:-Aborted download of ${file}}, removed partial file on disk."
    [[ -f "${file}" ]] && rm "${file}"
    die "${msg}"
}

# Arguments:
# 1: url
function download_from_oracle() {
    __download_from_oracle=
    local url
    url="$1"
    download_file "${url}" \
                  '' \
                  '--cookie' 'gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie'
    # shellcheck disable=SC2034
    __download_from_oracle="${__download_file}"
}

# Return unix timestamp of modification date for given file_path
#
# Arguments:
# 1: file_path
function get_file_mod_stamp() {
    __get_file_mod_stamp=
    local file_path mod_date
    file_path="$1"
    mod_date="$(stat "${file_path}" | awk -F': ' '/Modify: /{print $2}')"
    __get_file_mod_stamp="$(date --date "${mod_date}"  +"%s")"
}

# Copy given file_path from builder to "${_EMERGE_ROOT}" if modification date is newer than given orig_mod_stamp.
# Creates any required paths in "${_EMERGE_ROOT}" if missing.
#
# Arguments
# 1: file_path
# 2: orig_mod_stamp
function copy_from_builder_if_changed() {
    local file_path orig_mod_stamp target_path
    file_path="$1"
    orig_mod_stamp="$2"
    get_file_mod_stamp "${file_path}"
    if [[ "${orig_mod_stamp}" -lt "${__get_file_mod_stamp}" ]]; then
        target_path="$(dirname "${_EMERGE_ROOT}/${file_path}")"
        [[ -d "${target_path}" ]] || mkdir -p "${target_path}"
        cp -f "${file_path}" "${target_path}"
    fi
}

function build_rootfs() {
    local target_id passwd_date group_date

    [[ -z "${BOB_CURRENT_TARGET}" || "${BOB_CURRENT_TARGET}" != *'/'* ]] \
        && echo "fatal: Expected a fully qualified image id in BOB_CURRENT_TARGET." && return 1
    target_id="${BOB_CURRENT_TARGET}"

    # shellcheck disable=SC1091
    source /etc/profile

    if [[ -z "${_emerge_bin}" ]]; then
        if [[ "${CHOST}" == x86_64-pc-linux-* ]] || [[ "${CHOST}" == x86_64-gentoo-linux-* ]]; then
            _emerge_bin="emerge"
        else
            _emerge_bin="emerge-${CHOST}"
        fi
    fi

    mkdir -p "${_EMERGE_ROOT}"

    # save initial passwd/group modification date
    get_file_mod_stamp '/etc/passwd' && passwd_date="${__get_file_mod_stamp}"
    get_file_mod_stamp '/etc/group' && group_date="${__get_file_mod_stamp}"

    # read mounted config
    # shellcheck source=template/docker/image/build.sh disable=SC2015
    [[ -f "${_CONFIG}/build.sh" ]] && source "${_CONFIG}/build.sh"

    # use BOB_BUILDER_{CHOST,CFLAGS,CXXFLAGS} as they may differ when using crossdev
    export USE_BUILDER_FLAGS="true"
    # shellcheck disable=SC1091
    source /etc/profile

    # remove existing binary package cache file(s) if specified
    local no_cache_var no_cache_package current_tag cache_tag cache_tag_base bin_package_path
    for no_cache_var in ${!_no_cache*}; do
        current_tag=
        [[ "${no_cache_var}" != '_no_cache' ]] && current_tag="${no_cache_var##*_}"
        for no_cache_package in ${!no_cache_var}; do
            cache_tag=
            bin_package_path=
            [[ -n ${current_tag} ]] && cache_tag="${PKGDIR}/.no-cache-tags/${current_tag}/${no_cache_package%.xpak}"
            if [[ -n ${current_tag} && ! -e ${cache_tag} || -z ${current_tag} ]]; then
                bin_package_path="${PKGDIR}/${no_cache_package}"
                [[ -e "${bin_package_path}" ]] && rm -r "${bin_package_path}"
                if [[ -n "${current_tag}" ]]; then
                    cache_tag_base="${cache_tag}"
                    [[ "${no_cache_package}" == *'.xpak' ]] && cache_tag_base="${cache_tag%/*}"
                    mkdir -p "${cache_tag_base}"
                    [[ "${no_cache_package}" == *'.xpak' ]] && touch "${cache_tag}"
                fi
            fi
        done
    done

    # call configure_builder hook if declared in build.sh
    if declare -F configure_builder &>/dev/null; then
        configure_builder
    elif declare -F configure_bob &>/dev/null; then
        # deprecated, but still supported for a while
        configure_bob
    fi

    # switch back to BOB_{CHOST,CFLAGS,CXXFLAGS}
    unset USE_BUILDER_FLAGS
    # shellcheck disable=SC1091
    source /etc/profile

    mkdir -p "${_ROOTFS_BACKUP}"

    # set ROOT env for emerge calls
    export ROOT="${_EMERGE_ROOT}"

    # call pre install hook if declared in build.sh
    declare -F configure_rootfs_build &>/dev/null && configure_rootfs_build

    # when using a crossdev alias unset CHOST and PKGDIR to not override make.conf
    [[ "${_emerge_bin}" != "emerge" ]] && unset CHOST PKGDIR

    if [ -n "${_packages}" ]; then

        # shellcheck disable=SC2086
        generate_package_installed ${_packages}
        init_docs "${target_id}"
        # shellcheck disable=SC2086
        generate_doc_package_installed ${_packages}

        if [ -n "${BOB_INSTALL_BASELAYOUT}" ]; then
            # shellcheck disable=SC2086
            "${_emerge_bin}" ${_emerge_opt} --binpkg-respect-use=y -v sys-apps/baselayout
        fi

        if [ -d "${_PORTAGE_LOGDIR}" ]; then
            rm -r "${_PORTAGE_LOGDIR}"
        fi

        if [ "${BOB_KEEP_BUILD_LOG}" == true ]; then
            mkdir -p "${_PORTAGE_LOGDIR}"
            export PORTAGE_LOGDIR="${_PORTAGE_LOGDIR}"
        fi
        
        # install packages defined in image's build.sh
        # shellcheck disable=SC2086
        "${_emerge_bin}" ${_emerge_opt} --binpkg-respect-use=y -v ${_packages}
        [[ -f "${_PACKAGE_INSTALLED}" ]] \
            && sed -e '/^virtual/d' < "${_PACKAGE_INSTALLED}" >> /etc/portage/profile/package.provided

        # backup headers and static files, depending images can pull them in again
        if [[ -d "${_EMERGE_ROOT}/usr/include" ]]; then
            find "${_EMERGE_ROOT}/usr/include" -type f -name '*.h' | \
                tar -cpf "${_ROOTFS_BACKUP}/${target_id//\//_}-headers.tar" --files-from -
        fi
        if [[ -d "${_EMERGE_ROOT}/usr/${_LIB}" ]]; then
            find "${_EMERGE_ROOT}/usr/${_LIB}" -type f -name '*.a' | \
                tar -cpf "${_ROOTFS_BACKUP}/${target_id//\//_}-static_libs.tar" --files-from -
        fi

        # extract any possible required headers and static libs from previous builds
        for resource in "headers" "static_libs" "iconv"; do
            extract_build_dependencies "${resource}"
        done

        # merge with ld.so.conf from builder
        [[ ! -d "${_EMERGE_ROOT}"/etc/ ]] && mkdir "${_EMERGE_ROOT}"/etc/
        cat /etc/ld.so.conf >> "${_EMERGE_ROOT}"/etc/ld.so.conf
        sort -u "${_EMERGE_ROOT}"/etc/ld.so.conf -o "${_EMERGE_ROOT}"/etc/ld.so.conf

    fi

    # handle bug in portage when using custom root, any user/groups created during package installs are not created
    # at the custom root but on the host
    copy_from_builder_if_changed '/etc/passwd' "${passwd_date}"
    copy_from_builder_if_changed '/etc/group' "${group_date}"

    # call post install hook if declared in build.sh
    declare -F finish_rootfs_build &>/dev/null && finish_rootfs_build

    [[ -z "${BOB_IS_INTERACTIVE}" ]] && generate_documentation_footer

    unset ROOT PORTAGE_LOGDIR

    # /run symlink
    if [[ -n "${BOB_INSTALL_BASELAYOUT}" ]]; then
        mkdir -p "${_EMERGE_ROOT}"/{run,var} && ln -s /run "${_EMERGE_ROOT}/var/run"
    fi

    # clean up
    if [ -z "${BOB_SKIP_LIB_CLEANUP}" ]; then
        for lib_dir in "${_EMERGE_ROOT}"/{${_LIB},usr/${_LIB}}; do
            [[ -d "${lib_dir}" ]] && find "${lib_dir}" -type f \( -name '*.[co]' -o -name '*.prl' \) -delete
        done
    fi

    rm -rf \
        "${_EMERGE_ROOT}"/etc/ld.so.cache \
        "${_EMERGE_ROOT}"/usr/"${_LIB}"/qt*/mkspecs/ \
        "${_EMERGE_ROOT}"/usr/share/aclocal/ \
        "${_EMERGE_ROOT}"/usr/share/gettext/ \
        "${_EMERGE_ROOT}"/usr/share/gir-[0-9]*/ \
        "${_EMERGE_ROOT}"/usr/share/gtk-doc/* \
        "${_EMERGE_ROOT}"/usr/share/qt*/mkspecs/ \
        "${_EMERGE_ROOT}"/usr/share/vala/vapi/ \
        "${_EMERGE_ROOT}"/var/cache/edb \
        "${_EMERGE_ROOT}"/var/db/pkg/* \
        "${_EMERGE_ROOT}"/var/lib/portage \
        "${_EMERGE_ROOT}"/etc/portage \
        "${_EMERGE_ROOT}"/var/lib/gentoo

    if [[ -z "${_keep_headers}" ]]; then
        rm -rf "${_EMERGE_ROOT}"/usr/include/* \
               "${_EMERGE_ROOT}"/usr/"${_LIB}"/pkgconfig/ \
               "${_EMERGE_ROOT}"/usr/bin/*-config \
               "${_EMERGE_ROOT}"/usr/"${_LIB}"/cmake/
    fi

    local lib_dir
    for lib_dir in "${_EMERGE_ROOT}"/{"${_LIB}",usr/"${_LIB}"}; do
        if [[ -z "${_keep_static_libs}" ]] && [[ -d "${lib_dir}" ]] && [[ -n "$(ls -A "${lib_dir}")" ]]; then
            find "${lib_dir}"/* -type f -name "*.a" -delete
        fi
    done

    # just for less noise in the build output
    eselect news read new 1> /dev/null

    # if this is not an interactive build create the tar ball and clean up
    if [[ -z "${BOB_IS_INTERACTIVE}" && -n "$(ls -A "${_EMERGE_ROOT}")" ]]; then
        # make rootfs tar ball and copy to host
        tar -cpf "${_CONFIG}/rootfs.tar" -C "${_EMERGE_ROOT}" .
        chown "${BOB_HOST_UID}":"${BOB_HOST_GID}" "${_CONFIG}/rootfs.tar"
        rm -rf "${_EMERGE_ROOT}"
    fi

    if [[ -z "${BOB_IS_INTERACTIVE}" ]]; then
        generate_documentation
    else
        echo "*** Build finished, skipped rootfs.tar and PACKAGES.md"
        echo "To inspect the build result check the contents of ${_EMERGE_ROOT}"
    fi

    return 0
}

function main() {
    build_rootfs
}

[[ "${BOB_IS_DEBUG}" == 'true' ]] && set -x

if [[ "$1" != '--source-mode' ]]; then
    [[ "${BOB_IS_INTERACTIVE}" != 'true' ]] && set -e
    main
else
    set +e
    # build should always be started from script and not a sourced function, prevents container exit on error
    unset main build_rootfs
fi
