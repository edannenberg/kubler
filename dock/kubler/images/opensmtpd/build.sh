#
# build config
#
_packages="mail-mta/opensmtpd"

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
    sed -i 's/listen on localhost/listen on 0.0.0.0/g' $_EMERGE_ROOT/etc/opensmtpd/smtpd.conf
}
