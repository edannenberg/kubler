#
# build config
#
PACKAGES="dev-lang/php:5.5 dev-php/xdebug dev-php/pecl-memcache dev-php/pecl-redis dev-php/pecl-apcu pecl-imagick"
PHP_TIMEZONE="${BOB_TIMEZONE:-UTC}"
#ICONV_FROM=gentoobb/glibc

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    echo 'PHP_TARGETS="php5-5"' >> /etc/portage/make.conf
    echo 'PHP_INI_VERSION="production"' >> /etc/portage/make.conf

    update_use 'dev-lang/php' '+bcmath' '+calendar' '+curl' '+curlwrappers' '+fpm' '+gd' '+mhash' \
               '+mysql' '+mysqli' '+pdo' '+soap' '+sockets' '+xmlreader' '+xmlrpc' '+xmlwriter' '+xpm' '+zip'
    update_use 'app-eselect/eselect-php' '+fpm'
    update_use 'dev-php/pecl-apcu' '+mmap'

    # skip bash, perl, autogen. pulled in as dep since php 5.5.22
    provide_package app-shells/bash dev-lang/perl sys-devel/autogen
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    # set php iconv default to UTF-8, if you need full iconv functionality set ICONV_FROM=gentoobb/glibc above
    sed -i 's/^;iconv.input_encoding = ISO-8859-1/iconv.input_encoding = UTF-8/g' $EMERGE_ROOT/etc/php/fpm-php5.5/php.ini
    sed -i 's/^;iconv.internal_encoding = ISO-8859-1/iconv.internal_encoding = UTF-8/g' $EMERGE_ROOT/etc/php/fpm-php5.5/php.ini
    sed -i 's/^;iconv.output_encoding = ISO-8859-1/iconv.output_encoding = UTF-8/g' $EMERGE_ROOT/etc/php/fpm-php5.5/php.ini
    # set php time zone
    sed -i "s@^;date.timezone =@date.timezone = $PHP_TIMEZONE@g" $EMERGE_ROOT/etc/php/fpm-php5.5/php.ini
    # use above changes also for php cli config
    cp $EMERGE_ROOT/etc/php/fpm-php5.5/php.ini $EMERGE_ROOT/etc/php/cli-php5.5/php.ini
    # disable xdebug
    rm $EMERGE_ROOT/etc/php/fpm-php5.5/ext-active/xdebug.ini
    rm $EMERGE_ROOT/etc/php/cli-php5.5/ext-active/xdebug.ini
    # required by null-mailer
    copy_gcc_libs
    chmod 0640 $EMERGE_ROOT/etc/nullmailer/remotes
    # apparently a bug with nullmailer? links to non existing gnutls lib
    ln -r -s $EMERGE_ROOT/usr/lib64/libgnutls.so.28 $EMERGE_ROOT/usr/lib64/libgnutls.so.26
    # required by imagick
    find /usr/lib64/gcc/x86_64-pc-linux-gnu -name libgomp.so.* -exec cp {} $EMERGE_ROOT/usr/lib64/ \;
    # prepare adminer / phpinfo micro sites
    mkdir -p $EMERGE_ROOT/var/www/{adminer,phpinfo}
    wget -O $EMERGE_ROOT/var/www/adminer/adminer.php https://downloads.sourceforge.net/adminer/adminer-4.2.1-en.php
    wget -O $EMERGE_ROOT/var/www/adminer/adminer.css https://raw.github.com/vrana/adminer/master/designs/bueltge/adminer.css
    echo "<?php phpinfo(); ?>" > $EMERGE_ROOT/var/www/phpinfo/phpinfo.php
}
