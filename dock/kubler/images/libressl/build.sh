#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="dev-libs/libressl"

configure_bob()
{
    add_layman_overlay libressl
    # libressl
    # https://wiki.gentoo.org/wiki/Project:LibreSSL
    echo 'USE="${USE} libressl"'   >> /etc/portage/make.conf 
    echo "-libressl"               >> /etc/portage/profile/use.stable.mask 
    echo "-curl_ssl_libressl"      >> /etc/portage/profile/use.stable.mask 
    echo "dev-libs/openssl"        >> /etc/portage/package.mask/openssl
    echo "=dev-libs/libressl-2.4*" >> /etc/portage/package.accept_keywords/libressl
    emerge -f dev-libs/libressl
    emerge -C net-misc/openssh dev-libs/openssl
    emerge -1 dev-libs/libressl net-misc/wget

    # select python
    echo "=dev-lang/python-2.7.12" >> /etc/portage/package.accept_keywords/python-libre
    echo "=dev-lang/python-3.4.5" >> /etc/portage/package.accept_keywords/python-libre
    echo "=app-eselect/eselect-python-20160222" >> /etc/portage/package.accept_keywords/python-libre
    echo "=dev-lang/python-exec-2.4.3" >> /etc/portage/package.accept_keywords/python-libre
    emerge -1 =dev-lang/python-2.7.12 =dev-lang/python-3.4.5

    #echo "=net-misc/iputils-20121221-r2" >> /etc/portage/package.accept_keywords/iputils-libre
    #emerge -1 =net-misc/iputils-20121221-r2

    # install curl
    update_use 'dev-vcs/git' '-perl' '+libressl'
    update_use 'net-misc/curl' '+curl_ssl_libressl' '-curl_ssl_openssl'
    emerge -1 net-misc/curl dev-vcs/git

    emerge @preserved-rebuild
}

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    update_use 'app-misc/ca-certificates' '-cacert' '-insecure_certs'
    update_keywords 'app-misc/ca-certificates' '+~amd64'
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    :
}
