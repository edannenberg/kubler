## kubler/mariadb

Run this [MariaDB][] image with:

    $ docker run -d --name db-0 -v /data/db/db-0:/var/lib/mysql/ kubler/mariadb

Then [link][linking] to it from your client container:

    $ docker run --it --rm --link db-0:db your-client

Alternatively you can use the mysql server socket directly:

    $ docker run --it --rm --volumes-from db-0 kubler/mysql /bin/bash

The container will check /var/lib/mysql/ on startup, if empty it will install a default database.
Admin credentials for the new database can be set via env:

    $ docker run -d --name db-0 \
        -e MYSQL_ROOT_PW=secret
        -e MYSQL_ADMIN_USER=admin \
        -e MYSQL_ADMIN_PW=secret \
        kubler/mysql

Defaults if omitted:

    MYSQL_ROOT_PW=root
    MYSQL_ADMIN_USER=root
    MYSQL_ADMIN_PW=root

To enable backups set `BACKUP_CRON_SCHEDULE` to a standard cron expression, i.e. to backup daily at 5am:

    $ docker run -d --name db-0 \
        -e BACKUP_CRON_SCHEDULE='0 5 * * *' \
        -v /host_backups/db-0:/backup \
        kubler/mariadb

Backup related ENV and their defaults:

    BACKUP_THREADS=auto
    BACKUP_COMPRESSION_TYPE=bzip2
    BACKUP_CREATE_DB=yes # create db statement in dump
    BACKUP_EXCLUDE_DB=information_schema performance_schema
    BACKUP_LATEST_LINK=yes
    BACKUP_LATEST_CLEAN=yes # remove dates from latest filenames

[volume-mounting][volume-mount] your content under the container's
`/var/lib/mysql`.  You can also mount volumes from other
containers and serve their data, although you may neet to tweak the
config to serve from an alternative location.

> If you remove containers that mount volumes, including the initial
> `DATA` container, or the middleman, the volumes will not be deleted
> until there are no containers still referencing those volumes. This
> allows you to upgrade, or effectivly migrate data volumes between
> containers.

[Last Build][packages]

[MariaDB]: https://mariadb.org/
[volume-mount]: http://docs.docker.io/en/latest/use/working_with_volumes/
[linking]: http://docs.docker.io/en/latest/use/port_redirection/#linking-a-container
[packages]: PACKAGES.md
