#
# build config
#
PACKAGES="net-libs/http-parser dev-libs/libuv net-libs/nodejs"
EMERGE_OPT="--nodeps"

configure_bob()
{
    :
}

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
    copy_gcc_libs
}
