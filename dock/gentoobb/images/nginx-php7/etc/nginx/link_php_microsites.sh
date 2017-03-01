#!/bin/sh

if [ "$XDEBUG_ENABLED" == 'true' ]; then
    if [ ! -f /etc/php/fpm-php7.1/ext-active/xdebug.ini ] && [ -f /etc/php/fpm-php7.1/ext/xdebug.ini ]; then
        ln -s /etc/php/fpm-php7.1/ext/xdebug.ini /etc/php/fpm-php7.1/ext-active
        ln -s /etc/php/cli-php7.1/ext/xdebug.ini /etc/php/cli-php7.1/ext-active
    fi
fi

if [ ! -z $NG_TMPL_ADMINER_URL ]; then
    if [ ! -f /etc/nginx/sites-enabled/adminer.conf ] && [ -f /etc/nginx/sites-all/adminer.conf ]; then
        ln -s /etc/nginx/sites-all/adminer.conf /etc/nginx/sites-enabled
    fi
fi

if [ ! -z $NG_TMPL_PHPINFO_URL ]; then
    if [ ! -f /etc/nginx/sites-enabled/phpinfo.conf ] && [ -f /etc/nginx/sites-all/phpinfo.conf ]; then
        ln -s /etc/nginx/sites-all/phpinfo.conf /etc/nginx/sites-enabled
    fi
fi
