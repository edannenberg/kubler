#
# build config
#
PACKAGES="sys-apps/s6"

#
# this method runs in the bb builder container just before starting the build of the rootfs
# 
configure_rootfs_build()
{
    echo "sys-apps/s6 ~amd64" > /etc/portage/package.keywords/s6
    echo "dev-lang/execline ~amd64" >> /etc/portage/package.keywords/s6
    echo "dev-libs/skalibs ~amd64" >> /etc/portage/package.keywords/s6
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    # s6 folders
    mkdir -p $EMERGE_ROOT/etc/service /$EMERGE_ROOT/service
    # remove empty ld.so.conf
    echo "include ld.so.conf.d/*.conf" >> /$EMERGE_ROOT/etc/ld.so.conf
    echo "/usr/x86_64-pc-linux-gnu/lib" >> /$EMERGE_ROOT/etc/ld.so.conf
}
