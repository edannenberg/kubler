#!/bin/sh
# Copyright (C) 2014 Erik Dannenberg <erik.dannenberg@bbe-consulting.de>

set -e

EMERGE_ROOT="/emerge-root"
CONFIG="/config"
CONFIG_TMP="${CONFIG}/tmp"
PACKAGE_INSTALLED="${CONFIG_TMP}/package.installed"
DOC_PACKAGE_INSTALLED="${CONFIG_TMP}/doc.package.installed"
DOC_FOOTER_PURGED="${CONFIG_TMP}/doc.footer.purged"
DOC_FOOTER_INCLUDES="${CONFIG_TMP}/doc.footer.includes"

[ "$1" ] || {
    echo "--> Error: Empty repo id"
    exit 1
}

REPO="${1}"

copy_gcc_libs() {
    LIBGCC="$(find /usr/lib/ -name libgcc_s.so.1)"
    LIBSTDC="$(find /usr/lib/ -name libstdc++.so.6)"

    for lib in $LIBGCC $LIBSTDC; do
        cp $lib $EMERGE_ROOT/lib64/
    done
}

extract_build_dependencies() {
    RESOURCE_SUFFIX="${1}"
    RESOURCE_VAR="${RESOURCE_SUFFIX}_FROM"
    if [ -n "${!RESOURCE_VAR}" ]; then
        for PARENT_REPO in ${!RESOURCE_VAR}; do
            if [ -f "${CONFIG_TMP}/${PARENT_REPO}-${RESOURCE_SUFFIX}.tar" ]; then
                tar xpf "${CONFIG_TMP}/${PARENT_REPO}-${RESOURCE_SUFFIX}.tar"
            fi
        done
    fi
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

install_docker_gen() {
    wget http://github.com/jwilder/docker-gen/releases/download/0.3.2/docker-gen-linux-amd64-0.3.2.tar.gz
    mkdir -p $EMERGE_ROOT/bin
    tar -C $EMERGE_ROOT/bin -xvzf docker-gen-linux-amd64-0.3.2.tar.gz
    mkdir -p $EMERGE_ROOT/config/template
    log_as_installed "manual install" "docker-gen-0.3.2" "http://github.com/jwilder/docker-gen/"
}

# read config, mounted via build.sh
source ${CONFIG}/Buildconfig.sh || :

# call configure bob hook if declared in Buildconfig.sh
declare -F configure_bob &>/dev/null && configure_bob

if [ -n "$PACKAGES" ]; then
    mkdir -p ${CONFIG_TMP}

    if [ -f ${CONFIG_TMP}/package.provided ]; then
        cp ${CONFIG_TMP}/package.provided /etc/portage/profile/
    fi

    if [ -f ${CONFIG_TMP}/passwd ]; then
        cp ${CONFIG_TMP}/{passwd,group} /etc
    fi

    # set ROOT env for emerge calls
    export ROOT="${EMERGE_ROOT}"

    # call pre install hook if declared in Buildconfig.sh
    declare -F configure_rootfs_build &>/dev/null && configure_rootfs_build

    # generate installed package list
    emerge -p $PACKAGES | grep -Eow "\[.*\] (.*) to" | awk '{print $(NF-1)}' > ${PACKAGE_INSTALLED}

    # generate installed package list with use flags for auto docs
    emerge -p $PACKAGES | perl -nle 'print "$1 | `$3`" if /\[.*\] (.*) to \/.*\/( USE=")?([a-z0-9\- (){}]*)?/' | \
        sed /^virtual/d | sort -u > "${DOC_PACKAGE_INSTALLED}"

    # install packages (defined via Buildconfig.sh)
    emerge -v baselayout $PACKAGES

    # backup headers and static files, depending images can pull them in again
    if [ -d $EMERGE_ROOT/usr/include ]; then 
        find $EMERGE_ROOT/usr/include -type f -name '*.h' | tar -cpf ${CONFIG_TMP}/$REPO-HEADERS.tar --files-from -
    fi
    if [ -d $EMERGE_ROOT/usr/lib64 ]; then
        find $EMERGE_ROOT/usr/lib64 -type f -name '*.a' | tar -cpf ${CONFIG_TMP}/$REPO-STATIC_LIBS.tar --files-from -
    fi

    # extract any possible required headers and static libs from other images, build.sh provides them at ${CONFIG_TMP}
    for resource in "HEADERS" "STATIC_LIBS" "ICONV"; do
        extract_build_dependencies ${resource}
    done

    # handle bug in portage when using custom root, user/groups created during install are not created at the custom root but on the host
    cp -f /etc/{passwd,group} $EMERGE_ROOT/etc
    #pwconv -R $EMERGE_ROOT
    #grpconv -R $EMERGE_ROOT
    # also copy to repo dir for further builds 
    cp -f /etc/{passwd,group} ${CONFIG_TMP}
    # merge with ld.so.conf from parent image and copy for further builds depending on this image
    if [ -f ${CONFIG_TMP}/ld.so.conf.parent ]; then
        cat ${CONFIG_TMP}/ld.so.conf.parent >> $EMERGE_ROOT/etc/ld.so.conf
        sort -u $EMERGE_ROOT/etc/ld.so.conf -o $EMERGE_ROOT/etc/ld.so.conf
    fi
    cp -f $EMERGE_ROOT/etc/ld.so.conf ${CONFIG_TMP}

    generate_documentation_footer

    # call post install hook if declared in Buildconfig.sh
    declare -F finish_rootfs_build &>/dev/null && finish_rootfs_build

    unset ROOT

    # /run symlink
    ln -s /run $EMERGE_ROOT/var/run

    # clean up
    rm -rf $EMERGE_ROOT/usr/share/gtk-doc/* $EMERGE_ROOT/var/db/pkg/* $EMERGE_ROOT/etc/ld.so.cache
    if [ -z "$KEEP_HEADERS" ]; then
        rm -rf $EMERGE_ROOT/usr/include/*
    fi
    if [ -z "$KEEP_STATIC_LIBS" ] && [ "$(ls -A $EMERGE_ROOT/lib64)" ]; then
        find $EMERGE_ROOT/lib64/* -type f -name "*.a" -exec rm -f {} \;
    fi
    if [ -z "$KEEP_STATIC_LIBS" ] && [ "$(ls -A $EMERGE_ROOT/usr/lib64)" ]; then
        find $EMERGE_ROOT/usr/lib64/* -type f -name "*.a" -exec rm -f {} \;
    fi
fi

if [ -n "$INSTALL_DOCKER_GEN" ]; then
    install_docker_gen
fi

if [ -n "$PACKAGES" ] || [ -n "$INSTALL_DOCKER_GEN" ]; then
    # make rootfs tar ball
    tar -cpf ${CONFIG}/rootfs.tar -C ${EMERGE_ROOT} .
    chmod 777 ${CONFIG}/rootfs.tar
    if [ -f "${CONFIG_TMP}/${PACKAGE_INSTALLED}" ]; then
        chmod 777 "${CONFIG_TMP}/${PACKAGE_INSTALLED}"
    fi
fi
