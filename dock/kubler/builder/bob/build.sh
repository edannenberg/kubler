#
# Kubler phase 1 config, pick installed packages and/or customize the build
#

#
# This hook can be used to configure the build container itself, install packages, run any command, etc
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
    # when using overlay1 docker storage the created hard link will trigger an error during openssh uninstall
    [[ -f /usr/"${_LIB}"/misc/ssh-keysign ]] && rm /usr/"${_LIB}"/misc/ssh-keysign
    emerge -C net-misc/openssh
    update_use 'dev-libs/openssl' -bindist
    emerge dev-libs/openssl
    update_use 'dev-vcs/git' '-perl'
    update_use 'app-crypt/pinentry' '+ncurses'
    update_keywords 'app-portage/layman' '+~amd64'
    update_keywords 'dev-python/ssl-fetch' '+~amd64'
    update_keywords 'app-admin/su-exec' '+~amd64'
    emerge dev-vcs/git app-portage/layman app-misc/jq app-shells/bash-completion
    install_git_postsync_hooks
    configure_layman
    add_overlay kubler https://github.com/edannenberg/kubler-overlay.git
    emerge dev-lang/go
}
