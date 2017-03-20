#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="sys-libs/readline net-misc/curl app-admin/eselect app-portage/portage-utils app-shells/bash"

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    update_use 'sys-libs/ncurses' '+minimal'
    unprovide_package sys-libs/readline
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    :
}
