## kubler/nginx-proxy-conf

This is pretty much a copy of Jason Wilder's [jwilder-proxy][nginx-proxy] project. See the upstream documentation for
usage and configuration options. Docker Compose example:

```
version: '2.3'
services:
  nginx:
    image: kubler/nginx
    restart: always
    environment:
     - "NGINX_RELOAD_ON_CONTAINER_SIGHUP=true"
    volumes:
     - /home/data/nginx_proxy/certs:/etc/nginx/certs
     - /etc/nginx/sites-enabled
    ports:
     - "80:80"
     - "443:443"

  conf:
    image: kubler/nginx-proxy-conf
    restart: always
    environment:
      - "CERT_DEFAULT_FALLBACK=true"
      # replace the project name accordingly, the var can be omitted if the project name is `nginxproxy`
      - "NGINX_ID=${compose_project_name}_nginx_1"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    volumes_from:
      - nginx
``` 

#### Differences with original nginx-proxy project

This image does not contain Nginx and requires a separate Nginx container to run in tandem with, enforcing security
and reducing image size as a nice bonus.

##### NGINX_ID

`NGINX_ID` env is used by the Dockerfile `CMD` for sending a `SIGHUP` to the Nginx container on changes.
If you override the `CMD` the var can be ignored. Convention over configuration is a thing, so the var defaults to 
`nginxproxy_nginx_1`, assuming a Docker Compose project with the name `nginxproxy` and a service named `nginx`.
One way to ensure the Compose project name is setting it via `.env` file in the Compose project dir:

```
COMPOSE_PROJECT_NAME=nginxproxy
```

##### CERT_DEFAULT_FALLBACK

The original config expects certs for each proxied container at `/etc/nginx/certs/${vhost_url}.crt`. If the file does
not exist the generated config serves a `500` for https attempts on those urls. This can be somewhat annoying, and 
now circumvented by passing `-e CERT_DEFAULT_FALLBACK=true` on container start, as in the Compose example above. 
If set, the auto-generated `default.crt` is used if the expected cert is missing.

[Last Build][packages]

[jwilder-proxy]: https://github.com/jwilder/nginx-proxy
[packages]: PACKAGES.md
