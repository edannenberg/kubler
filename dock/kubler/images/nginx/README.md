## kubler/nginx

Run this [Nginx][] image with:

    $ docker run -d --name nginx-0 -v /var/www/nginx-0/htdocs:/var/www/localhost -p 80:80 -p 443:443 kubler/nginx

##### Site config

The Nginx main config sources `*.conf` files in `/etc/nginx/conf.d/` and `/etc/nginx/sites-enabled/`

Default `server{}` config is in:

    /etc/nginx/sites-enabled/default.conf

For dev setups you may specify the `UID/GID` of the Nginx worker process:

    $ docker run -d --name nginx-0 -v /var/www/nginx-0/htdocs:/var/www/localhost -p 80:80  -p 443:443 \
        -e NGINX_UID=$(id -u $(whoami)) \
        -e NGINX_GID=$(id -g $(whoami)) \
        kubler/nginx

##### SSL options

Default SSL certificates are expected at:

    /etc/nginx/certs/default.{crt,key}

If missing, a self signed certificate is created on container start. [HTTP/2][] is enabled per default.

Due to the [POODLE][] exploit SSL3 is disabled per default.

To enable [forward-secrecy][] set `NGINX_FORWARD_SECRECY` on container start:

    $ docker run -d --name nginx-0 -v /var/www/nginx-0/htdocs:/var/www/localhost -p 80:80  -p 443:443 \
        -v /host/data/certs:/etc/nginx/certs
        -e NGINX_FORWARD_SECRECY=true
        kubler/nginx

##### Templating Nginx config files

The Nginx startup script also provides a simple templating mechanism for site config files:

    $ docker run -d --name nginx-0 -v /var/www/nginx-0/htdocs:/var/www/localhost -p 80:80 -p 443:443 \
        -e NG_TMPL_MY_VAR=my_value \
        kubler/nginx

This would replace the marker named `##_NG_TMPL_MY_VAR_##` with the provided value in all `.conf` files in 
`/etc/nginx/sites-enabled`. Template variable names must start with `NG_TMPL_`.

#### RealIP

If your Nginx container is running behind a proxy you may want to set `NGINX_REAL_IP_FROM` to get the real ip for all
requests:

$ docker run -d --name nginx-0 -v /var/www/nginx-0/htdocs:/var/www/localhost \
        -e "VIRTUAL_HOST=foo.net"
        -e "NGINX_REAL_IP_FROM=172.18.0.0/16" \
        kubler/nginx 

See [real_ip_from][] docs for details.

##### SIGHUP signal handling

To mirror the Nginx process behaviour for handling `SIGHUP` you may pass `-e NGINX_RELOAD_ON_CONTAINER_SIGHUP=true` on
container start. Reloading the Nginx config from the Docker host is then as easy as invoking `docker kill -s SIGHUP <my_nginx>`.

[Last Build][packages]

[Nginx]: http://nginx.org/
[real_ip_from]: http://nginx.org/en/docs/http/ngx_http_realip_module.html#set_real_ip_from
[forward-secrecy]: http://en.wikipedia.org/wiki/Forward_secrecy
[POODLE]: http://en.wikipedia.org/wiki/POODLE
[HTTP/2]: https://en.wikipedia.org/wiki/HTTP/2
[packages]: PACKAGES.md
