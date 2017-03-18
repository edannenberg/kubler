#
# build config
#
_packages="sys-libs/readline net-misc/curl app-admin/eselect app-portage/portage-utils app-shells/bash"

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    update_use 'sys-libs/ncurses' '+minimal'
    unprovide_package sys-libs/readline
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    :
}
