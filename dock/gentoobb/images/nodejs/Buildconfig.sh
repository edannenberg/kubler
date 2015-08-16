#
# build config
#
PACKAGES="net-libs/http-parser dev-libs/libuv dev-libs/openssl"

configure_bob()
{
    # nodejs ebuild pulls in python for node-gyp
    # we only want the runtime deps for node in this image
    NODEJS_VERSION=$(get_package_version 'net-libs/nodejs')
    # nodejs currently requires openssl with ECDH :/
    emerge -C net-misc/openssh
    update_use 'dev-libs/openssl' '-bindist'
    emerge dev-libs/openssl net-libs/nodejs
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
    tar xjvf "/packages/x86_64-pc-linux-gnu/net-libs/nodejs-${NODEJS_VERSION}.tbz2" -C "${EMERGE_ROOT}"
    log_as_installed "manual_install" "net-libs/nodejs-${NODEJS_VERSION}"
}
