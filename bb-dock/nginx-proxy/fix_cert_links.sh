#!/bin/sh
hosts=$(grep "upstream" /etc/nginx/sites-enabled/default.conf | awk '{ print $(NF-1) }')
cd /etc/nginx/ssl
for host in $hosts; do
    if [ ! -d /etc/nginx/ssl/$host ]; then
        ln -s localhost $host
    fi
done
pkill -HUP /usr/sbin/nginx
sleep 1
