## kubler/python3

Run this [Python][] image with:

    $ docker run -it --rm --name bash kubler/python3 python

Comes with [Pip][].

The image comes with a `python` user for unprivileged container usage. To ease development pains
you can use the provided [ONBUILD][] instructions. Docker-Compose example:

```
version: '2.3'
services:
  app:
    build:
      dockerfile: ${PWD}/docker/Dockerfile
      context: ./docker
      args:
        - PYTHON_UID=${UID}
        - PYTHON_GID=${GID}
    user: python
    working_dir: ${PWD}
    volumes:
      - ~/.somecache:/home/python/.somecache
      - ${PWD}:${PWD}
```

The referenced Dockerfile:

```
FROM kubler/python3
```

The [ONBUILD][] instructions are triggered by setting the `PYTHON_UID` and `PYTHON_GID` docker build args
and will set the image's `python` user uid/gid to the passed values. Then we just mount some local folders and
the project source for a close to native development environment.

Note: The example above expects the environment variables `UID` and `GID`, on Bash `UID` is an internal
variable and not exported by default! You may want to add the following to your `~/.bashrc`:

```
export UID
export GID="$(id -g $(whoami))"
```

[Last Build][packages]

[Python]: https://www.python.org/
[Pip]: https://github.com/pypa/pip
[packages]: PACKAGES.md
