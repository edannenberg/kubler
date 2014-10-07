#
# build config
#
PACKAGES="sys-apps/busybox"

#
# this method runs in the bb builder container just before starting the build of the rootfs
# 
configure_rootfs_build()
{
    # -static to enable dns lookups
    echo "sys-apps/busybox -static" > /etc/portage/package.use/busybox
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    :
}
