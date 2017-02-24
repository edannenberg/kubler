#
# build config
#
_packages="app-shells/bash dev-db/postgresql"

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    unprovide_package app-shells/bash
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    install_suexec
    uninstall_package app-shells/bash
    mkdir /backup
}
