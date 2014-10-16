Run this [Mysql][] image with:

    $ docker run -d --name db-0 -v /data/db/db-0:/var/lib/mysql/ gentoobb/mysql

Then [link][linking] to it from your client container:

    $ docker run --it --rm --link db-0:db your-client

Alternatively you can use the mysql server socket directly:

    $ docker run --it --rm --volumes-from db-0 gentoobb/mysql /bin/bash

The container will check /var/lib/mysql/ on startup, if empty it will install a default database.
Admin credentials for the new database can be set via env:

    $ docker run -d --name db-0 \
        -e MYSQL_ROOT_PW=secret
        -e MYSQL_ADMIN_USER=admin \
        -e MYSQL_ADMIN_PW=secret \
        gentoobb/mysql

Defaults if omitted:

    MYSQL_ROOT_PW=root
    MYSQL_ADMIN_USER=root
    MYSQL_ADMIN_PW=root

[volume-mounting][volume-mount] your content under the container's
`/var/lib/mysql`.  You can also mount volumes from other
containers and serve their data, although you may neet to tweak the
config to serve from an alternative location.

> If you remove containers that mount volumes, including the initial
> `DATA` container, or the middleman, the volumes will not be deleted
> until there are no containers still referencing those volumes. This
> allows you to upgrade, or effectivly migrate data volumes between
> containers.

[Mysql]: http://mysql.com/
[volume-mount]: http://docs.docker.io/en/latest/use/working_with_volumes/
[linking]: http://docs.docker.io/en/latest/use/port_redirection/#linking-a-container
[devicemapper-size-limit]: https://www.kernel.org/doc/Documentation/device-mapper/thin-provisioning.txt
[VOLUME]: http://docs.docker.io/en/latest/use/working_with_volumes/#getting-started
[fd24041]: https://github.com/SvenDowideit/docker/commit/fd240413ff835ee72741d839dccbee24e5cc410c
[3389]: https://github.com/dotcloud/docker/pull/3389
