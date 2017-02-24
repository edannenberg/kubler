#
# build config
#
_packages=""

configure_bob() {
    # install default packages
    emerge sys-devel/crossdev
    # setup layman
    #layman -L
    #echo source /var/lib/layman/make.conf >> /etc/portage/make.conf
}
