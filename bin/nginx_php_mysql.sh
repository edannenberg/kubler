#!/bin/bash

VHOST_BASE=test.void
ADMINER_URL=db.${VHOST_BASE}
PHPINFO_URL=phpinfo.${VHOST_BASE}
VHOST_URL=${VHOST_BASE},${ADMINER_URL},${PHPINFO_URL}

USER_UID=$(id -u $(whoami))
USER_GID=$(id -g $(whoami))

start () {
    # mysql
    docker run -d \
        --name www_mysql \
        --hostname www_mysql \
        gentoobb/mysql

    MYSQL_IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' www_mysql`

    # nginx php
    docker run -d \
        -e VIRTUAL_HOST="$VHOST_URL" \
        -e NG_TMPL_ADMINER_URL="$ADMINER_URL" \
        -e NG_TMPL_PHPINFO_URL="$PHPINFO_URL" \
        -e NGINX_UID="$USER_UID" \
        -e NGINX_GID="$USER_GID" \
        --link www_mysql:db \
        --name www_php \
        --hostname www_php \
        gentoobb/nginx-php5.5

    NGINX_IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' www_php`

    echo -e "\nmysql:\t\t $MYSQL_IP:3306 login: root/root"
    echo -e "nginx:\t\t http://$NGINX_IP/"
    echo -e "vhost:\t\t http://$VHOST_BASE/"
    echo -e "adminer:\t http://$ADMINER_URL/adminer.php?server=db"
    echo -e "phpinfo:\t http://$PHPINFO_URL/"
}

stop () {
    echo "stopping container:"
    docker stop www_mysql
    docker stop www_php
    echo "destroying container:"
    docker rm www_mysql
    docker rm www_php
}

case "${1}" in
    start) start ${2} $3;;
    stop) stop;;
*) echo  "
Start or stop a simple nginx php5.5 mysql webstack.
 
usage: ${0} start|stop [local_web_dir] [local_mysql_dir]";;
esac
