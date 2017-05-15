#
# build config
#
_packages="dev-libs/libressl"

configure_bob()
{
    layman -l | grep -q libressl && layman -d libressl
    layman -a libressl
    # libressl
    # https://wiki.gentoo.org/wiki/Project:LibreSSL
    echo 'USE="${USE} libressl"'   >> /etc/portage/make.conf 
    echo "-libressl"               >> /etc/portage/profile/use.stable.mask 
    echo "-curl_ssl_libressl"      >> /etc/portage/profile/use.stable.mask 
    echo "dev-libs/openssl"        >> /etc/portage/package.mask/openssl
    echo "=dev-libs/libressl-2.4*" >> /etc/portage/package.accept_keywords/libressl
    emerge -f libressl 
    emerge -C openssh
    emerge -C openssl 
    emerge -1q libressl
    emerge -1q wget
    
    # select python
    echo "=dev-lang/python-2.7.12" >> /etc/portage/package.accept_keywords/python-libre
    echo "=dev-lang/python-3.4.5" >> /etc/portage/package.accept_keywords/python-libre
    echo "=app-eselect/eselect-python-20160222" >> /etc/portage/package.accept_keywords/python-libre
    echo "=dev-lang/python-exec-2.4.3" >> /etc/portage/package.accept_keywords/python-libre
    emerge -1q =dev-lang/python-2.7.12 =dev-lang/python-3.4.5

    #echo "=net-misc/iputils-20121221-r2" >> /etc/portage/package.accept_keywords/iputils-libre
    #emerge -1q =net-misc/iputils-20121221-r2

    # install curl
    update_use 'dev-vcs/git' '-perl' '+libressl'
    update_use 'net-misc/curl' '+curl_ssl_libressl' '-curl_ssl_openssl'
    emerge -1q net-misc/curl

    emerge -1q dev-vcs/git

    emerge -q @preserved-rebuild
}

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    update_use 'app-misc/ca-certificates' '-cacert' '-insecure_certs'
    update_keywords 'app-misc/ca-certificates' '+~amd64'
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    :
}
