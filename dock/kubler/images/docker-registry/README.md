## kubler/docker-registry

Run this [docker-registry][] 2.x image with:

    $ mkdir /var/lib/docker-registry
    $ docker run -d --name docker-registry \
       -v /var/lib/docker-registry:/tmp/registry \
       -p 5000:5000 kubler/docker-registry

Assuming the [nginx-proxy][] container is running, you can also start the registry with VIRTUAL_HOST and VIRTUAL_PORT ENV set:

    $ docker run -d --name docker-registry \
       -e VIRTUAL_HOST=docker.local \
       -e VIRTUAL_PORT=5000 \
       -v /var/lib/docker-registry:/tmp/registry \
       kubler/docker-registry

When using a self signed CA for the proxy you need to either pass `--insecure-registry docker.local` to your docker daemon
or copy the CA to `/etc/docker/certs.d/docker.local/ca.crt` on each box that wants to use the registry.

To test the registry:

    $ docker tag someimage docker.local/someimage
    $ docker push docker.local/someimage
    $ docker rmi docker.local/someimage
    $ docker pull docker.local/someimage

Searching the registry is currently not implemented, should be in soon though.

Also see the [docker-registry-docs][].

[Last Build][packages]

[docker-registry]: https://github.com/docker/distribution/
[docker-registry-docs]: https://github.com/docker/distribution/blob/master/docs/index.md
[nginx-proxy]: https://github.com/edannenberg/gentoo-bb/tree/master/bb-dock/nginx-proxy
[packages]: PACKAGES.md
