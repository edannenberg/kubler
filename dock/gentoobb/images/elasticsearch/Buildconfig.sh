#
# build config
#
PACKAGES="app-shells/bash app-misc/elasticsearch"

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    update_keywords 'app-misc/elasticsearch' '+~amd64'
    # install bash again, needed at build time
    unprovide_package app-shells/bash
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    uninstall_package app-shells/bash
}
