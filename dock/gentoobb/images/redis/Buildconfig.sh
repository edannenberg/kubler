#
# build config
#
PACKAGES="dev-db/redis"

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    echo 'dev-lang/lua -readline' >> /etc/portage/package.use/redis
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    :
}
