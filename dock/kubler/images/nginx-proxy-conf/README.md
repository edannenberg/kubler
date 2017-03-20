## kubler/nginx-proxy-conf

This image generates the /etc/nginx/sites-enabled/default.conf file for kubler/nginx-proxy by listening to docker
events on the host via [docker-gen][].

See Jason Wilder's excellent blog [article][jwilder-blog] for the full details.

Run this [docker-gen][] image with:

    $ docker run -d \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /var/lib/docker/containers:/var/lib/docker/containers \
        --volumes-from www_proxy \
        --name www_proxy_conf \
        --hostname www_proxy_conf \
        kubler/nginx-proxy-conf

[Last Build][packages]

[docker-gen]: https://github.com/jwilder/docker-gen
[jwilder-blog]: http://jasonwilder.com/blog/2014/03/25/automated-nginx-reverse-proxy-for-docker/
[packages]: PACKAGES.md
