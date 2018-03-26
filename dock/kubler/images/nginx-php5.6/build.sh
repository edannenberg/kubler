#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_php_slot="5.6"
_php_target="php${_php_slot/\./-}"
_packages="dev-lang/php:${_php_slot} dev-php/xdebug dev-php/pecl-memcache dev-php/pecl-redis dev-php/pecl-apcu pecl-imagick"
_php_timezone="${BOB_TIMEZONE:-UTC}"
_adminer_version="4.6.2"
#_iconv_from=kubler/glibc

configure_bob()
{
    echo "PHP_TARGETS=\"${_php_target}\"" >> /etc/portage/make.conf
    echo 'PHP_INI_VERSION="production"' >> /etc/portage/make.conf

    update_use 'sys-libs/ncurses' '+minimal'
    update_use 'dev-lang/php' '+bcmath' '+calendar' '+curl' '+cli' '+fpm' '+mhash' \
               '+mysql' '+mysqli' '+pcntl' '+pdo' '+soap' '+sockets' '+xmlreader' '+xmlrpc' '+xmlwriter' '+xpm' '+xslt' '+zip'
    # flaggie issue with gd use flag, apparently there now is a conflicting license with the same name
    echo 'dev-lang/php gd' >> /etc/portage/package.use/php
    update_use 'app-eselect/eselect-php' '+fpm'
    update_use 'dev-php/pecl-apcu' '+mmap'

    emerge "dev-lang/php:${_php_slot}"
}

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    update_use 'media-gfx/imagemagick' '-openmp'

    # skip bash, perl, autogen. pulled in as dep since php 5.5.22
    provide_package app-shells/bash dev-lang/perl sys-devel/autogen
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    # set php iconv default to UTF-8, if you need full iconv functionality set _iconv_from=kubler/glibc above
    local fpm_php_ini
    fpm_php_ini="${_EMERGE_ROOT}"/etc/php/fpm-php"${_php_slot}"/php.ini
    sed -i 's/^;iconv.input_encoding = ISO-8859-1/iconv.input_encoding = UTF-8/g' "${fpm_php_ini}"
    sed -i 's/^;iconv.internal_encoding = ISO-8859-1/iconv.internal_encoding = UTF-8/g' "${fpm_php_ini}"
    sed -i 's/^;iconv.output_encoding = ISO-8859-1/iconv.output_encoding = UTF-8/g' "${fpm_php_ini}"
    # set php time zone
    sed -i "s@^;date.timezone =@date.timezone = $_php_timezone@g" "${fpm_php_ini}"
    # use above changes also for php cli config
    cp "${fpm_php_ini}" "${_EMERGE_ROOT}"/etc/php/cli-php${_php_slot}/php.ini
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
