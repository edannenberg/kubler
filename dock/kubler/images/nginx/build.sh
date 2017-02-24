#
# build config
#
_packages="www-servers/nginx::mva"

configure_bob()
{
    # add mva overlay which has nginx with pagespeed and other goodies
    layman -a mva
}

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    echo 'NGINX_MODULES_HTTP="access auth_basic autoindex charset fastcgi \
             gzip gzip_static limit_req map proxy rewrite scgi ssi stub_status v2"' >> /etc/portage/make.conf
    echo 'NGINX_MODULES_MAIL=""' >> /etc/portage/make.conf
    update_keywords 'www-servers/nginx' '+~amd64'
    update_use 'www-servers/nginx' '+http2'
    update_use 'dev-libs/libpcre' '-readline'
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    mkdir -p $_EMERGE_ROOT/etc/nginx/conf.d
    # required if pagespeed module is included
    #copy_gcc_libs
    # remove overlay
    unset ROOT
    layman -d mva
}
