#
# build config
#
PACKAGES="net-misc/curl app-admin/eselect app-shells/bash"
KEEP_HEADERS=true

#
# this method runs in the bb builder container just before starting the build of the rootfs
# 
configure_rootfs_build()
{
    :
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    :
}
