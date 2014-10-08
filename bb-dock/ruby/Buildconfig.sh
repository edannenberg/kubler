#
# build config
#
PACKAGES="app-shells/bash dev-lang/ruby"

#
# this method runs in the bb builder container just before starting the build of the rootfs
# 
configure_rootfs_build()
{
    sed -i /^app-shells\\/bash/d /etc/portage/profile/package.provided
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    :
}
