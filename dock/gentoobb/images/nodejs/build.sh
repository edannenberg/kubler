#
# build config
#
PACKAGES="net-libs/http-parser dev-libs/libuv dev-libs/icu net-libs/nodejs"
EMERGE_OPT="--nodeps"

configure_bob()
{
    # nodejs expects those on the host for compilation
    emerge net-libs/http-parser dev-libs/libuv dev-libs/icu
}

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    update_use net-libs/nodejs +icu
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    copy_gcc_libs
}
