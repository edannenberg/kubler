Run this [s6][] image with:

    $ docker run -d --name s6 gentoobb/s6

Provides a generic filesystem watcher service that can be configured via env. Disabled per default.

Example: The following snippet, used in a Dockerfile based on this image, will start a service that fires
a SIGHUP at nginx when the file /etc/nginx/sites-enabled/default.conf changes:

    ENV WATCHER_FS_CMD ls /etc/nginx/sites-enabled/default.conf
    ENV WATCHER_ONCHANGE pkill -HUP nginx
    # ENV WATCHER_OPT -d # optional, pass options to [entr][], -d is handy for watching directories
    RUN ln -s /etc/service/fs-watcher /service

[entr][] is used as fs watcher.

[s6]: http://skarnet.org/software/s6/
[entr]: http://entrproject.org/
