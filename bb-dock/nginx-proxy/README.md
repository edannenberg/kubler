This image serves as an automated vhost proxy for any number of containers running on the same host.

Run this [Nginx][] proxy image with:

    $ docker run -d -t \
        -p 80:80 \
        -p 443:443 \
        --name www_proxy \
        --hostname www_proxy \
        gentoobb/nginx-proxy

Now start the required nginx-proxy-conf container that handles auto-configuration of the proxy:

    $ docker run -d \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /var/lib/docker/containers:/var/lib/docker/containers \
        --volumes-from www_proxy \
        --name www_proxy_conf \
        --hostname www_proxy_conf \
        gentoobb/nginx-proxy-conf

For security reasons the conf container is separated from the nginx container because [docker-gen][] requires the host's docker socket.
Check the nginx-proxy-conf documentation for more details.

Finally start a regular nginx container, notice the -e flag:

    $ docker run -d \
        -e VIRTUAL_HOST=foo.void \
        --name www \
        --hostname www \
        gentoobb/nginx-php5.5

Provided your dns resolves foo.void to the host the nginx-proxy container is running on you can now access the www container
via http://foo.void in your browser.

You can also use the provided nginx_proxy.sh script, from the top level directory execute:

    $ ./bin/nginx_proxy.sh start

[Nginx]: http://nginx.org/
[docker-gen]: https://github.com/jwilder/docker-gen
