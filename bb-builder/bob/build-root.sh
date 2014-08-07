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

# read config, mounted via build.sh
source /config/Buildconfig.sh

# call pre install hook
declare -F configure_rootfs_build &>/dev/null && configure_rootfs_build

# install base + packages (see Buildconfig.sh in dock/*/)
echo "sys-apps/s6 ~amd64" > /etc/portage/package.keywords/s6
echo "dev-lang/execline ~amd64" >> /etc/portage/package.keywords/s6
echo "dev-libs/skalibs ~amd64" >> /etc/portage/package.keywords/s6

emerge -v baselayout glibc sys-apps/s6 $PACKAGES

# busybox last
export VERY_BRAVE_OR_VERY_DUMB="yes"
emerge -v busybox

# handle bug in portage when using custom root, user/groups created during install are not created at the custom root but on the host
cp -f /etc/{passwd,group} $EMERGE_ROOT/etc

# call post install hook
declare -F finish_rootfs_build &>/dev/null && finish_rootfs_build

# /run symlink
ln -s /run $EMERGE_ROOT/var/run

# s6 folders
mkdir -p $EMERGE_ROOT/etc/service /$EMERGE_ROOT/service

# clean up
rm -rf $EMERGE_ROOT/usr/include/* $EMERGE_ROOT/usr/share/gtk-doc/* $EMERGE_ROOT/var/db/pkg/*
find $EMERGE_ROOT/lib64 -name "*.a" -exec rm -rf {} \;

# make rootfs tar ball
tar -cpf /config/rootfs.tar -C $EMERGE_ROOT .
chmod 777 /config/rootfs.tar
