#!/bin/sh

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
