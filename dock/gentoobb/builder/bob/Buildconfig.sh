#
# build config
#
PACKAGES=""
EMERGE_BIN="emerge"

configure_bob() {
    # install flaggie, required for update_use() helper
    emerge app-portage/flaggie
    mkdir -p /etc/portage/package.{accept_keywords,unmask,mask,use}
    touch /etc/portage/package.accept_keywords/flaggie
    # set locale of build container
    echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
    locale-gen
    echo 'LANG="en_US.UTF-8"' > /etc/env.d/02locale
    env-update
    source /etc/profile
    # install default packages
    update_use 'dev-vcs/git' '-perl'
    update_use 'app-crypt/pinentry' '+ncurses'
    update_keywords 'app-portage/layman' '+~amd64'
    emerge sys-devel/crossdev dev-vcs/git app-portage/layman sys-devel/distcc
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
