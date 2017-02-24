#
# build config
#
_packages="net-libs/http-parser dev-libs/libuv dev-libs/icu net-libs/nodejs"

configure_bob()
{
    update_use net-libs/nodejs +icu
    # build binary packages first to avoid pulling in python in the next phase
    emerge net-libs/http-parser dev-libs/libuv dev-libs/icu net-libs/nodejs
}

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    # install binary packages with no deps when building the root fs
    _emerge_opt="--nodeps"
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    copy_gcc_libs
}
