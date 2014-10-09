#!/bin/sh
# Copyright (C) 2014 Erik Dannenberg <erik.dannenberg@bbe-consulting.de>

set -e

EMERGE_ROOT="/emerge-root" 

[ "$1" ] || {
    echo "--> Error: Empty repo id"
    exit 1
}

copy_gcc_libs() {
    LIBGCC="$(find /usr/lib/ -name libgcc_s.so.1)"
    LIBSTDC="$(find /usr/lib/ -name libstdc++.so.6)"

    for lib in $LIBGCC $LIBSTDC; do
        cp $lib $EMERGE_ROOT/lib64/
    done
}

install_docker_gen() {
    wget http://github.com/jwilder/docker-gen/releases/download/0.3.2/docker-gen-linux-amd64-0.3.2.tar.gz
    mkdir -p $EMERGE_ROOT/bin
    tar -C $EMERGE_ROOT/bin -xvzf docker-gen-linux-amd64-0.3.2.tar.gz
    mkdir -p $EMERGE_ROOT/config/template
}

# read config, mounted via build.sh
source /config/Buildconfig.sh

if [ -n "$PACKAGES" ]; then
    mkdir -p /config/tmp

    if [ -f /config/tmp/package.provided ]; then
        cp /config/tmp/package.provided /etc/portage/profile/
    fi

    if [ -f /config/tmp/passwd ]; then
        cp /config/tmp/{passwd,group} /etc
    fi

    # call pre install hook
    declare -F configure_rootfs_build &>/dev/null && configure_rootfs_build

    # generate installed package list
    emerge -p $PACKAGES | grep -Eow "\[.*\] (.*) to" | awk '{print $(NF-1)}' > /config/tmp/package.installed

    # install packages (see Buildconfig.sh in dock/*/)
    emerge -v baselayout $PACKAGES

    # handle bug in portage when using custom root, user/groups created during install are not created at the custom root but on the host
    cp -f /etc/{passwd,group} $EMERGE_ROOT/etc
    # also copy to repo dir for further builds 
    cp -f /etc/{passwd,group} /config/tmp

    # call post install hook
    declare -F finish_rootfs_build &>/dev/null && finish_rootfs_build

    # /run symlink
    ln -s /run $EMERGE_ROOT/var/run

    # clean up
    rm -rf $EMERGE_ROOT/usr/share/gtk-doc/* $EMERGE_ROOT/var/db/pkg/* $EMERGE_ROOT/etc/ld.so.cache
    if [ -z "$KEEP_HEADERS" ]; then
        rm -rf $EMERGE_ROOT/usr/include/*
    fi
    if [ "$(ls -A $EMERGE_ROOT/lib64)" ]; then
        find $EMERGE_ROOT/lib64/* -name "*.a" -exec rm -rf {} \;
    fi
fi

if [ -n "$INSTALL_DOCKER_GEN" ]; then
    install_docker_gen
fi

if [ -n "$PACKAGES" ] || [ -n "$INSTALL_DOCKER_GEN" ]; then
    # make rootfs tar ball
    tar -cpf /config/rootfs.tar -C $EMERGE_ROOT .
    chmod 777 /config/rootfs.tar
    if [ -f /config/tmp/package.installed ]; then
        chmod 777 /config/tmp/package.installed
    fi
fi
