## kubler/pure-ftpd

Run this [pure-ftpd][] image with:

    $ docker run -d --name pureftpd \
        -p "21:21" -p "50010-50010:50000-50010" \
        -v /some/path/pureftpd/ssl:/etc/ssl/private \
        -v /some/path/pureftpd/passwd:/etc/pureftpd \
        -v /some/path/mydata:/var/ftp-data \
        kubler/pure-ftpd

Default config only allows explicit FTP over TLS. Unless you provide your own certs a self signed one is
created on container start. All users are chrooted to their configured home dir.

The image is configured for [virtual user](https://download.pureftpd.org/pub/pure-ftpd/doc/README.Virtual-Users)
auth. Some helper scripts for user management are provided:

    docker exec pureftpd pure-user-add.sh someuser /var/ftp-data/someuser
    docker exec pureftpd pure-user-list.sh
    docker exec pureftpd pure-user-show.sh someuser
    docker exec pureftpd pure-user-mod.sh someuser -d /var/ftp-data/some-user
    docker exec pureftpd pure-user-passwd.sh someuser
    docker exec pureftpd pure-user-del.sh someuser

A more real-life `docker-compose.yml`:

```
version: '2'
services:
  pureftpd:
    image: kubler/pure-ftpd
    environment:
      - FTPD_VIRT_UID
      - FTPD_VIRT_GID
      - FTPD_PORT=21
      - FTPD_MAX_CONN=25
      - FTPD_MAX_CONN_IP=5
      - FTPD_DISK_FULL=90%
      - FTPD_AUTH=puredb:/etc/pureftpd.pdb
      - FTPD_MISC=-p 50000:50010 -D -j -Z -Y 2 -A -b -E -R -k 99
      - CRT_COUNTRY=DE
      - CRT_STATE=SA
      - CRT_LOCACTION=MD
      - CRT_ORG=Some Org
      - CRT_CN=ftp.my.url
    ports:
      - "21:21"
      - "50000:50010"
    volumes:
      - /var/docker-data/pureftpd/cert:/etc/ssl/private
      - /var/docker-data/pureftpd/passwd:/etc/pureftpd
      - /var/www:/var/ftp-data
    restart: unless-stopped
    network_mode: host
```

In the example above `FTPD_VIRT_UID` and `FTPD_VIRT_GID` are expected to be exported on the host as environment
variables. If set, their values are set on container start as uid/gid for the `ftp-data` user. This allows to use
the same uid/gid in other containers, like nginx in a common shared web hosting scenario, avoiding any permission
problems.

All `FTPD_*` values above are the default values and can be safely omitted. `CRT_*` variables are only used when
creating the self signed certificate and can also be omitted.

---

Prior art this image is based on:

https://github.com/stilliard/docker-pure-ftpd
https://github.com/gimoh/docker-pureftpd

---

[Last Build][packages]

[pure-ftpd]: https://www.pureftpd.org/project/pure-ftpd
[packages]: PACKAGES.md
