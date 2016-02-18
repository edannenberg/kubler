#!/bin/sh
# Copyright (C) 2014 Erik Dannenberg <erik.dannenberg@bbe-consulting.de>

set -e

EMERGE_ROOT="/emerge-root"
EMERGE_BIN="${BOB_EMERGE_BIN:-emerge}"
EMERGE_OPT="${EMERGE_OPT:-}"
CONFIG="/config"
CONFIG_TMP="${CONFIG}/tmp"
ROOTFS_BACKUP="/backup-rootfs"
PACKAGE_INSTALLED="${ROOTFS_BACKUP}/package.installed"
DOC_PACKAGE_INSTALLED="${ROOTFS_BACKUP}/doc.package.installed"
DOC_PACKAGE_PROVIDED="${ROOTFS_BACKUP}/doc.package.provided"
DOC_FOOTER_PURGED="${ROOTFS_BACKUP}/doc.footer.purged"
DOC_FOOTER_INCLUDES="${ROOTFS_BACKUP}/doc.footer.includes"

[ "$1" ] || {
    echo "--> Error: Empty repo id"
    exit 1
}

REPO="${1}"
IMAGE_NS="${REPO%%/*}"
IMAGE_ID="${REPO##*/}"

copy_gcc_libs() {
    mkdir -p ${EMERGE_ROOT}/lib64
    LIBGCC="$(find /usr/lib/ -name libgcc_s.so.1)"
    LIBSTDC="$(find /usr/lib/ -name libstdc++.so.6)"

    for lib in ${LIBGCC} ${LIBSTDC}; do
        cp $lib ${EMERGE_ROOT}/lib64/
    done
}

extract_build_dependencies() {
    RESOURCE_SUFFIX="${1}"
    RESOURCE_VAR="${RESOURCE_SUFFIX}_FROM"
    if [ -n "${!RESOURCE_VAR}" ]; then
        for PARENT_REPO in ${!RESOURCE_VAR}; do
            if [ -f "${ROOTFS_BACKUP}/${PARENT_REPO/\//_}-${RESOURCE_SUFFIX}.tar" ]; then
                tar xpf "${ROOTFS_BACKUP}/${PARENT_REPO/\//_}-${RESOURCE_SUFFIX}.tar"
            fi
        done
    fi
}

# Find package version of given gentoo package atom
#
# Arguments:
# 1: package_atom
get_package_version()
{
    local PACKAGE="${1}"
    exec 2>/dev/null
    echo $(emerge -p "${PACKAGE}" | grep ${PACKAGE} | sed -e "s|${PACKAGE}-|${PACKAGE}§|" -e 's/[\s]*USE=/§USE=/g' | awk -F§ '{print $2}')
    exec 2>&1
}

generate_documentation_footer() {
    echo "#### Purged" > "${DOC_FOOTER_PURGED}"
    write_checkbox_line "Headers" "${KEEP_HEADERS}" "${DOC_FOOTER_PURGED}" "negate"
    write_checkbox_line "Static Libs" "${KEEP_STATIC_LIBS}" "${DOC_FOOTER_PURGED}" "negate"
    if [[ -n $HEADERS_FROM ]] || [[ -n $STATIC_LIBS_FROM ]] || [[ -n $ICONV_FROM ]]; then
        echo -e "\n#### Included" > "${DOC_FOOTER_INCLUDES}"
        if [[ -n $HEADERS_FROM ]]; then
            write_checkbox_line "Headers from ${HEADERS_FROM}" "checked" "${DOC_FOOTER_INCLUDES}"
        fi
        if [[ -n $STATIC_LIBS_FROM ]]; then
            write_checkbox_line "Static Libs from ${STATIC_LIBS_FROM}" "checked" "${DOC_FOOTER_INCLUDES}"
        fi
        if [[ -n $ICONV_FROM ]]; then
            write_checkbox_line "Glibc Iconv Encodings" "checked" "${DOC_FOOTER_INCLUDES}"
        fi
    fi
}

generate_documentation() {
    DOC_FILE="${CONFIG}/PACKAGES.md"
    TABLE_HEADER="Package | USE Flags\n--------|----------"
    echo "#### Installed" > $DOC_FILE
    if [[ -f ${DOC_PACKAGE_INSTALLED} ]]; then
        echo -e "$TABLE_HEADER" >> $DOC_FILE
        cat ${DOC_PACKAGE_INSTALLED} | sed -e "1d" >> $DOC_FILE
    else
        echo "None." >> $DOC_FILE
    fi
    echo "#### Inherited" >> $DOC_FILE
    echo -e "$TABLE_HEADER" >> $DOC_FILE
    if [[ -f ${DOC_PACKAGE_PROVIDED} ]]; then
        cat ${DOC_PACKAGE_PROVIDED} >> $DOC_FILE
    else
        echo "**FROM scratch** |" >> $DOC_FILE
    fi
    if [[ -f ${DOC_FOOTER_PURGED} ]]; then
        cat ${DOC_FOOTER_PURGED} >> $DOC_FILE
    fi
    if [[ -f ${DOC_FOOTER_INCLUDES} ]]; then
        cat ${DOC_FOOTER_INCLUDES} >> $DOC_FILE
    fi
}

# Appends a github markdown line with a checkbox and label to given file.
#
# Arguments:
# 1: checkbox label
# 2: is checked
# 3: file
# 4: negate checked state, when set the true/false eval of $2 is negated, optional
write_checkbox_line() {
    LABEL="${1}"
    CHECKED="${2}"
    NEGATE_CHECK_STATE="${4}"
    if [[ -z "$CHECKED" ]] || [[ "$CHECKED" = "false" ]]; then
        STATE=0
    else 
        STATE=1
    fi
    if [[ -n $NEGATE_CHECK_STATE ]]; then
        if [[ "$STATE" == 1 ]]; then
            STATE=0
        else 
            STATE=1
        fi
    fi
    if [[ "$STATE" == 1 ]]; then
        CHECKBOX="- [x]"
    else 
        CHECKBOX="- [ ]"
    fi
    echo "${CHECKBOX} ${LABEL}" >> "${3}"
}

# Generates $PACKAGE_INSTALLED from provided portage package atoms,
# should only get called from configure_rootfs_build() hook
#
# Arguments:
# 1: PACKAGES (i.e. "sys-apps/busybox dev-vcs/git")
generate_package_installed() {
    local PACKAGES="${1}"
    # generate installed package list
    "${EMERGE_BIN}" ${EMERGE_OPT} --binpkg-respect-use=y -p ${PACKAGES[@]} | \
    grep -Eow "\[.*\] (.*) to" | \
    awk '{print $(NF-1)}' > ${PACKAGE_INSTALLED}
}

# Append DOC_PACKAGE_INSTALLED from last build to DOC_PACKAGE_PROVIDED, overwrite DOC_PACKAGE_INSTALLED with header for current build
# Should only get called from configure_bob() or configure_rootfs_build() hooks
#
# Arguments:
# 1: IMAGE_NAME (only used in header)
init_docs() {
    local IMAGE_NAME="${1}"
    touch -a ${DOC_PACKAGE_PROVIDED}
    [[ -f ${DOC_PACKAGE_INSTALLED} ]] && \
            echo -e "$(cat ${DOC_PACKAGE_INSTALLED})\n$(cat ${DOC_PACKAGE_PROVIDED})" > ${DOC_PACKAGE_PROVIDED}

    echo "**FROM ${IMAGE_NAME}** |" > ${DOC_PACKAGE_INSTALLED}
}

# Generates $DOC_PACKAGE_INSTALLED from provided portage package atoms,
# should only get called from configure_rootfs_build() hook
#
# Arguments:
# 1: PACKAGES (i.e. "shell/bash dev-vcs/git")
generate_doc_package_installed() {
    local PACKAGES="${1}"
    # generate installed package list with use flags
    "${EMERGE_BIN}" ${EMERGE_OPT} --binpkg-respect-use=y -p ${PACKAGES[@]} | \
        perl -nle 'print "$1 | `$3`" if /\[.*\] (.*) to \/.*\/( USE=")?([a-z0-9\- (){}]*)?/' | \
        sed /^virtual/d | sort -u >> "${DOC_PACKAGE_INSTALLED}"
}

# Adds a package entry in $DOC_PACKAGE_INSTALLED to document non-Portage package installs.
# You should only use this function from the finish_rootfs_build() hook.
#
# Arguments:
# 1: package group (for example "gem" if you installed ruby gems)
# 2: package-version
# 3: optional string that appears in the use flags column
log_as_installed() {
    echo "*${1}*: ${2} | ${3}" >> "${DOC_PACKAGE_INSTALLED}"
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
update_use() {
    flaggie --strict --destructive-cleanup ${@}
}

# Just for better readabilty of Buildconfig.sh
update_keywords() {
    update_use ${@}
}

mask_package() {
    echo "${1}" >> /etc/portage/package.mask/bob
}

unmask_package() {
    echo "${1}" >> /etc/portage/package.unmask/bob
}

# Fake package install by adding it to package.provided
# Usually called from configure_rootfs_build() hook.
#
# Arguments:
# 1: package atom (i.e. app-shells/bash)
# n: more package atoms
provide_package() {
    for P in ${@}; do
        emerge -p "${P}" | grep "${P}" | grep -Eow "\[.*\] (.*) to" | awk '{print $(NF-1)}' >> /etc/portage/profile/package.provided
    done
}

# Mark package atom for reinstall.
# Usually called from configure_rootfs_build() hook.
#
# Arguments:
# 1: package atom (i.e. app-shells/bash)
# n: more package atoms
unprovide_package() {
    for P in ${@}; do
        sed -i /^${P//\//\\\/}/d /etc/portage/profile/package.provided
    done
}

# Remove packages that were only needed at build time, also cleans ${DOC_PACKAGE_INSTALLED}
# Usually called from finish_rootfs_build() hook.
#
# Arguments:
# 1: package atom (i.e. app-shells/bash)
# n: more package atoms
uninstall_package() {
    emerge -C ${@}
    for P in ${@}; do
        # reflect uninstall in docs
        sed -i /^${P//\//\\\/}/d "${DOC_PACKAGE_INSTALLED}"
    done
}

install_docker_gen() {
    local DOCKERGEN_VERSION="0.6.0"
    wget "http://github.com/jwilder/docker-gen/releases/download/${DOCKERGEN_VERSION}/docker-gen-linux-amd64-${DOCKERGEN_VERSION}.tar.gz"
    mkdir -p $EMERGE_ROOT/bin
    tar -C $EMERGE_ROOT/bin -xvzf "docker-gen-linux-amd64-${DOCKERGEN_VERSION}.tar.gz"
    mkdir -p $EMERGE_ROOT/config/template
    log_as_installed "manual install" "docker-gen-${DOCKERGEN_VERSION}" "http://github.com/jwilder/docker-gen/"
}

install_gosu()
{
    local GOSU_VERSION="1.7"
    mkdir -p ${EMERGE_ROOT}/usr/local/bin
    curl -o ${EMERGE_ROOT}/usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64"
    chmod +x ${EMERGE_ROOT}/usr/local/bin/gosu
    log_as_installed "manual install" "gosu-${GOSU_VERSION}" "https://github.com/tianon/gosu/"
}

download_from_oracle() {
    wget --no-cookies --no-check-certificate \
         --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
         -P /distfiles \
         "${1}"
}

source /etc/profile

if [[ "${CHOST}" = "x86_64-pc-linux-gnu" ]]; then
    EMERGE_BIN="emerge"
else
    EMERGE_BIN="emerge-${CHOST}"
fi

mkdir -p $EMERGE_ROOT

# read config, mounted via build.sh
[[ -f ${CONFIG}/Buildconfig.sh ]] && source ${CONFIG}/Buildconfig.sh || :

# use BOB_BUILDER_{CHOST,CFLAGS,CXXFLAGS}
export USE_BUILDER_FLAGS="true"
source /etc/profile

# call configure bob hook if declared in Buildconfig.sh
declare -F configure_bob &>/dev/null && configure_bob

# switch back to BOB_{CHOST,CFLAGS,CXXFLAGS}
unset USE_BUILDER_FLAGS
source /etc/profile

mkdir -p ${ROOTFS_BACKUP} 

# set ROOT env for emerge calls
export ROOT="${EMERGE_ROOT}"

# call pre install hook if declared in Buildconfig.sh
declare -F configure_rootfs_build &>/dev/null && configure_rootfs_build

# when using a crossdev alias unset CHOST and PKGDIR to not override make.conf
[[ "${EMERGE_BIN}" != "emerge" ]] && unset CHOST PKGDIR

if [ -n "$PACKAGES" ]; then

    generate_package_installed "${PACKAGES}"
    init_docs ${REPO/\images\//}
    generate_doc_package_installed "${PACKAGES}"

    "${EMERGE_BIN}" ${EMERGE_OPT} --binpkg-respect-use=y -v sys-apps/baselayout
    # install packages (defined via Buildconfig.sh)
    "${EMERGE_BIN}" ${EMERGE_OPT} --binpkg-respect-use=y -v $PACKAGES

    [[ -f ${PACKAGE_INSTALLED} ]] && cat ${PACKAGE_INSTALLED} | sed -e /^virtual/d >> /etc/portage/profile/package.provided

    # backup headers and static files, depending images can pull them in again
    if [ -d $EMERGE_ROOT/usr/include ]; then 
        find $EMERGE_ROOT/usr/include -type f -name '*.h' | \
            tar -cpf ${ROOTFS_BACKUP}/${IMAGE_NS}_${IMAGE_ID}-HEADERS.tar --files-from -
    fi
    if [ -d $EMERGE_ROOT/usr/lib64 ]; then
        find $EMERGE_ROOT/usr/lib64 -type f -name '*.a' | \
            tar -cpf ${ROOTFS_BACKUP}/${IMAGE_NS}_${IMAGE_ID}-STATIC_LIBS.tar --files-from -
    fi

    # extract any possible required headers and static libs from previous builds
    for resource in "HEADERS" "STATIC_LIBS" "ICONV"; do
        extract_build_dependencies ${resource}
    done

    # handle bug in portage when using custom root, user/groups created during install are not created at the custom root but on the host
    cp -f /etc/{passwd,group} $EMERGE_ROOT/etc
    # merge with ld.so.conf from builder
    cat /etc/ld.so.conf >> $EMERGE_ROOT/etc/ld.so.conf
    sort -u $EMERGE_ROOT/etc/ld.so.conf -o $EMERGE_ROOT/etc/ld.so.conf

fi

# call post install hook if declared in Buildconfig.sh
declare -F finish_rootfs_build &>/dev/null && finish_rootfs_build

generate_documentation_footer

unset ROOT

# /run symlink
mkdir -p $EMERGE_ROOT/var/run && ln -s /run $EMERGE_ROOT/var/run

# clean up
rm -rf $EMERGE_ROOT/usr/share/gtk-doc/* $EMERGE_ROOT/var/db/pkg/* $EMERGE_ROOT/etc/ld.so.cache
if [ -z "$KEEP_HEADERS" ]; then
    rm -rf $EMERGE_ROOT/usr/include/*
fi
if [ -z "$KEEP_STATIC_LIBS" ] && [ -d $EMERGE_ROOT/lib64 ] && [ "$(ls -A $EMERGE_ROOT/lib64)" ]; then
    find $EMERGE_ROOT/lib64/* -type f -name "*.a" -exec rm -f {} \;
fi
if [ -z "$KEEP_STATIC_LIBS" ] && [ -d $EMERGE_ROOT/usr/lib64 ] && [ "$(ls -A $EMERGE_ROOT/usr/lib64)" ]; then
    find $EMERGE_ROOT/usr/lib64/* -type f -name "*.a" -exec rm -f {} \;
fi

if [ -n "$INSTALL_DOCKER_GEN" ]; then
    install_docker_gen
fi

if [ "$(ls -A $EMERGE_ROOT)" ]; then
    # make rootfs tar ball
    tar -cpf ${CONFIG}/rootfs.tar -C ${EMERGE_ROOT} .
    chmod 777 ${CONFIG}/rootfs.tar
    rm -rf "${EMERGE_ROOT}"
fi

generate_documentation
