This image serves as an automated vhost proxy for any number of containers running on the same host.

Run this [Nginx][] proxy image with:

    $ docker run -d -t \
        -p 80:80 \
        -p 443:443 \
        --name www_proxy \
        --hostname www_proxy \
        kubler/nginx-proxy

For persistent ssl certificates use:

    $ docker run -d -t \
        -p 80:80 \
        -p 443:443 \
        -v /docker_proxy_certs:/etc/nginx/ssl
        --name www_proxy \
        --hostname www_proxy \
        kubler/nginx-proxy

The default proxy certs are generated in localhost/, certs for each vhost are expected in $VIRTUAL_HOST/. Symlinks to the default cert are created
on config change. Replace with your own certs per host as needed.

Now start the required nginx-proxy-conf container that handles auto-configuration of the proxy:

    $ docker run -d \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /var/lib/docker/containers:/var/lib/docker/containers \
        --volumes-from www_proxy \
        --name www_proxy_conf \
        --hostname www_proxy_conf \
        kubler/nginx-proxy-conf

For security reasons the conf container is separated from the nginx container because [docker-gen][] requires the host's docker socket.
Check the nginx-proxy-conf documentation for more details.

Finally to use the proxy container simply pass VIRTUAL_HOST and VIRTUAL_PORT ENVs to containers you wish to proxy:

    $ docker run -d \
        -e VIRTUAL_HOST=foo.void \
        --name www \
        --hostname www \
        kubler/nginx-php5.5

Provided your dns resolves foo.void to the host the www_proxy container is running on, you can now access the www container
via http://foo.void in your browser. VIRTUAL_PORT defaults to 80 and can be omitted.

You can also use the provided nginx_proxy.sh script, from the top level directory execute:

    $ ./bin/nginx_proxy.sh start

[Nginx]: http://nginx.org/
[docker-gen]: https://github.com/jwilder/docker-gen
