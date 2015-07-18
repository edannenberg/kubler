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
    update_keywords 'app-portage/layman' '+~amd64'
    emerge sys-devel/crossdev dev-vcs/git app-portage/layman
    # setup layman
    layman -L
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    :
}
