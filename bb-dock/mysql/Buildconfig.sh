#
# build config
#
PACKAGES="mysql"

#
# this method runs in the bb builder container just before building the rootfs
# 
configure_rootfs_build()
{
    :
}

#
# this method runs in the bb builder container just before packing the rootfs
# 
finish_rootfs_build()
{
    copy_gcc_libs
}
