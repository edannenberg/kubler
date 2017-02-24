#
# build config
#
_packages="dev-java/icedtea-bin"

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    update_use 'dev-java/icedtea-bin' '-webstart'
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
    # gentoo's run-java-tool.bash wrapper expects which at /usr/bin
    ln -rs ${_EMERGE_ROOT}/bin/which ${_EMERGE_ROOT}/usr/bin/which
}
