#
# build config
#
PACKAGES=""

configure_bob() {
    # install flaggie, required for update_use() helper
    emerge app-portage/flaggie
    mkdir -p /etc/portage/package.{accept_keywords,unmask,mask,use}
    touch /etc/portage/package.accept_keywords/flaggie
    # install default packages
    update_use 'dev-vcs/git' '-perl'
    update_use 'app-crypt/pinentry' '+ncurses'
    emerge sys-devel/crossdev dev-vcs/git app-portage/layman
    # setup layman
    layman -L
    echo source /var/lib/layman/make.conf >> /etc/portage/make.conf
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    :
}
