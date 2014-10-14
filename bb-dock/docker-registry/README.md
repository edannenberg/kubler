Run this [docker-registry][] image with:

    $ mkdir /var/lib/docker-registry
    $ docker run -d --name docker-registry \
    >   -e SEARCH_BACKEND=sqlalchemy \
    >   -v /var/lib/docker-registry:/tmp/registry \
    >   -p 5000:5000 gentoobb/docker-registry

[docker-registry]: https://github.com/dotcloud/docker-registry/
