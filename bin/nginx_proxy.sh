#!/bin/bash

start () {
    # nginx-proxy
    docker run -d -t \
        -p 80:80 \
        -p 443:443 \
        --name www_proxy \
        --hostname www_proxy \
        gentoobb/nginx-proxy

    PROXY_IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' www_proxy`

    # nginx-proxy config
    docker run -d \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /var/lib/docker/containers:/var/lib/docker/containers \
        --volumes-from www_proxy \
        --name www_proxy_conf \
        --hostname www_proxy_conf \
        gentoobb/nginx-proxy-conf

    NGINX_IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' www_proxy_conf`

    echo -e "\nnginx:\t $PROXY_IP port 80 and 443 are host mapped."
}

stop () {
    echo "stopping container:"
    docker stop www_proxy_conf
    docker stop www_proxy
    echo "destroying container:"
    docker rm www_proxy_conf
    docker rm www_proxy
}

case "${1}" in
    start) start ${2} $3;;
    stop) stop;;
*) echo  "
Start or stop a nginx-proxy for vhosting.
 
usage: ${0} start|stop";;
esac
