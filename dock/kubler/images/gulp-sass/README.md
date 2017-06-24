## kubler/gulp-sass

Run this [Gulp][] and [libsass][] image with:

    $ docker run -it --rm -v /some/project:/some/project kubler/gulp-sass

The image comes with a `nodejs` user for unprivileged container usage. See [kubler/nodejs](../nodejs/README.md) for
details. Docker-Compose example:

```
version: '2.2'
services:
  gulp:
    build:
      dockerfile: ${PWD}/docker/Dockerfile.gulp
      context: ./docker
      args:
        - NODEJS_UID=${UID}
        - NODEJS_GID=${GID}
    command: ["gulp", "watch"]
    stdin_open: true
    tty: true
    working_dir: ${PWD}
    user: nodejs
    volumes:
      - ~/.npm:/home/nodejs/.npm
      - ${PWD}:${PWD}
```

The referenced Dockerfile just points to the image:

```
FROM kubler/gulp-sass
```

Note: The example above expects the environment variables `UID` and `GID`, on Bash `UID` is an internal
variable and not exported by default! You may want to add the following to your `~/.bashrc`:

```
export UID
export GID="$(id -g $(whoami))"
```

Consider using [gulp-plumber][] in your project to prevent container exit on sass/css errors while `gulp watch`
is running.

[Last Build][packages]

[Gulp]: http://gulpjs.com/
[libsass]: http://sass-lang.com/libsass
[gulp-plumber]: https://github.com/floatdrop/gulp-plumber
[packages]: PACKAGES.md
[ONBUILD]: https://docs.docker.com/engine/reference/builder/#onbuild
