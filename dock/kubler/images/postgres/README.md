## kubler/postgres

Run this [PostgreSQL][] image with:

    $ docker run -d --name db-0 -v /data/db/db-0:/var/lib/postgresql/data kubler/postgres

Then [link][linking] to it from your client container:

    $ docker run --it --rm --link db-0:db your-client

The container will check `/var/lib/postgresql/data` on startup, if empty it will install a default database.
Admin credentials for the new database can be set via env:

    $ docker run -d --name db-0 \
        -e POSTGRES_PASSWORD=secret
        -e POSTGRES_USER=admin \
        -e POSTGRES_DB=mydb \
        kubler/postgres

Defaults if omitted:

    POSTGRES_PASSWORD=<empty> (no pw)
    POSTGRES_USER=postgres
    POSTGRES_DB=$POSTGRES_USER

To enable backups set `BACKUP_CRON_SCHEDULE` to a standard cron expression, i.e. to backup daily at 5am:

    $ docker run -d --name db-0 \
        -e BACKUP_CRON_SCHEDULE='0 5 * * *' \
        -v /host_backups/db-0:/backup \
        kubler/postgres

The default backup command can be overridden with `BACKUP_CRON_EXEC`.

To run a custom command as part of the default container startup you may use `EXEC_ON_START`, i.e.

    -e EXEC_ON_START='echo hi'

[Last Build][packages]

[PostgreSQL]: http://www.postgresql.org/
[linking]: http://docs.docker.io/en/latest/use/port_redirection/#linking-a-container
[packages]: PACKAGES.md
