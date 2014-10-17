Run this [Nginx][] image with:

    $ docker run -d --name nginx-0 -v /var/www/nginx-0/htdocs:/var/www/localhost -p 80:80 -p 443:443 gentoobb/nginx

Default SSL certificates are expected at: 

    /etc/nginx/ssl/nginx.{crt,key}

If they are missing a self signed certificate is created on container start.

The nginx config reads *.conf files in /etc/nginx/sites-enabled if you want to add further config. 

Default server{} config is in: 

    /etc/nginx/sites-enabled/default.conf

For dev setups you can specify the UID/GID of the nginx worker process:

    $ docker run -d --name nginx-0 -v /var/www/nginx-0/htdocs:/var/www/localhost -p 80:80  -p 443:443 \
        -e NGINX_UID=$(id -u $(whoami)) \
        -e NGINX_GID=$(id -g $(whoami)) \
        gentoobb/nginx

The nginx startup script also provides a simple templating mechanism for site config files:

    $ docker run -d --name nginx-0 -v /var/www/nginx-0/htdocs:/var/www/localhost -p 80:80 -p 443:443 \
        -e NG_TMPL_MY_VAR=my_value \
        gentoobb/nginx

This would replace the marker named ##_NG_TMPL_MY_VAR_## with the provided value in all .conf files in /etc/nginx/sites-enabled.
Template variable names must start with NG_TMPL_.

[volume-mounting][volume-mount] your content under the container's
`/var/www/localhost`.  You can also mount volumes from other
containers and serve their data, although you may neet to tweak the
config to serve from an alternative location.  Adjusting this image to
serve from a configurable `$HTTP_ROOT` wouldn't be too difficult
either.

[Nginx]: http://nginx.org/
[volume-mount]: http://docs.docker.io/en/latest/use/working_with_volumes/
