Testing Image Stacks
====================

For testing the base images after updates we utilize [docker-compose](https://docs.docker.com/compose/) with a thin wrapper script to handle environment variables in a sane way.

## Quick Start

Provided you already have python and pip, you can install docker-compose by invoking:

    $ sudo pip install docker-compose

The wrapper scripts are located in the `bin/` folder and have `dc_` as file name prefix. All arguments are passed straight to the `docker-compose` binary.

Almost all of the provided docker-compose files are expecting a running reverse proxy for http access. So let's get that out of the way first:

    $ ./bin/dc_nginx_proxy.sh up -d

The nginx proxy container is fully automated and based on Jason Wilder's excellent [docker-gen][] utility.
If you are not familar with it you should definitely check it out. For more information visit his [blog][jwilder-blog].

In case you don't want to constantly tune your `/etc/hosts` file to map domain names to your localhost interface I recommend installing a dns forwarder like [dnsmasq](https://en.wikipedia.org/wiki/Dnsmasq). Then just settle on a fake top level domain and forward everything to localhost. If `ping whatever.void` resolves you are good to go.

Now simply fire up container stacks of your choice, lets try the good old lamp:

    $ ./bin/dc_nginx_php_mariadb.sh up -d

The wrapper script will output some details on how to access the containers.

To check the container status:

    $ ./bin/dc_nginx_php_mariadb.sh ps

To stop the stack:

    $ ./bin/dc_nginx_php_mariadb.sh stop

## Adding a wrapper

First create a docker [compose file](https://docs.docker.com/compose/compose-file/). You can put the file anywhere you want, but I recommend placing it in the `docker-compose/` folder. You might also find some inspiration in the existing docker-compose files in that folder if you are new to docker-compose.

Finally add this wrapper script skeleton in `bin/`:

```bash
#!/bin/bash
set -a

# If you want to override variables defined in run.conf, while stile providing
# POSIX parameter expansion, override before sourcing the wrapper script.

# docker-compose project name, essentially the container name prefix. no white space!
DC_PROJECT_NAME="${DC_PROJECT_NAME:-my_project}"

# source generic wrapper script and defaults from run.conf
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/../inc/dc-wrapper.sh" || exit 1

# docker-compose file location
DC_FILE="${DC_DIR}/my-docker-compose-file.yml"

# services config
MY_ENV="${MY_ENV:-some value}"

STARTUP_MSG="SOME INFO"

dc-wrapper "$@"
```

Modify `DC_PROJECT_NAME` and `DC_FILE`, then simply add more ENV as required in your docker-compose file. The full power of bash is at your disposal. :)

[docker-gen]: https://github.com/jwilder/docker-gen
[jwilder-blog]: http://jasonwilder.com/blog/2014/03/25/automated-nginx-reverse-proxy-for-docker/
