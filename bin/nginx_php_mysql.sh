#!/bin/bash

VHOST_URL=test.void,www.test.void

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
    --link www_mysql:db \
    --name www_php \
    --hostname www_php \
    gentoobb/nginx-php5.5

    NGINX_IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' www_php`

    echo -e "\nmysql:\t\t $MYSQL_IP:3306 login: root/root"
    echo -e "nginx:\t\t http://$NGINX_IP/adminer.php?server=db"
    if [ -n $VHOST_URL ]; then
        echo -e "domain name(s):  $VHOST_URL"
    fi
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
