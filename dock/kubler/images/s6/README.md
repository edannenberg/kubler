## kubler/s6

Run this [s6][] image with:

    $ docker run -d --name s6 kubler/s6

Provides a generic filesystem watcher service that can be configured via env. Disabled per default.

Example: The following snippet, used in a `Dockerfile` based on this image, will start a service that fires
a `SIGHUP` at nginx when the file `/etc/nginx/sites-enabled/default.conf` changes:

    ENV WATCHER_FS_CMD ls /etc/nginx/sites-enabled/default.conf
    ENV WATCHER_ONCHANGE pkill -HUP nginx
    # ENV WATCHER_OPT -d # optional, pass options to [entr][], -d is handy for watching directories
    RUN ln -s /etc/service/fs-watcher /service

The service is just a simple wrapper for [entr][].

For full container signal control you may also customize the scripts in `/etc/service/.s6-svscan/`. Check the [s6-svscan][]
documentation for details. Note that you are not restricted to a `#!/bin/execlineb -P` shebang in those scripts, 
the usual `#!/bin/env sh` shebang will do as well.

Also includes a service to run [busybox-crond][]. Disabled per default. To enable the cron service in builds based on
this image:

    RUN echo '* * * * * echo hi' >> /var/spool/cron/crontabs/root && ln -s /etc/service/cron /service

[Last Build][packages]

[s6]: https://skarnet.org/software/s6/
[s6-svscan]: https://skarnet.org/software/s6/s6-svscan.html
[entr]: http://entrproject.org/
[busybox-crond]: https://www.busybox.net/downloads/BusyBox.html
[packages]: PACKAGES.md
