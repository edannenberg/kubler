gentoo-bb
=========

Build framework to produce minimal root file systems based on [Gentoo][]. It's primarily intended for maintaining an organization's
[LXC][] base image stack(s), but can probably fairly easy (ab)used for other use cases involving a custom root fs, cross compiling comes to mind.

Currently supported build engines:

* [Docker][]

Planned support:

* [rkt][]

PR are always welcome. ;)

## News

* 20160211 images include patches for [cve-2015-7547](https://googleonlinesecurity.blogspot.de/2016/02/cve-2015-7547-glibc-getaddrinfo-stack.html)

## Goals

* Central organization-wide management of base images
* Full control over image content across all layers
* Containers should only contain the bare minimum to run
  * Separate build and runtime dependencies
  * Only deploy runtime dependencies
* Maximum flexibility while assembling the rootfs, but with minimal effort
* Keep things maintainable as the stack grows

## Status

* Stable for a while now and powers a good amount of our internal infrastructure, too scared still for docker in the wild :)
* Monthly update cycle for all reference images

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
* Tiny static busybox-musl root image (~1.2mb), FROM scratch is fine too
* Shared layer support for final images, images are not squashed and can depend on other images
* [s6][] instead of [OpenRC][] as default supervisor (small footprint (<1mb) and proper docker SIGTERM handling), optional of course
* Reference images are available on [docker hub][gentoo-bb-docker]
* Push image stack(s) to a public or private docker registry

## How much do I save?

* Quite a bit, the Nginx Docker image, for example, clocks in at ~17MB, compared to >1GB for a full Gentoo version or ~300MB for a similiar Ubuntu version

## Quick Start

    $ git clone https://github.com/edannenberg/gentoo-bb.git
    $ cd gentoo-bb
    $ ./build.sh build gentoobb/glibc

This will build a busybox and glibc image. To build all images you may run `./build.sh`. 

* If you don't have GPG available use `-s` to skip verification of downloaded files (SHA512 is still checked)
* Check the directories in `dock/gentoobb/images/` for image specific documentation

For testing container stacks see the [docker-compose](https://github.com/edannenberg/gentoo-bb/tree/master/docker-compose) section.
All reference images are available via docker hub. You may skip the build process if you just want to play around with
those before investing your precious cpu cycles. :p

The first run will take quite a bit of time, don't worry, once the build containers and binary package cache are seeded
future runs will be much faster.

## Creating a new namespace

Images are kept in a directory in `./dock/`, called `namespace`. You may have any number of namespaces. A helper is
provided to take care of the boiler plate for you: 

```
 $ cd gentoo-bb/
 $ ./build.sh add namespace somename
 --> Who maintains the new namespace?
 Name (John Doe): My Name
 EMail (john@doe.net): my@mail.org
 --> What type of images would you like to build?
 Engine (docker):

 --> Successfully added somename namespace at ./dock/somename

 $ tree dock/somename/
 dock/somename/
 |-- .gitignore
 |-- build.conf
 .-- README.md
```

You are now ready to work on your shiny new image stack.

## Adding Docker images

Let's create a test image in our new namespace. If you chose a more sensible namespace name above replace `somename`
accordingly:

```
 $ ./build.sh add image somename/figlet
 --> Do you want to extend an existing image? Full image id (i.e. gentoobb/busybox) or scratch
 Parent Image (scratch): gentoobb/glibc

 --> Successfully added somename/figlet image at ./dock/somename/images/figlet
```

We used `gentoobb/glibc` as parent image, or what you probably know as `FROM` in your `Dockerfiles`. The namespace now looks
like this:
 
```
 $ tree dock/somename/
 dock/somename/
 |-- build.conf
 |-- images
 |   .-- figlet
 |       |-- build.conf
 |       |-- build.sh
 |       |-- Dockerfile.template
 |       .-- README.md
 .-- README.md
```

Edit the new image's build script located at `./dock/somename/images/figlet/build.sh`. For now lets just install [figlet](http://www.figlet.org/) by adding it
to the `PACKAGES` variable:

```
PACKAGES="app-misc/figlet"
```

When it's time to build this will instruct the build container in the *first build phase* to install the given package(s)
from Gentoo's package tree at an empty directory. It's content is then exported to the host as `rootfs.tar` file.
In the *second build phase* a normal Docker build is started and the `rootfs.tar` file is added to the final image.

See the 'how does it work' section below for more details on the build process. Also make sure to read the comments
in `build.sh`. But let's build the darn thing already:

```
 $ ./build.sh build somename
```

Once that finishes we are ready to take the image for a test drive:

```
 $ docker images | grep /figlet
 $ docker run -it --rm somename/figlet figlet gentoo-bb
```

Some useful options for `build.sh` while working on an image:

Start an interactive build container, same as used in the first phase to create the `rootfs.tar`:

    $ ./bin/bob-interactive.sh mynamespace/myimage

Force rebuild of myimage and all images it depends on:

    $ ./build.sh -f build mynamespace/myimage

Same as above, but also rebuild all `rootfs.tar` files:

    $ ./build.sh -F build mynamespace/myimage

Only rebuild myimage1 and myimage2, ignore images they depend on:

    $ ./build.sh -nF build mynamespace/{myimage1,myimage2}

## Updating build containers to a newer Gentoo stage3 release

First check for new releases by running:

    $ ./build.sh update

If a new release was found simply rebuild the stack by running:

    $ ./build.sh clean
    $ ./build.sh -C

* Minor things might (read will) break, Oracle downloads, for example, may not work.

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
* `build-root.sh` reads `build.sh` from the mounted `/config` directory
* if `configure_bob()` hook is defined in `build.sh` (in `/config`), execute it
* `package.installed` file is generated which is used by depending images as `package.provided`
* if `configure_rootfs_build()` hook is defined in `build.sh` (in `/config`), execute it
* `PACKAGES` defined in `build.sh` (in `/config`) are installed at a custom empty root directory
* if `finish_rootfs_build()` hook is defined in `build.sh` (in `/config`), execute it
* resulting `rootfs.tar` is placed in `/config`, end of first build phase
* used build container gets committed as a new builder image which will be used by other builds depending on this image, this preserves exact build state
* `build.sh` (in gentoo-bb root) then starts a normal docker build that uses `rootfs.tar` to create the final image

Build container names generally start with `gentoobb/bob`, when a new build container state is committed the current image name gets appended.
For example `gentoobb/bob-openssl` refers to the container used to build the `gentoobb/openssl` image.

## Thanks

[@wking][] for his [gentoo-docker][] repo which served as an excellent starting point

[@jbergstroem][] for all his contributions and feedback to this project <3

[LXC]: https://en.wikipedia.org/wiki/LXC
[gentoo-docker]: https://github.com/wking/dockerfile
[bob-core]: https://github.com/edannenberg/gentoo-bb/tree/master/bob-core
[s6]: https://skarnet.org/software/s6/
[OpenRC]: https://wiki.gentoo.org/wiki/OpenRC
[Docker]: https://www.docker.com/
[rkt]: https://github.com/coreos/rkt
[gentoo-bb-docker]: https://hub.docker.com/search/?q=gentoobb&page=1&isAutomated=0&isOfficial=0&starCount=0&pullCount=0
[nginx-packages]: https://github.com/edannenberg/gentoo-bb/blob/master/dock/gentoobb/images/nginx/PACKAGES.md
[Gentoo]: https://www.gentoo.org/
[binary package]: https://wiki.gentoo.org/wiki/Binary_package_guide
[CoreOS]: https://coreos.com/
[@wking]: https://github.com/wking
[@jbergstroem]: https://github.com/jbergstroem
