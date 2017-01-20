#
# build config
#
PHP_SLOT="7.1"
PHP_TARGET="php${PHP_SLOT/\./-}"
ZEND_API="20160303"
PACKAGES="dev-lang/php dev-php/xdebug dev-php/pecl-apcu_bc dev-libs/libmemcached media-gfx/imagemagick"
#PACKAGES="dev-lang/php dev-php/pecl-memcached dev-php/pecl-redis pecl-imagick"
PHP_TIMEZONE="${BOB_TIMEZONE:-UTC}"
ADMINER_VERSION="4.2.5"
#ICONV_FROM=gentoobb/glibc

configure_bob()
{
    echo "PHP_TARGETS=\"${PHP_TARGET}\"" >> /etc/portage/make.conf
    echo 'PHP_INI_VERSION="production"' >> /etc/portage/make.conf

    update_keywords 'dev-lang/php' '+~amd64'

    update_use '+gif' '+jpeg' '+jpeg2k' '+png' '+tiff' '+webp'
    update_use 'dev-lang/php' '+bcmath' '+calendar' '+curl' '+fpm' '+mhash' \
               '+mysql' '+mysqli' '+pcntl' '+pdo' '+soap' '+sockets' '+webp' '+xmlreader' '+xmlrpc' '+xmlwriter' '+xpm' '+xslt' '+zip'
    # flaggie issue with gd use flag, apparently there now is a conflicting license with the same name
    echo 'dev-lang/php gd' >> /etc/portage/package.use/php
    update_use 'app-eselect/eselect-php' '+fpm'
    update_use 'media-gfx/imagemagick' '-openmp'
    emerge php git libmemcached imagemagick
}

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    update_keywords 'dev-php/xdebug' '+~amd64'
    update_keywords 'dev-php/xdebug-client' '+~amd64'
    update_keywords 'dev-php/pecl-apcu' '+~amd64'
    update_keywords 'dev-php/pecl-apcu_bc' '+~amd64'
    update_keywords 'dev-php/pecl-redis' '+~amd64'

    update_use 'dev-php/pecl-apcu' '+mmap'

    # skip bash, perl, autogen. pulled in as dep since php 5.5.22
    provide_package app-shells/bash dev-lang/perl sys-devel/autogen
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    # php memcached support - currently not in portage tree
    git clone https://github.com/php-memcached-dev/php-memcached.git
    cd php-memcached/
    git checkout php7
    phpize
    # our libtool is too new, regen some stuff with current version
    aclocal; libtoolize --force; autoheader; autoconf
    ./configure --disable-memcached-sasl
    make
    cp modules/* /emerge-root/usr/lib64/php${PHP_SLOT}/lib/extensions/no-debug-zts-${ZEND_API}/
    echo "extension=/usr/lib64/php${PHP_SLOT}/lib/extensions/no-debug-zts-${ZEND_API}/memcached.so" > ${EMERGE_ROOT}/etc/php/cli-php${PHP_SLOT}/ext/memcached.ini
    ln -sr ${EMERGE_ROOT}/etc/php/cli-php${PHP_SLOT}/ext/memcached.ini ${EMERGE_ROOT}/etc/php/cli-php${PHP_SLOT}/ext-active/memcached.ini
    echo "extension=/usr/lib64/php${PHP_SLOT}/lib/extensions/no-debug-zts-${ZEND_API}/memcached.so" > ${EMERGE_ROOT}/etc/php/fpm-php${PHP_SLOT}/ext/memcached.ini
    ln -sr ${EMERGE_ROOT}/etc/php/fpm-php${PHP_SLOT}/ext/memcached.ini ${EMERGE_ROOT}/etc/php/fpm-php${PHP_SLOT}/ext-active/memcached.ini

    # php redis support
    cd ..
    git clone https://github.com/phpredis/phpredis.git
    cd phpredis/
    git checkout php7
    phpize
    # our libtool is too new, regen some stuff with current version
    aclocal; libtoolize --force; autoheader; autoconf
    ./configure
    make
    cp modules/* /emerge-root/usr/lib64/php${PHP_SLOT}/lib/extensions/no-debug-zts-${ZEND_API}/
    echo "extension=/usr/lib64/php${PHP_SLOT}/lib/extensions/no-debug-zts-${ZEND_API}/redis.so" > /emerge-root/etc/php/fpm-php${PHP_SLOT}/ext-active/redis.ini

    # php imagick support - ebuild currently buggy (doesn't find php7 target even though it is active)
    cd ..
    wget https://pecl.php.net/get/imagick-3.4.3RC1.tgz
    tar xvzf imagick-3.4.3RC1.tgz
    cd imagick-3.4.3RC1/
    phpize
    # our libtool is too new, regen some stuff with current version
    aclocal; libtoolize --force; autoheader; autoconf
    ./configure
    make
    cp modules/* /emerge-root/usr/lib64/php${PHP_SLOT}/lib/extensions/no-debug-zts-${ZEND_API}/
    echo "extension=/usr/lib64/php${PHP_SLOT}/lib/extensions/no-debug-zts-${ZEND_API}/imagick.so" > ${EMERGE_ROOT}/etc/php/cli-php${PHP_SLOT}/ext/imagick.ini
    ln -sr ${EMERGE_ROOT}/etc/php/cli-php${PHP_SLOT}/ext/imagick.ini ${EMERGE_ROOT}/etc/php/cli-php${PHP_SLOT}/ext-active/imagick.ini
    echo "extension=/usr/lib64/php${PHP_SLOT}/lib/extensions/no-debug-zts-${ZEND_API}/imagick.so" > ${EMERGE_ROOT}/etc/php/fpm-php${PHP_SLOT}/ext/imagick.ini
    ln -sr ${EMERGE_ROOT}/etc/php/fpm-php${PHP_SLOT}/ext/imagick.ini ${EMERGE_ROOT}/etc/php/fpm-php${PHP_SLOT}/ext-active/imagick.ini

    # set php iconv default to UTF-8, if you need full iconv functionality set ICONV_FROM=gentoobb/glibc above
    sed -i 's/^;iconv.input_encoding = ISO-8859-1/iconv.input_encoding = UTF-8/g' $EMERGE_ROOT/etc/php/fpm-php${PHP_SLOT}/php.ini
    sed -i 's/^;iconv.internal_encoding = ISO-8859-1/iconv.internal_encoding = UTF-8/g' $EMERGE_ROOT/etc/php/fpm-php${PHP_SLOT}/php.ini
    sed -i 's/^;iconv.output_encoding = ISO-8859-1/iconv.output_encoding = UTF-8/g' $EMERGE_ROOT/etc/php/fpm-php${PHP_SLOT}/php.ini
    # set php time zone
    sed -i "s@^;date.timezone =@date.timezone = $PHP_TIMEZONE@g" $EMERGE_ROOT/etc/php/fpm-php${PHP_SLOT}/php.ini
    # use above changes also for php cli config
    cp $EMERGE_ROOT/etc/php/fpm-php${PHP_SLOT}/php.ini $EMERGE_ROOT/etc/php/cli-php${PHP_SLOT}/php.ini
    # disable xdebug
    rm $EMERGE_ROOT/etc/php/fpm-php${PHP_SLOT}/ext-active/xdebug.ini
    rm $EMERGE_ROOT/etc/php/cli-php${PHP_SLOT}/ext-active/xdebug.ini
    # required by null-mailer
    copy_gcc_libs
    chmod 0640 $EMERGE_ROOT/etc/nullmailer/remotes
    # apparently a bug with nullmailer? links to non existing gnutls lib
    ln -r -s $EMERGE_ROOT/usr/lib64/libgnutls.so.28 $EMERGE_ROOT/usr/lib64/libgnutls.so.26
    # required by imagick
    find /usr/lib64/gcc/x86_64-pc-linux-gnu -name libgomp.so.* -exec cp {} $EMERGE_ROOT/usr/lib64/ \;
    # prepare adminer / phpinfo micro sites
    mkdir -p $EMERGE_ROOT/var/www/{adminer,phpinfo}
    wget -O $EMERGE_ROOT/var/www/adminer/adminer.php https://www.adminer.org/static/download/${ADMINER_VERSION}/adminer-${ADMINER_VERSION}-en.php
    wget -O $EMERGE_ROOT/var/www/adminer/adminer.css https://raw.github.com/vrana/adminer/master/designs/bueltge/adminer.css
    echo "<?php phpinfo(); ?>" > $EMERGE_ROOT/var/www/phpinfo/phpinfo.php
}
