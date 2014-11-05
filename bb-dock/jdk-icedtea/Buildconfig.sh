#
# build config
#
PACKAGES="dev-java/icedtea-bin"

#
# this method runs in the bb builder container just before starting the build of the rootfs
# 
configure_rootfs_build()
{
    # skip python
    emerge -p dev-lang/python | grep dev-lang/python | grep -Eow "\[.*\] (.*) to" | awk '{print $(NF-1)}' >> /etc/portage/profile/package.provided
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    :
}
