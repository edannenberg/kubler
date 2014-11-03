#
# build config
#
PACKAGES="dev-lang/php:5.5 dev-php/xdebug dev-php/pecl-memcache dev-php/pecl-redis dev-php/pecl-apcu"

#
# this method runs in the bb builder container just before starting the build of the rootfs
# 
configure_rootfs_build()
{
    echo 'PHP_TARGETS="php5-5"' >> /etc/portage/make.conf
    echo 'PHP_INI_VERSION="production"' >> /etc/portage/make.conf

    echo 'dev-lang/php bcmath calendar curl curlwrappers fpm gd mhash mysql mysqli pdo soap sockets xmlreader xmlrpc xmlwriter xpm xsl zip' > /etc/portage/package.use/php
    echo 'app-admin/eselect-php fpm' >> /etc/portage/package.use/php
    echo 'dev-php/pecl-apcu mmap' > /etc/portage/package.use/apcu
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    # disable xdebug
    rm $EMERGE_ROOT/etc/php/fpm-php5.5/ext-active/xdebug.ini
    # required by null-mailer
    copy_gcc_libs
}
