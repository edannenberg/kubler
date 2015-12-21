#
# build config
#
PACKAGES="dev-java/icedtea-bin"

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    update_use 'dev-java/icedtea-bin' '-awt'
    # skip python and nss
    provide_package dev-lang/python
    provide_package dev-libs/nss
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    copy_gcc_libs
}
