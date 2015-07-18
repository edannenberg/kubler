gentoo-bb
=========

Build framework to produce minimal root file systems based on [Gentoo][]. It's primarily intended for maintaining [LXC][] base image stacks,
but can probably fairly easy (ab)used for other use cases involving a custom root fs, cross compiling comes to mind.

Currently supported build engines:

* [Docker][]

Planned support:

* [Rocket][]

PR are always welcome. ;)

## Goals

* Containers should only contain the bare minimum to run
  * Separate build and runtime dependencies
  * Only deploy runtime dependencies
* Maximum flexibility while assembling the rootfs, but with minimal effort
* Keep things maintainable as the stack grows

## Features

* Decoupled build logic
* Maintain multiple image stacks with differing build engines
* Generic [root-fs][bob-core] build script to quickly bootstrap a build container
* Utilizes Gentoo's [binary package][] features for quick rebuilds
* Simple hook system allows for full control of the build process while retaining modularity
* Generic image and builder dependencies that can be utilized by build engines
* Automated image [documentation][nginx-packages] and history when using a CVS

### Docker Features

* Essentially enables [nested](https://github.com/docker/docker/issues/7115) docker builds
* Everything happens in docker containers except for some bash glue on the build host
* Tiny static busybox-uclibc root image (~1.2mb), FROM scratch is fine too
* Shared layer support for final images, images are not squashed and can depend on other images
* [s6][] instead of [OpenRC][] as default supervisor (small footprint (<1mb) and proper docker SIGTERM handling)
* Reference images are available on [docker.io][gentoo-bb-docker]
* Push image stack(s) to a public or private docker registry

## How much do I save?

* Quite a bit, the Nginx Docker image, for example, clocks in at ~20MB, compared to >1GB for a full Gentoo version or ~300MB for a similiar Ubuntu version

## Quick Start

    $ git clone https://github.com/edannenberg/gentoo-bb.git
    $ cd gentoo-bb
    $ ./build.sh

* If you don't have GPG available use `-s` to skip verification of downloaded files
* Check the directories in `dock/gentoobb/images/` for image specific documentation
* `bin/` contains a few scripts to start/stop container chains

## Creating a new namespace

```bash
    $ cd gentoo-bb/
    $ mkdir -p dock/mynamespace/images/
    $ cat <<END > dock/mynamespace/build.conf
AUTHOR="My Name <my@mail.org>"
DEF_BUILD_CONTAINER="gentoobb/bob"
CONTAINER_ENGINE="docker"
END
```

You are now ready to work on your shiny new image stack. The `build.conf` above defines the `gentoobb/bob` image
as `default build container`. You may set any build container from other namespaces or roll your own of course.
For most tasks the `gentoobb/bob` image should do just fine though.

## Adding Docker images

Let's setup a test image in our new namespace:

```bash
 $ cd gentoo-bb/
 $ mkdir -p dock/mynamespace/images/figlet
 $ cat <<END > dock/mynamespace/images/figlet/Buildconfig.sh
PACKAGES="app-misc/figlet"
END
 $ cat <<END > dock/mynamespace/images/figlet/Dockerfile.template
FROM gentoobb/glibc
ADD rootfs.tar /
CMD ["figlet", "gentoo-bb"]
END
 $ ./build.sh build mynamespace
```

Pretty straight forward, pass a Gentoo `package atom` to be installed in the first build phase and setup a `Dockerfile` that
assembles the final image. Again we use an image from another namespace as base for the final image. (gentoobb/glibc)

See the 'how does it work' section below for more details on the build process.

The first run will take quite a bit of time, don't worry, once the build containers and binary package cache are seeded future runs
will be much faster. Let's spin up the new image:

    $ docker images | grep /figlet
    $ docker run -it --rm mynamespace/figlet

 * All images must be located in `dock/<namespace>/images/`, directory name = image name
 * `Dockerfile.template` and `Buildconfig.sh` are the only required files
 * `build.sh` will pick up the image on the next run

Some useful options for `build.sh` while working on an image:

Start an interactive build container, same as used to create the rootfs.tar:

    $ ./bin/bob-interactive.sh mynamespace/myimage

Force rebuild of myimage and all images it depends on:

    $ ./build.sh -f build mynamespace/myimage

Same as above, but also rebuild all rootfs.tar files:

    $ ./build.sh -F build mynamespace/myimage

Only rebuild myimage1 and myimage2, ignore images they depend on:

    $ ./build.sh -nF build mynamespace/{myimage1,myimage2}

## Updating to a newer gentoo stage3 release

First check for a new release by running:

    $ ./build.sh update

If a new release was found simply rebuild the stack by running:

    $ ./build.sh -F

* Minor things might break, Oracle downloads, for example, may not work. You can always download them manually to `tmp/distfiles`.

## How does it work?

* `build.sh` reads global defaults from `build.conf`
* iterates over `dock/`
* reads `build.conf` in each `dock/<namespace>/` directory and imports defined `CONTAINER_ENGINE` from `inc/engine/`
* generates build order by iterating over `dock/<namespace>/images/`
* executes `build_core()` for each required engine to bootstrap the initial build container
* executes `build_builder()` for any other required build containers in `dock/<namespace>/builder/<repo>`
* executes `build_image()` to build each `dock/<namespace>/images/<repo>` 

Each implementation is allowed to only implement parts of the build process, if no build containers are required thats fine too.

### Docker specific build details

* `build_core()` builds a clean stage 3 image with portage snapshot and helper files from `./bob-core/`
* `build_image()` mounts each `dock/<namespace>/images/<repo>` directory into a fresh build container as `/config`
* executes `build-root.sh` inside build container
* `build-root.sh` reads `Buildconfig.sh` from the mounted `/config` directory
* if `configure_bob()` hook is defined in `Buildconfig.sh`, execute it
* `package.installed` file is generated which is used by depending images as `package.provided`
* if `configure_rootfs_build()` hook is defined in `Buildconfig.sh`, execute it
* `PACKAGES` defined in `Buildconfig.sh` are installed at a custom empty root directory
* if `finish_rootfs_build()` hook is defined in `Buildconfig.sh`, execute it
* resulting `rootfs.tar` is placed in `/config`, end of first build phase
* used build container gets committed as a new builder image which will be used by other builds depending on this image, this preserves exact build state
* `build.sh` then starts a normal docker build that uses `rootfs.tar` to create the final image

Build container names generally start with `gentoobb/bob`, when a new build container state is committed the current image name gets appended.
For example `gentoobb/bob-openssl` refers to the container used to build the `gentoobb/openssl` image.

## Thanks

[@wking][] for his [gentoo-docker][] repo which served as an excellent starting point

[@jbergstroem][] for all his contributions and feedback to this project <3

[LXC]: http://en.wikipedia.org/wiki/LXC
[gentoo-docker]: https://github.com/wking/dockerfile
[bob-core]: https://github.com/edannenberg/gentoo-bb/tree/master/bob-core
[s6]: http://skarnet.org/software/s6/
[OpenRC]: http://wiki.gentoo.org/wiki/OpenRC
[Docker]: http://www.docker.io/
[Rocket]: https://github.com/coreos/rocket
[gentoo-bb-docker]: https://registry.hub.docker.com/repos/gentoobb/?&s=alphabetical
[nginx-packages]: https://github.com/edannenberg/gentoo-bb/blob/master/dock/gentoobb/images/nginx/PACKAGES.md
[Gentoo]: http://www.gentoo.org/
[binary package]: https://wiki.gentoo.org/wiki/Binary_package_guide
[CoreOS]: https://coreos.com/
[@wking]: https://github.com/wking
[@jbergstroem]: https://github.com/jbergstroem
