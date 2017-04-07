#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="dev-java/icedtea-bin"

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    update_use 'dev-java/icedtea-bin' '-webstart' '+headless-awt'
    # skip python and nss
    provide_package dev-lang/python
    provide_package dev-libs/nss
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    copy_gcc_libs
    # gentoo's run-java-tool.bash wrapper expects which at /usr/bin
    ln -rs "${_EMERGE_ROOT}"/bin/which "${_EMERGE_ROOT}"/usr/bin/which
}
