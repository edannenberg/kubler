## kubler/nginx-proxy

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

The default proxy certs are generated in `localhost/`, certs for each vhost are expected in `$VIRTUAL_HOST/`.
Symlinks to the default cert are created on config change for each host. Replace with your own certs
per host as needed.

Example Docker Compose setup:

```
version: '2.0'
services:
  nginx:
    image: kubler/nginx-proxy
    restart: always
    volumes:
     - /home/data/runtime/nginx_proxy/certs:/etc/nginx/ssl
    ports:
     - "80:80"
     - "443:443"

  conf:
    image: kubler/nginx-proxy-conf
    restart: always
    volumes:
     - /var/run/docker.sock:/var/run/docker.sock:ro
    volumes_from:
     - nginx
```

For security reasons the conf container is separated from the nginx container because [docker-gen][]
requires the host's docker socket. Check the nginx-proxy-conf documentation for more details.

Finally to use the proxy container simply pass `VIRTUAL_HOST` and `VIRTUAL_PORT` ENVs to containers you
wish to proxy:

    $ docker run -d \
        -e VIRTUAL_HOST=foo.void \
        --name www \
        --hostname www \
        kubler/nginx-php7

Provided your dns resolves foo.void to the host the www_proxy container is running on, you can now access
the www container via http://foo.void in your browser. `VIRTUAL_PORT` defaults to 80 and can be omitted.

To create a http->https redirect set `VIRTUAL_FORCE_HTTPS=true`.

Websocket proxying for any sub path can be enabled by setting `VIRTUAL_WS_PATH=/my-ws-connection`.

Note: Docker Compose version 2 markup creates a custom network for each project, you need to connect containers
to the nginx-proxy container:

```
version: '2'
services:
  foo:
    image: kubler/nginx-php7
    networks:
      - extern
      - default
  db:
    image: kubler/postgres
networks:
  extern:
    external:
      name: nginxproxy_default
```

The order of `networks` is important, always list the external network first or the nginx-proxy-conf container
will use a non-reachable IP from `foo`'s default network.

[Last Build][packages]

[Nginx]: http://nginx.org/
[docker-gen]: https://github.com/jwilder/docker-gen
[packages]: PACKAGES.md
