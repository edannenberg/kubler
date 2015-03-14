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
    sed -i /^app-shells\\/bash/d /etc/portage/profile/package.provided
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    emerge -C app-shells/bash
    # reflect uninstall in docs
    sed -i /^app-shells\\/bash/d "${DOC_PACKAGE_INSTALLED}"
}
