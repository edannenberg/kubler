#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_php_slot="7.1"
_php_target="php${_php_slot/\./-}"
_zend_api="20160303"
_packages="dev-lang/php dev-php/xdebug dev-php/pecl-apcu_bc dev-libs/libmemcached media-gfx/imagemagick"
#_packages="dev-lang/php dev-php/pecl-memcached dev-php/pecl-redis pecl-imagick"
_php_timezone="${BOB_TIMEZONE:-UTC}"
_adminer_version="4.3.1"
#_iconv_from=kubler/glibc

configure_bob()
{
    echo "PHP_TARGETS=\"${_php_target}\"" >> /etc/portage/make.conf
    echo 'PHP_INI_VERSION="production"' >> /etc/portage/make.conf
    echo "-php_targets_${_php_target}" >> /etc/portage/profile/use.mask

    update_keywords 'dev-lang/php' '+~amd64'
    update_use 'sys-libs/ncurses' '+minimal'

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
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    update_keywords 'dev-php/xdebug' '+~amd64'
    update_keywords 'dev-php/xdebug-client' '+~amd64'
    #update_keywords 'dev-php/pecl-redis' '+~amd64'

    update_use 'dev-php/pecl-apcu' '+mmap'

    # skip bash, perl, autogen. pulled in as dep since php 5.5.22
    provide_package app-shells/bash dev-lang/perl sys-devel/autogen
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
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
    cp modules/* "${_EMERGE_ROOT}/usr/${_LIB}/php${_php_slot}/lib/extensions/no-debug-zts-${_zend_api}/"
    echo "extension=/usr/${_LIB}/php${_php_slot}/lib/extensions/no-debug-zts-${_zend_api}/memcached.so" \
        > "${_EMERGE_ROOT}"/etc/php/cli-php"${_php_slot}"/ext/memcached.ini
    ln -sr "${_EMERGE_ROOT}"/etc/php/cli-php"${_php_slot}"/ext/memcached.ini \
        "${_EMERGE_ROOT}"/etc/php/cli-php"${_php_slot}"/ext-active/memcached.ini
    echo "extension=/usr/${_LIB}/php${_php_slot}/lib/extensions/no-debug-zts-${_zend_api}/memcached.so" \
        > "${_EMERGE_ROOT}"/etc/php/fpm-php"${_php_slot}"/ext/memcached.ini
    ln -sr ${_EMERGE_ROOT}/etc/php/fpm-php${_php_slot}/ext/memcached.ini \
        "${_EMERGE_ROOT}"/etc/php/fpm-php"${_php_slot}"/ext-active/memcached.ini

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
    cp modules/* "${_EMERGE_ROOT}/usr/${_LIB}/php${_php_slot}/lib/extensions/no-debug-zts-${_zend_api}/"
    echo "extension=/usr/${_LIB}/php${_php_slot}/lib/extensions/no-debug-zts-${_zend_api}/redis.so" \
        > /emerge-root/etc/php/fpm-php${_php_slot}/ext-active/redis.ini

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
    cp modules/* "${_EMERGE_ROOT}/usr/${_LIB}/php${_php_slot}/lib/extensions/no-debug-zts-${_zend_api}/"
    echo "extension=/usr/${_LIB}/php${_php_slot}/lib/extensions/no-debug-zts-${_zend_api}/imagick.so" \
        > "${_EMERGE_ROOT}"/etc/php/cli-php"${_php_slot}"/ext/imagick.ini
    ln -sr "${_EMERGE_ROOT}"/etc/php/cli-php${_php_slot}/ext/imagick.ini \
        "${_EMERGE_ROOT}"/etc/php/cli-php"${_php_slot}"/ext-active/imagick.ini
    echo "extension=/usr/${_LIB}/php${_php_slot}/lib/extensions/no-debug-zts-${_zend_api}/imagick.so" \
        > "${_EMERGE_ROOT}"/etc/php/fpm-php"${_php_slot}"/ext/imagick.ini
    ln -sr "${_EMERGE_ROOT}"/etc/php/fpm-php"${_php_slot}"/ext/imagick.ini \
        "${_EMERGE_ROOT}"/etc/php/fpm-php"${_php_slot}"/ext-active/imagick.ini

    # set php iconv default to UTF-8, if you need full iconv functionality set ICONV_FROM=kubler/glibc above
    local fpm_php_ini
    fpm_php_ini="${_EMERGE_ROOT}"/etc/php/fpm-php"${_php_slot}"/php.ini
    sed -i 's/^;iconv.input_encoding = ISO-8859-1/iconv.input_encoding = UTF-8/g' "${fpm_php_ini}"
    sed -i 's/^;iconv.internal_encoding = ISO-8859-1/iconv.internal_encoding = UTF-8/g' "${fpm_php_ini}"
    sed -i 's/^;iconv.output_encoding = ISO-8859-1/iconv.output_encoding = UTF-8/g' "${fpm_php_ini}"
    # set php time zone
    sed -i "s@^;date.timezone =@date.timezone = $_php_timezone@g" "${fpm_php_ini}"
    # use above changes also for php cli config
    cp "${fpm_php_ini}" "${_EMERGE_ROOT}"/etc/php/cli-php"${_php_slot}"/php.ini
    # disable xdebug
    rm "${_EMERGE_ROOT}"/etc/php/{cli,fpm}-php"${_php_slot}"/ext-active/xdebug.ini
    # required by null-mailer
    copy_gcc_libs
    chmod 0640 "${_EMERGE_ROOT}"/etc/nullmailer/remotes
    # apparently a bug with nullmailer? links to non existing gnutls lib
    ln -sr "${_EMERGE_ROOT}"/usr/"${_LIB}"/libgnutls.so.28 "${_EMERGE_ROOT}"/usr/"${_LIB}"/libgnutls.so.26
    # required by imagick
    find /usr/"${_LIB}"/gcc/x86_64-pc-linux-gnu -name libgomp.so.* -exec cp {} "${_EMERGE_ROOT}"/usr/"${_LIB}"/ \;
    # prepare adminer / phpinfo micro sites
    mkdir -p "${_EMERGE_ROOT}"/var/www/{adminer,phpinfo}
    wget -O "${_EMERGE_ROOT}"/var/www/adminer/adminer.php \
        https://www.adminer.org/static/download/"${_adminer_version}"/adminer-"${_adminer_version}"-en.php
    wget -O "${_EMERGE_ROOT}"/var/www/adminer/adminer.css \
        https://raw.github.com/vrana/adminer/master/designs/bueltge/adminer.css
    echo "<?php phpinfo(); ?>" > "${_EMERGE_ROOT}"/var/www/phpinfo/phpinfo.php
}
