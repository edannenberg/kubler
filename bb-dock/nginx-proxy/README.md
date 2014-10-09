This image serves as a vhost proxy for containers. It picks up containers having a VIRTUAL_HOST env. See nginx-proxy-conf repo for more details.

Run this [Nginx][] proxy image with:

    $ docker run -d -t \
        -p 80:80 \
        -p 443:443 \
        --name www_proxy \
        --hostname www_proxy \
        gentoobb/nginx-proxy

[Nginx]: http://nginx.org/
