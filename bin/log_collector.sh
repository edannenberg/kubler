#!/bin/bash

VHOST_URL=logs.void,www.logs.void

start () {
    # elasticsearch
    docker run -d \
        --name log_elasticsearch \
        --hostname log_elasticsearch \
        gentoobb/elasticsearch

    ES_IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' log_elasticsearch`

    # kibana
    docker run -d \
        -e KIBANA_SECURE=false \
        -e ELASTICSEARCH_URL=http://${ES_IP}:9200 \
        -e VIRTUAL_HOST="$VHOST_URL" \
        --name log_kibana \
        --hostname log_kibana \
        gentoobb/kibana

    # fluentd collector
    docker run -d \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /var/lib/docker/containers:/var/lib/docker/containers \
        --link log_elasticsearch:es1 \
        --name log_collector \
        --hostname log_collector \
        gentoobb/log-collector

    KIBANA_IP=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' log_kibana`

    echo -e "\nelasticsearch:\t http://$ES_IP:9200/"
    echo -e "kibana:\t\t http://$KIBANA_IP/index.html#/dashboard/file/logstash.json"
    if [ -n $VHOST_URL ]; then
        echo -e "domain name(s):  $VHOST_URL"
    fi
}

stop () {
    echo "stopping container:"
    docker stop log_collector
    docker stop log_kibana
    docker stop log_elasticsearch

    echo "destroying container:"
    docker rm log_collector
    docker rm log_kibana
    docker rm log_elasticsearch
}

case "${1}" in
    start) start;;
    stop) stop;;
*) echo "
Start or stop a container log collector.

usage: ${0} start|stop";;
esac
