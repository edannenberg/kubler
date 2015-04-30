Run this [docker-registry][] image with:

    $ mkdir /var/lib/docker-registry
    $ docker run -d --name docker-registry \
       -v /var/lib/docker-registry:/tmp/registry \
       -p 5000:5000 gentoobb/docker-registry

To search the registry:

    $ curl -X GET http://localhost:5000/v2/search?q=test

The image only supports http connections, for smooth docker integration put the container behind a https proxy.
Assuming the [nginx-proxy][] container is running, just start the registry with VIRTUAL_HOST and VIRTUAL_PORT ENV set:

    $ docker run -d --name docker-registry \
       -e VIRTUAL_HOST=docker.local \
       -e VIRTUAL_PORT=5000 \
       -v /var/lib/docker-registry:/tmp/registry \
       gentoobb/docker-registry

When using a self signed CA for the proxy you need to either pass `--insecure-registry docker.local` to your docker daemon
or copy the CA to `/etc/docker/certs.d/docker.local/ca.crt` on each box that wants to use the registry.

You can now search the registry like this:

    $ docker search docker.local/test

Pushing to a private docker registry is currently pretty awkward. You might wanna have a look at [push.sh][].

[docker-registry]: https://github.com/docker/distribution/
[nginx-proxy]: https://github.com/edannenberg/gentoo-bb/tree/master/bb-dock/nginx-proxy
[push.sh]: https://github.com/edannenberg/gentoo-bb/blob/master/push.sh
