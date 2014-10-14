#
# build config
#
PACKAGES="net-misc/curl"
INSTALL_DOCKER_GEN=true
KEEP_HEADERS=true

#
# this method runs in the bb builder container just before starting the build of the rootfs
# 
configure_rootfs_build()
{
    # needed a build time, so we remove them from package.provided for reinstall
    sed -i /^net-misc\\/curl/d /etc/portage/profile/package.provided
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    :
}
