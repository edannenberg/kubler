#
# build config
#
PACKAGES="dev-lang/php:5.5 dev-php/xdebug dev-php/pecl-memcache dev-php/pecl-redis dev-php/pecl-apcu"
PHP_TIMEZONE="${BOB_TIMEZONE:-UTC}"
#ICONV_FROM=gentoobb/glibc

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

    # skip bash, perl, autogen. pulled in as dep since php 5.5.22
    emerge -p app-shells/bash | grep app-shells/bash | grep -Eow "\[.*\] (.*) to" | awk '{print $(NF-1)}' >> /etc/portage/profile/package.provided
    emerge -p dev-lang/perl | grep dev-lang/perl | grep -Eow "\[.*\] (.*) to" | awk '{print $(NF-1)}' >> /etc/portage/profile/package.provided
    emerge -p sys-devel/autogen | grep sys-devel/autogen | grep -Eow "\[.*\] (.*) to" | awk '{print $(NF-1)}' >> /etc/portage/profile/package.provided
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
    # prepare adminer / phpinfo micro sites
    mkdir -p $EMERGE_ROOT/var/www/{adminer,phpinfo}
    wget -O $EMERGE_ROOT/var/www/adminer/adminer.php https://downloads.sourceforge.net/adminer/adminer-4.1.0-en.php
    wget -O $EMERGE_ROOT/var/www/adminer/adminer.css https://raw.github.com/vrana/adminer/master/designs/bueltge/adminer.css
    echo "<?php phpinfo(); ?>" > $EMERGE_ROOT/var/www/phpinfo/phpinfo.php
}
