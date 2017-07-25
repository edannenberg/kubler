## kubler/nginx-proxy

Automated vhost proxy for any number of containers running on the same host.

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
version: '2.2'
services:
  nginx:
    image: kubler/nginx-proxy
    restart: always
    volumes:
     - /home/data/docker/nginx_proxy/certs:/etc/nginx/ssl
    ports:
     - "80:80"
     - "443:443"

  conf:
    image: kubler/nginx-proxy-conf
    restart: always
    environment:
     - PROXY_NETWORK=network_name
    volumes:
     - /var/run/docker.sock:/var/run/docker.sock:ro
    volumes_from:
     - nginx
```

Note: Docker Compose version 2 markup uses the Docker networks feature, to ensure the proxy-conf container picks the
right network you either need to set `PROXY_NETWORK` (usually `${your_compose_project_name}_default`) or conform to
the default by setting the expected `COMPOSE_PROJECT_NAME`. It's recommended to use the `.env` file for the latter:

```
COMPOSE_PROJECT_NAME=nginxproxy
```

Then connect your other containers you want to proxy to the `nginxproxy` network:

```
version: '2.2'
services:
  foo:
    image: kubler/nginx-php7
    environment:
      - VIRTUAL_HOST=www.foo.local
    networks:
      - proxy
      - default
  db:
    image: kubler/postgres

networks:
  proxy:
    external:
      name: nginxproxy_default
```

For security reasons the conf container is separated from the nginx container as [docker-gen][]
requires the host's docker socket. Check the [nginx-proxy-conf][] documentation for more details.

Finally to use the proxy container simply pass `VIRTUAL_HOST` and `VIRTUAL_PORT` ENVs to containers you
wish to proxy:

    $ docker run -d \
        -e VIRTUAL_HOST=foo.void \
        --name www \
        --hostname www \
        kubler/nginx-php7

Provided your dns resolves `foo.void` to the host the nginx-proxy container is running on, you can now access
the www container via http://foo.void in your browser. `VIRTUAL_PORT` defaults to 80 and can be omitted.

To create a http->https redirect set `VIRTUAL_FORCE_HTTPS=true`.

Websocket proxying for any sub path can be enabled by setting `VIRTUAL_WS_PATH=/my-ws-connection`.

[Last Build][packages]

[Nginx]: http://nginx.org/
[docker-gen]: https://github.com/jwilder/docker-gen
[nginx-proxy-conf]: ../nginx-proxy-conf/README.md
[packages]: PACKAGES.md
