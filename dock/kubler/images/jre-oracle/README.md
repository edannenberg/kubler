## kubler/jre-oracle

Run this [Java][] image with:

    $ docker run -it --rm kubler/jre-oracle

The image comes with a `java` user for unprivileged container usage. To ease development pains
you can use the provided [ONBUILD][] instructions. Docker Compose example for a Gradle project:

```
version: '2'
services:
  app:
    build:
      dockerfile: ${PWD}/docker/Dockerfile
      context: ./docker
      args:
        - JAVA_UID=${UID}
        - JAVA_GID=${GID}
    user: java
    working_dir: ${PWD}
    volumes:
      - ~/.m2:/home/java/.m2
      - ~/.gradle:/home/java/.gradle
      - ${PWD}:${PWD}
    command: [./gradlew, some-task]
```

The referenced Dockerfile:

```
FROM kubler/jre-oracle
```

The [ONBUILD][] instructions are triggered by setting `JAVA_UID` and `JAVA_GID` docker build args and will
set the image's `java` user uid/gid to the passed values. Then we just mount some local cache folders and
the project source for a close to native development environment.

Note: The example above expects the environment variables `UID` and `GID`, on Bash `UID` is an internal
variable and not exported by default! You may want to add the following to your `~/.bashrc`:

```
export UID
export GID="$(id -g $(whoami))"
```

[Last Build][packages]

[Java]: https://www.oracle.com/java/index.html
[packages]: PACKAGES.md
[ONBUILD]: https://docs.docker.com/engine/reference/builder/#onbuild
