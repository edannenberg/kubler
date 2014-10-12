Run this [Nginx][] image with:

    $ docker run -d --name nginx-0 -v /var/www/nginx-0/htdocs:/var/www/localhost -p 80:80 gentoobb/nginx

Default SSL certificates are expected at: 

    /etc/nginx/ssl/nginx.{crt,key}

If they are missing a self signed certificate is created on container start.

The default config reads *.conf files in /etc/nginx/sites-enabled if you want to add further config. 

Default server{} config is in: 

    /etc/nginx/sites-enabled/default.conf

[volume-mounting][volume-mount] your content under the container's
`/var/www/localhost`.  You can also mount volumes from other
containers and serve their data, although you may neet to tweak the
config to serve from an alternative location.  Adjusting this image to
serve from a configurable `$HTTP_ROOT` wouldn't be too difficult
either.

[Nginx]: http://nginx.org/
[volume-mount]: http://docs.docker.io/en/latest/use/working_with_volumes/
