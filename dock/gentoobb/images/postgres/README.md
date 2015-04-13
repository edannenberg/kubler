Run this [PostgreSQL][] image with:

    $ docker run -d --name db-0 -v /data/db/db-0:/var/lib/postgresql/data gentoobb/postgres

Then [link][linking] to it from your client container:

    $ docker run --it --rm --link db-0:db your-client

The container will check `/var/lib/postgresql/data` on startup, if empty it will install a default database.
Admin credentials for the new database can be set via env:

    $ docker run -d --name db-0 \
        -e POSTGRES_PASSWORD=secret
        -e POSTGRES_USER=admin \
        -e POSTGRES_DB=mydb \
        gentoobb/postgres

Defaults if omitted:

    POSTGRES_PASSWORD=<empty> (no pw)
    POSTGRES_USER=postgres
    POSTGRES_DB=$POSTGRES_USER

[PostgreSQL]: http://www.postgresql.org/
[linking]: http://docs.docker.io/en/latest/use/port_redirection/#linking-a-container
