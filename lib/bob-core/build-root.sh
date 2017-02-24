#!/usr/bin/env bash

# Copyright (C) 2014-2017 Erik Dannenberg <erik.dannenberg@xtrade-gmbh.de>

set -e

readonly _EMERGE_ROOT="/emerge-root"
readonly _CONFIG="/config"
readonly _CONFIG_TMP="${_CONFIG}/tmp"
readonly _ROOTFS_BACKUP="/backup-rootfs"
readonly _PACKAGE_INSTALLED="${_ROOTFS_BACKUP}/package.installed"
readonly _DOC_PACKAGE_INSTALLED="${_ROOTFS_BACKUP}/doc.package.installed"
readonly _DOC_PACKAGE_PROVIDED="${_ROOTFS_BACKUP}/doc.package.provided"
readonly _DOC_FOOTER_PURGED="${_ROOTFS_BACKUP}/doc.footer.purged"
readonly _DOC_FOOTER_INCLUDES="${_ROOTFS_BACKUP}/doc.footer.includes"

_emerge_bin="${BOB_EMERGE_BIN:-emerge}"
_emerge_opt="${BOB_EMERGE_OPT:-}"

[ "$1" ] || {
    echo "--> Error, missing required image id"
    exit 1
}

_image="${1}"
_image_ns="${_image%%/*}"
_image_id="${_image##*/}"

# Copy libgcc/libstdc++ libs
function copy_gcc_libs() {
    local lib_gcc lib_stdc lib
    mkdir -p "${_EMERGE_ROOT}/lib64"
    lib_gcc="$(find /usr/lib/ -name libgcc_s.so.1)"
    lib_stdc="$(find /usr/lib/ -name libstdc++.so.6)"

    for lib in "${lib_gcc}" "${lib_stdc}"; do
        cp "${lib}" "${_EMERGE_ROOT}"/lib64/
    done
}

# Fix profile symlink as we don't use default portage location, part of stage3 builder setup
#
# Arguments:
# 1: new_portage_path, optional, default: /var/sync
function fix_portage_profile_symlink() {
    local new_portage_path old_profile
    new_portage_path="${1:-/var/sync}"
    _old_profile="$(readlink -m /etc/portage/make.profile)"
    rm /etc/portage/make.profile
    echo "switching portage profile to: ${new_portage_path}/${_old_profile#/usr/}"
    ln -sr "${new_portage_path}"/${_old_profile#/usr/} /etc/portage/make.profile
}

# Clone a fork of hasufell/portage-gentoo-git-config and copy postsync hooks, part of stage3 builder setup
function install_git_postsync_hooks() {
    git clone https://github.com/srcshelton/portage-gentoo-git-config.git gitsync
    cp ./gitsync/repo.postsync.d/sync_* /etc/portage/repo.postsync.d/
    chmod +x /etc/portage/repo.postsync.d/sync_*
    rm -r ./gitsync
    # not required when using gentoo-mirror/gentoo.git
    rm /etc/portage/repo.postsync.d/sync_gentoo_cache
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
function get_package_version()
{
    local package
    package="$1"
    exec 2>/dev/null
    echo $("${_emerge_bin}" -p "${package}" | grep "${package}" | sed -e "s|${package}-|${package}§|" -e 's/[\s]*USE=/§USE=/g' \
        | awk -F§ '{print $2}')
    exec 2>&1
}

function generate_documentation_footer() {
    echo "#### Purged" > "${_DOC_FOOTER_PURGED}"
    write_checkbox_line "Headers" "${_keep_headers}" "${_DOC_FOOTER_PURGED}" "negate"
    write_checkbox_line "Static Libs" "${_keep_static_libs}" "${_DOC_FOOTER_PURGED}" "negate"
    if [[ -n "${_headers_from}" ]] || [[ -n "${_static_libs_from}" ]] || [[ -n "${_iconv_from}" ]]; then
        echo -e "\n#### Included" > "${_DOC_FOOTER_INCLUDES}"
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
    table_header="Package | USE Flags\n--------|----------"
    echo "#### Installed" > "${doc_file}"
    if [[ -f "${_DOC_PACKAGE_INSTALLED}" ]]; then
        echo -e "${table_header}" >> "${doc_file}"
        cat "${_DOC_PACKAGE_INSTALLED}" | sed -e "1d" >> "${doc_file}"
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
    chown ${BOB_HOST_UID}:${BOB_HOST_GID} "${doc_file}"
}

# Appends a github markdown line with a checkbox and label to given file.
#
# Arguments:
# 1: checkbox label
# 2: is checked
# 3: out_file
# 4: negate checked state, when set the true/false eval of $2 is negated, optional
function write_checkbox_line() {
    local label checked out_file negate_check_state state checkbox
    label="$1"
    checked="$2"
    out_file="$3"
    negate_checked_state="$4"
    if [[ -z "$checked" ]] || [[ "$checked" = "false" ]]; then
        state=0
    else 
        state=1
    fi
    if [[ -n $negate_checked_state ]]; then
        if [[ "$state" == 1 ]]; then
            state=0
        else 
            state=1
        fi
    fi
    if [[ "$state" == 1 ]]; then
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
# 1: packages (i.e. "sys-apps/busybox dev-vcs/git")
function generate_package_installed() {
    local packages current_emerge_opts
    packages="$1"
    # disable binary package features temporarily to work around binpkg_multi_instance altering the version string
    current_emerge_opts="${EMERGE_DEFAULT_OPTS}"
    export EMERGE_DEFAULT_OPTS=""
    # generate installed package list
    "${_emerge_bin}" ${_emerge_opt} --binpkg-respect-use=y -p "${packages[@]}" | \
        eix '-|*' --format '<markedversions:NAMEVERSION>' > "${_PACKAGE_INSTALLED}"
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
        echo -e "$(cat "${_DOC_PACKAGE_INSTALLED}")\n$(cat "${_DOC_PACKAGE_PROVIDED}")" > "${_DOC_PACKAGE_PROVIDED}"

    echo "**FROM ${image_name}** |" > "${_DOC_PACKAGE_INSTALLED}"
}

# Generates $_DOC_PACKAGE_INSTALLED from provided portage package atoms,
# should only get called from configure_rootfs_build() hook
#
# Arguments:
# 1: packages (i.e. "shell/bash dev-vcs/git")
function generate_doc_package_installed() {
    local packages current_emerge_opts
    packages="$1"
    # disable binary package features temporarily to work around binpkg_multi_instance altering the version string
    current_emerge_opts="${EMERGE_DEFAULT_OPTS}"
    export EMERGE_DEFAULT_OPTS=""
    # generate installed package list with use flags
    "${_emerge_bin}" ${_emerge_opt} --binpkg-respect-use=y -p "${packages[@]}" | \
        perl -nle 'print "$1 | `$3`" if /\[.*\] (.*) to \/.*\/( USE=")?([a-z0-9\- (){}]*)?/' | \
        sed /^virtual/d | sort -u >> "${_DOC_PACKAGE_INSTALLED}"
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

# Thin wrapper for app-portage/flaggie, a tool for managing portage keywords and use flags
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
    flaggie --strict --destructive-cleanup ${@}
}

# Just for better readabilty of build.sh
function update_keywords() {
    update_use ${@}
}

function mask_package() {
    echo "$1" >> /etc/portage/package.mask/bob
}

function unmask_package() {
    echo "$1" >> /etc/portage/package.unmask/bob
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
    for package in ${@}; do
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
        for package in ${@}; do
            sed -i /^${package//\//\\\/}/d "${pkg_provided}"
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
    emerge -C ${@}
    for package in ${@}; do
        # reflect uninstall in docs
        sed -i /^${package//\//\\\/}/d "${_DOC_PACKAGE_INSTALLED}"
    done
}

function install_oci_deps() {
    local acserver_path
    export GOPATH=/go
    export PATH=$PATH:$GOPATH/bin
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

function install_docker_gen() {
    local dockergen_version
    dockergen_version="0.7.3"
    wget "http://github.com/jwilder/docker-gen/releases/download/${dockergen_version}/docker-gen-linux-amd64-${dockergen_version}.tar.gz"
    mkdir -p "${_EMERGE_ROOT}/bin"
    tar -C  "${_EMERGE_ROOT}/bin" -xvzf "docker-gen-linux-amd64-${dockergen_version}.tar.gz"
    mkdir -p  "${_EMERGE_ROOT}/config/template"
    log_as_installed "manual install" "docker-gen-${dockergen_version}" "http://github.com/jwilder/docker-gen/"
}

# deprecated, use install_suexec instead
function install_gosu() {
    local gosu_version
    gosu_version="1.10"
    mkdir -p "${_EMERGE_ROOT}/usr/local/bin"
    curl -o "${_EMERGE_ROOT}/usr/local/bin/gosu" -SL "https://github.com/tianon/gosu/releases/download/${gosu_version}/gosu-amd64"
    chmod +x "${_EMERGE_ROOT}/usr/local/bin/gosu"
    log_as_installed "manual install" "gosu-${gosu_version}" "https://github.com/tianon/gosu/"
}

function install_suexec() {
    local suexec_version
    suexec_version="0.2"
    git clone https://github.com/ncopa/su-exec.git
    cd su-exec/
    git checkout tags/v${suexec_version}
    make && strip su-exec
    mkdir -p "${_EMERGE_ROOT}/usr/local/bin"
    cp su-exec "${_EMERGE_ROOT}/usr/local/bin/"
    log_as_installed "manual install" "su-exec-${suexec_version}" "https://github.com/ncopa/su-exec/"
}

# Arguments:
# 1: url
function download_from_oracle() {
    wget --no-cookies --no-check-certificate \
         --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
         -P /distfiles \
         "$1"
}

source /etc/profile

if [[ -z "${_emerge_bin}" ]]; then
    if [[ "${CHOST}" == x86_64-pc-linux-* ]] || [[ "${CHOST}" == x86_64-gentoo-linux-* ]]; then
        _emerge_bin="emerge"
    else
        _emerge_bin="emerge-${CHOST}"
    fi
fi

mkdir -p "${_EMERGE_ROOT}"

# read config, mounted via build.sh
[[ -f "${_CONFIG}/build.sh" ]] && source "${_CONFIG}/build.sh" || :

# use BOB_BUILDER_{CHOST,CFLAGS,CXXFLAGS} as they may differ when using crossdev
export USE_BUILDER_FLAGS="true"
source /etc/profile

# call configure bob hook if declared in build.sh
declare -F configure_bob &>/dev/null && configure_bob

# switch back to BOB_{CHOST,CFLAGS,CXXFLAGS}
unset USE_BUILDER_FLAGS
source /etc/profile

mkdir -p "${_ROOTFS_BACKUP}"

# set ROOT env for emerge calls
export ROOT="${_EMERGE_ROOT}"

# call pre install hook if declared in build.sh
declare -F configure_rootfs_build &>/dev/null && configure_rootfs_build

# when using a crossdev alias unset CHOST and PKGDIR to not override make.conf
[[ "${_emerge_bin}" != "emerge" ]] && unset CHOST PKGDIR

if [ -n "${_packages}" ]; then

    generate_package_installed ${_packages}
    init_docs "${_image/\images\//}"
    generate_doc_package_installed ${_packages}

    if [ -z "${BOB_SKIP_BASELAYOUT}" ]; then
        "${_emerge_bin}" ${_emerge_opt} --binpkg-respect-use=y -v sys-apps/baselayout
    fi
    # install packages defined in image's build.sh
    "${_emerge_bin}" ${_emerge_opt} --binpkg-respect-use=y -v ${_packages}

    [[ -f "${_PACKAGE_INSTALLED}" ]] && cat "${_PACKAGE_INSTALLED}" | sed -e /^virtual/d >> /etc/portage/profile/package.provided

    # backup headers and static files, depending images can pull them in again
    if [[ -d "${_EMERGE_ROOT}/usr/include" ]]; then
        find "${_EMERGE_ROOT}/usr/include" -type f -name '*.h' | \
            tar -cpf "${_ROOTFS_BACKUP}/${_image_ns}_${_image_id}-headers.tar" --files-from -
    fi
    if [[ -d "${_EMERGE_ROOT}/usr/lib64" ]]; then
        find "${_EMERGE_ROOT}/usr/lib64" -type f -name '*.a' | \
            tar -cpf "${_ROOTFS_BACKUP}/${_image_ns}_${_image_id}-static_libs.tar" --files-from -
    fi

    # extract any possible required headers and static libs from previous builds
    for resource in "headers" "static_libs" "iconv"; do
        extract_build_dependencies "${resource}"
    done

    # handle bug in portage when using custom root, user/groups created during install are not created at the custom root but on the host
    cp -f /etc/{passwd,group} "${_EMERGE_ROOT}/etc"
    # merge with ld.so.conf from builder
    cat /etc/ld.so.conf >> "${_EMERGE_ROOT}/etc/ld.so.conf"
    sort -u "${_EMERGE_ROOT}/etc/ld.so.conf" -o "${_EMERGE_ROOT}/etc/ld.so.conf"

fi

# call post install hook if declared in build.sh
declare -F finish_rootfs_build &>/dev/null && finish_rootfs_build

generate_documentation_footer

unset ROOT

# /run symlink
if [[ -z "${BOB_SKIP_BASELAYOUT}" ]]; then
    mkdir -p "${_EMERGE_ROOT}"/{run,var} && ln -s /run "${_EMERGE_ROOT}/var/run"
fi

# clean up
for lib_dir in "${_EMERGE_ROOT}"/{lib64,usr/lib64}; do
    [[ -d "${lib_dir}" ]] && find "${lib_dir}" -type f \( -name '*.[co]' -o -name '*.prl' \) -delete
done

rm -rf \
    "${_EMERGE_ROOT}"/etc/ld.so.cache \
    "${_EMERGE_ROOT}"/usr/bin/*-config \
    "${_EMERGE_ROOT}"/usr/lib64/cmake/ \
    "${_EMERGE_ROOT}"/usr/lib64/pkgconfig/ \
    "${_EMERGE_ROOT}"/usr/lib64/qt*/mkspecs/ \
    "${_EMERGE_ROOT}"/usr/share/aclocal/ \
    "${_EMERGE_ROOT}"/usr/share/gettext/ \
    "${_EMERGE_ROOT}"/usr/share/gir-[0-9]*/ \
    "${_EMERGE_ROOT}"/usr/share/gtk-doc/* \
    "${_EMERGE_ROOT}"/usr/share/qt*/mkspecs/ \
    "${_EMERGE_ROOT}"/usr/share/vala/vapi/ \
    "${_EMERGE_ROOT}"/var/cache/edb \
    "${_EMERGE_ROOT}"/var/db/pkg/* \
    "${_EMERGE_ROOT}"/var/lib/portage

if [[ -z "${_keep_headers}" ]]; then
    rm -rf "${_EMERGE_ROOT}"/usr/include/*
fi

for lib_dir in "${_EMERGE_ROOT}"/{lib64,usr/lib64}; do
    if [[ -z "${_keep_static_libs}" ]] && [[ -d "${lib_dir}" ]] && [[ "$(ls -A "${lib_dir}")" ]]; then
        find "${lib_dir}"/* -type f -name "*.a" -delete
    fi
done

if [[ -n "${_install_docker_gen}" ]]; then
    install_docker_gen
fi

if [[ "$(ls -A "${_EMERGE_ROOT}")" ]]; then
    # make rootfs tar ball and copy to host
    tar -cpf "${_CONFIG}/rootfs.tar" -C "${_EMERGE_ROOT}" .
    chown ${BOB_HOST_UID}:${BOB_HOST_GID} "${_CONFIG}/rootfs.tar"
    rm -rf "${_EMERGE_ROOT}"
fi

generate_documentation