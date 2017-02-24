Run this [Nginx][] image with:

    $ docker run -d --name nginx-0 -v /var/www/nginx-0/htdocs:/var/www/localhost -p 80:80 -p 443:443 kubler/nginx

Default SSL certificates are expected at:

    /etc/nginx/ssl/localhost/nginx.{crt,key}

If missing, a self signed certificate is created on container start. [HTTP/2][] is enabled per default.

Due to the [POODLE][] exploit SSL3 is disabled per default.

To enable [forward-secrecy][] set NGINX_FORWARD_SECRECY on container start:

    $ docker run -d --name nginx-0 -v /var/www/nginx-0/htdocs:/var/www/localhost -p 80:80  -p 443:443 \
        -e NGINX_FORWARD_SECRECY=true
        kubler/nginx

The nginx main config sources *.conf files in /etc/nginx/conf.d/ and /etc/nginx/sites-enabled/

Default server{} config is in:

    /etc/nginx/sites-enabled/default.conf

For dev setups you can specify the UID/GID of the nginx worker process:

    $ docker run -d --name nginx-0 -v /var/www/nginx-0/htdocs:/var/www/localhost -p 80:80  -p 443:443 \
        -e NGINX_UID=$(id -u $(whoami)) \
        -e NGINX_GID=$(id -g $(whoami)) \
        kubler/nginx

The nginx startup script also provides a simple templating mechanism for site config files:

    $ docker run -d --name nginx-0 -v /var/www/nginx-0/htdocs:/var/www/localhost -p 80:80 -p 443:443 \
        -e NG_TMPL_MY_VAR=my_value \
        kubler/nginx

This would replace the marker named ##_NG_TMPL_MY_VAR_## with the provided value in all .conf files in /etc/nginx/sites-enabled.
Template variable names must start with NG_TMPL_.

[Nginx]: http://nginx.org/
[forward-secrecy]: http://en.wikipedia.org/wiki/Forward_secrecy
[POODLE]: http://en.wikipedia.org/wiki/POODLE
[HTTP/2]: https://en.wikipedia.org/wiki/HTTP/2

