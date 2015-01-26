#
# build config
#
PACKAGES=""

configure_bob() {
    # install default packages
    emerge sys-devel/crossdev
    # setup layman
    #layman -L
    #echo source /var/lib/layman/make.conf >> /etc/portage/make.conf
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    :
}
