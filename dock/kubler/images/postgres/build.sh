#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="app-admin/su-exec app-shells/bash dev-db/postgresql"

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
    uninstall_package app-shells/bash
    mkdir /backup
    # since eselect-postgresql-2.1 /usr/share/pkgconfig folder is expected
    mkdir -p "${_EMERGE_ROOT}"/usr/share/pkgconfig
}
