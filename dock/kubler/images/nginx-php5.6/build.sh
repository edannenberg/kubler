#
# build config
#
PHP_SLOT="5.6"
PHP_TARGET="php${PHP_SLOT/\./-}"
_packages="dev-lang/php:${PHP_SLOT} dev-php/xdebug dev-php/pecl-memcache dev-php/pecl-redis dev-php/pecl-apcu pecl-imagick"
PHP_TIMEZONE="${BOB_TIMEZONE:-UTC}"
ADMINER_VERSION="4.2.5"
#ICONV_FROM=kubler/glibc

configure_bob()
{
    echo "PHP_TARGETS=\"${PHP_TARGET}\"" >> /etc/portage/make.conf
    echo 'PHP_INI_VERSION="production"' >> /etc/portage/make.conf

    update_use 'sys-libs/ncurses' '+minimal'
    update_use 'dev-lang/php' '+bcmath' '+calendar' '+curl' '+fpm' '+mhash' \
               '+mysql' '+mysqli' '+pcntl' '+pdo' '+soap' '+sockets' '+xmlreader' '+xmlrpc' '+xmlwriter' '+xpm' '+xslt' '+zip'
    # flaggie issue with gd use flag, apparently there now is a conflicting license with the same name
    echo 'dev-lang/php gd' >> /etc/portage/package.use/php
    update_use 'app-eselect/eselect-php' '+fpm'
    update_use 'dev-php/pecl-apcu' '+mmap'

    emerge "dev-lang/php:${PHP_SLOT}"
}

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    update_use 'media-gfx/imagemagick' '-openmp'

    # skip bash, perl, autogen. pulled in as dep since php 5.5.22
    provide_package app-shells/bash dev-lang/perl sys-devel/autogen
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    # set php iconv default to UTF-8, if you need full iconv functionality set ICONV_FROM=kubler/glibc above
    sed -i 's/^;iconv.input_encoding = ISO-8859-1/iconv.input_encoding = UTF-8/g' $_EMERGE_ROOT/etc/php/fpm-php${PHP_SLOT}/php.ini
    sed -i 's/^;iconv.internal_encoding = ISO-8859-1/iconv.internal_encoding = UTF-8/g' $_EMERGE_ROOT/etc/php/fpm-php${PHP_SLOT}/php.ini
    sed -i 's/^;iconv.output_encoding = ISO-8859-1/iconv.output_encoding = UTF-8/g' $_EMERGE_ROOT/etc/php/fpm-php${PHP_SLOT}/php.ini
    # set php time zone
    sed -i "s@^;date.timezone =@date.timezone = $PHP_TIMEZONE@g" $_EMERGE_ROOT/etc/php/fpm-php${PHP_SLOT}/php.ini
    # use above changes also for php cli config
    cp $_EMERGE_ROOT/etc/php/fpm-php${PHP_SLOT}/php.ini $_EMERGE_ROOT/etc/php/cli-php${PHP_SLOT}/php.ini
    # disable xdebug
    rm $_EMERGE_ROOT/etc/php/fpm-php${PHP_SLOT}/ext-active/xdebug.ini
    rm $_EMERGE_ROOT/etc/php/cli-php${PHP_SLOT}/ext-active/xdebug.ini
    # required by null-mailer
    copy_gcc_libs
    chmod 0640 $_EMERGE_ROOT/etc/nullmailer/remotes
    # apparently a bug with nullmailer? links to non existing gnutls lib
    ln -r -s $_EMERGE_ROOT/usr/lib64/libgnutls.so.28 $_EMERGE_ROOT/usr/lib64/libgnutls.so.26
    # required by imagick
    find /usr/lib64/gcc/x86_64-pc-linux-gnu -name libgomp.so.* -exec cp {} $_EMERGE_ROOT/usr/lib64/ \;
    # prepare adminer / phpinfo micro sites
    mkdir -p $_EMERGE_ROOT/var/www/{adminer,phpinfo}
    wget -O $_EMERGE_ROOT/var/www/adminer/adminer.php https://www.adminer.org/static/download/${ADMINER_VERSION}/adminer-${ADMINER_VERSION}-en.php
    wget -O $_EMERGE_ROOT/var/www/adminer/adminer.css https://raw.github.com/vrana/adminer/master/designs/bueltge/adminer.css
    echo "<?php phpinfo(); ?>" > $_EMERGE_ROOT/var/www/phpinfo/phpinfo.php
}
