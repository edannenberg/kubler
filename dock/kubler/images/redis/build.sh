#
# build config
#
_packages="dev-db/redis"

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    update_use 'dev-lang/lua' '-readline'
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    # disable protected mode
    sed -i 's/^protected-mode yes/protected-mode no/g' "${_EMERGE_ROOT}/etc/redis.conf"
}
