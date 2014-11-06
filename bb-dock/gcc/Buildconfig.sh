#
# build config
#
PACKAGES="sys-kernel/linux-headers sys-devel/make sys-devel/binutils sys-devel/gcc"
KEEP_HEADERS=true
KEEP_STATIC_LIBS=true

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
