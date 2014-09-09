#
# build config
#
PACKAGES="app-shells/bash app-misc/elasticsearch"

#
# this method runs in the bb builder container just before starting the build of the rootfs
# 
configure_rootfs_build()
{
    echo "app-misc/elasticsearch ~amd64" >> /etc/portage/package.keywords/elastic
    sed -i /^app-shells\\/bash/d /etc/portage/profile/package.provided
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    :
}
