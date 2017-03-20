#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="app-shells/bash dev-db/postgresql"

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    unprovide_package app-shells/bash
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    install_suexec
    uninstall_package app-shells/bash
    mkdir /backup
}
