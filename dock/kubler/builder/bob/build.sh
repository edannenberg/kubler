#
# build config, sourced by build-root.sh inside build container
#
_packages=""

#
# this hook can be used to configure the build container itself, install packages, etc
#
configure_bob() {
    fix_portage_profile_symlink
    # install basics used by helper functions
    emerge app-portage/flaggie app-portage/eix app-portage/gentoolkit
    configure_eix
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
    update_keywords 'dev-python/ssl-fetch' '+~amd64'
    emerge dev-vcs/git app-portage/layman sys-devel/distcc app-misc/jq
    install_git_postsync_hooks
    configure_layman
    # install aci/oci requirements
    emerge dev-lang/go app-crypt/gnupg
    install_oci_deps
}

#
# this hook is called in the build container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    :
}
