#
# build config
#
_packages="dev-libs/openssl"

configure_bob()
{
    # enable ECDH
    emerge -C net-misc/openssh
    update_use 'dev-libs/openssl' '-bindist'
    unprovide_package 'dev-libs/openssl'
    emerge dev-libs/openssl
}

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    :
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    :
}
