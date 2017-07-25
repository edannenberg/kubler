Kubler
======

### A container image meta builder

> [Wikipedia](https://en.wikipedia.org/wiki/Cooper_%28profession%29#.22Cooper.22_as_a_name) said:
In much the same way as the trade or vocation of smithing produced the common English surname Smith
and the German name Schmidt, the cooper trade is also the origin of German names like Kübler.
>
> There is still demand for high-quality ~~wooden barrels~~ containers, and it is thought that the
highest-quality ~~barrels~~ containers are those hand-made by professional ~~coopers~~ kublers.

At the core Kubler is just a simple ~~craftsman~~ bash script that, well, builds things.. and things that
can depend on other things. It does'nt really care all too much about the details as long as it gets 
to build. So what, some ~~people~~ scripts just like to build things. Don't judge.

What kind of things? In theory your imagination is the limit, but we provide batteries for building
[Docker][] images, with [acbuild][] (read: rkt and OCI) support in the works. PR are always welcome. ;)  

Due to it's unrivaled flexibility [Gentoo][] is used under the hood as build container base, 
however the final images hold just the runtime dependencies for selected software packages, resulting
in very slim images. To achieve this a 2 phase build process is employed, essentially the often requested, but
still missing, Docker feature for [nested](https://github.com/docker/docker/issues/7115) image builds.

## Goals

* Central, organization-wide management of base images
* Containers should only contain the bare minimum to run
  * Separate build and runtime dependencies
  * Only deploy runtime dependencies
* Maximum flexibility while assembling the root file system, but with minimal effort
* Keep things maintainable as the stack grows

## Status

* Stable for a while now and used in production
* Monthly update cycle for all reference images

## Features

* Decoupled build logic
* Maintain multiple image stacks with differing build engines
* Generic [root-fs][bob-core] build script to quickly bootstrap a [Gentoo][] based build container
* Utilizes Gentoo's [binary package][] features for quick rebuilds
* Simple hook system allows for full control of the build process while retaining modularity
* Generic image and builder dependencies that can be utilized by build engines
* Automated image [documentation][nginx-packages] and history when using a CVS

### Docker Features

* Essentially enables [nested](https://github.com/docker/docker/issues/7115) docker builds
* Everything happens in docker containers except for some bash glue on the build host
* Glibc, Musl and Uclibc based build containers, each with complete toolchain out of the box
* Tiny static busybox-musl root image (~1.2mb), FROM scratch is fine too
* Shared layer support for final images, images are not squashed and can depend on other images
* [s6][] instead of [OpenRC][] as default supervisor (small footprint (<1mb) and proper docker SIGTERM handling),
optional of course
* Reference images are available on [docker hub][kubler-docker]
* Push built image stack(s) to a public or private docker registry

### Requirements

* Bash 4.x
* Working Docker setup

Optional:

* GPG for download verification

Kubler has been tested on Gentoo, CoreOS and macOS. It should run on all Linux distributions.

## How much do I save?

* Quite a bit, the Nginx Docker image, for example, clocks in at ~17MB, compared to >1GB for a full Gentoo version
or ~300MB for a similiar Ubuntu version

## Quick Start

    $ git clone https://github.com/edannenberg/kubler.git

Kubler needs a `working-dir` to operate from, much like `git` needs to be called from inside a git repo for most of its
functionality. You may also call Kubler from any sub directory and it will detect the proper path. The Kubler git repo 
comes with an example image stack, let's build a provided `glibc` image:

    $ cd kubler/
    $ ./kubler.sh build kubler/glibc

This will build a `kubler/busybox` and `kubler/glibc` image. You also get a glibc and musl based build container for
free, which you can utilize for your own images.

* You may add `kubler.sh` to your `PATH`, one-liner: `export PATH="${PATH}:/path/to/kubler/bin"` 
* If you don't have GPG available use `build -s ..` to skip verification of downloaded files (SHA512 is still checked)
* The directories in `./dock/kubler/images/` contain image specific documentation

Note: If you get a 404 error on downloading a Gentoo stage3 tar ball try running `kubler update` to resolve the issue.
The Gentoo servers only keep those files for a few weeks.

The first run will take quite a bit of time, don't worry, once the build containers and binary package cache
are seeded future runs will be much faster.

## Creating a new namespace

Images are kept in a `namespace` directory in `--working-dir`. You may have any number of namespaces. A helper is
provided to take care of the boiler plate for you: 

```
 $ cd kubler/
 $ ./kubler.sh new namespace testing
 
 --> Who maintains the new namespace?
 Name (John Doe): My Name
 EMail (john@doe.net): my@mail.org
 --> What type of images would you like to build?
 Engine (docker):

 --> Successfully added "testing" namespace at ./dock/testing

 $ tree dock/testing/
 dock/testing/
 |-- .gitignore
 |-- kubler.conf
 .-- README.md
```

You are now ready to work on your shiny new image stack.

## Adding Docker images

Let's create a [Figlet](http://www.figlet.org/) test image in our new namespace. If you chose a more
sensible namespace name above replace `testing` accordingly:

```
 $ ./kubler.sh new image testing/figlet

 --> Extend an existing image? Fully qualified image id (i.e. kubler/busybox) if yes or scratch
 Parent Image (scratch): kubler/glibc

 --> Successfully added testing/figlet image at ./dock/testing/images/figlet
```

We used `kubler/glibc` as parent image, or what you probably know as `FROM` in your `Dockerfiles`.
The namespace now looks like this:
 
```
 $ tree dock/testing/
 dock/testing/
 |-- kubler.conf
 |-- images
 |   .-- figlet
 |       |-- build.conf
 |       |-- build.sh
 |       |-- Dockerfile.template
 |       .-- README.md
 .-- README.md
```

Edit the new image's build script located at `./dock/testing/images/figlet/build.sh` and add `app-misc/figlet` to the
`_packages` variable:

```
_packages="app-misc/figlet"
```

When it's time to build this will instruct the build container in the *first build phase* to install the given package(s)
from Gentoo's package tree at an empty directory. It's content is then exported to the host as a `rootfs.tar` file.
In the *second build phase* a normal Docker build is started and the `rootfs.tar` file is added to the final image.

See the 'how does it work' section below for more details on the build process. Also make sure to read the comments
in `build.sh`. But let's build the darn thing already:

```
 $ ./kubler.sh build testing
```

Once that finishes we are ready to take the image for a test drive:

```
 $ docker images | grep /figlet
 $ docker run -it --rm kubler/figlet figlet kubler sends his regards
```

Some useful options for while working on an image:

Start an interactive build container, same as used in the first phase to create the `rootfs.tar`:

    $ ./kubler.sh build -i mynamespace/myimage

Force rebuild of myimage and all images it depends on:

    $ ./kubler.sh build -f mynamespace/myimage

Same as above, but also force a rebuild of any existing `rootfs.tar` files:

    $ ./kubler.sh build -F mynamespace/myimage

Only rebuild myimage1 and myimage2, ignore images they depend on:

    $ ./kubler.sh build -n -F mynamespace/{myimage1,myimage2}

## Updating build containers to a newer Gentoo stage3 release

First check for new releases by running:

    $ ./kubler.sh update

If a new stage3 release was found simply rebuild the stack by running:

    $ ./kubler.sh clean
    $ ./kubler.sh -C build mynamespace

* Minor things might (read will) break, Oracle downloads, for example, may not work.

## How does it work?

* `kubler.sh` determines `--working-dir` either by passed arg or by looking in the current dir and it's parents
* `kubler.sh` reads global defaults from `kubler.conf`
* iterates over current `--working-dir`
* reads `kubler.conf` in each `working-dir/<namespace>/` directory and imports defined `BUILD_ENGINE`
from `lib/engine/`
* generates build order by iterating over `working-dir/<namespace>/images/` for each required image
* executes `build_core()` for each required engine to bootstrap the initial build container
* executes `build_builder()` for any other required build containers in `working-dir/<namespace>/builder/<image>`
* executes `build_image()` to build each `working-dir/<namespace>/images/<image>` 

Each implementation is allowed to only implement parts of the build process, if no build containers
are required thats fine too.

### Docker specific build details

* `build_core()` builds a clean stage 3 image with some helper files from `./lib/bob-core/`
* `build_image()` mounts each `working_dir/<namespace>/images/<image>` directory into a fresh build container
as `/config`
* executes `build-root.sh` inside build container
* `build-root.sh` reads `build.sh` from the mounted `/config` directory
* if `configure_bob()` hook is defined in `build.sh`, execute it
* `package.installed` file is generated which is used by depending images as [package.provided][]
* if `configure_rootfs_build()` hook is defined in `build.sh`, execute it
* `_packages` defined in `build.sh` are installed at a custom empty root directory
* if `finish_rootfs_build()` hook is defined in `build.sh`, execute it
* resulting `rootfs.tar` is placed in `/config`, end of first build phase
* used build container gets committed as a new builder image which will be used by other builds depending on this image,
this preserves exact build state
* `kubler.sh` then starts a normal docker build that uses `rootfs.tar` to create the final image

Build container names generally start with `*/bob`, when a new build container state is committed the current image
name gets appended. For example `kubler/bob-openssl` refers to the container used to build the `kubler/openssl` image.

## Thanks

[@wking][] for his [gentoo-docker][] repo which served as an excellent starting point

[@jbergstroem][], one of the earliest contributers that helped shape the project probably more then he knows <3

[@azimut][], Mr. ARMv7a :P

[@berney][], Ricer in chief

[@soredake][], for his contributions and feedback

[@mischief][] for contributing the theme of the project name 

[Argbash][] for making my life a bit easier, if you bash script yourself you should definitely check it out!

[LXC]: https://en.wikipedia.org/wiki/LXC
[gentoo-docker]: https://github.com/wking/dockerfile
[bob-core]: https://github.com/edannenberg/kubler/tree/master/lib/bob-core
[s6]: https://skarnet.org/software/s6/
[OpenRC]: https://wiki.gentoo.org/wiki/OpenRC
[Docker]: https://www.docker.com/
[acbuild]: https://github.com/containers/build
[kubler-docker]: https://hub.docker.com/u/kubler/
[nginx-packages]: https://github.com/edannenberg/kubler/blob/master/dock/kubler/images/nginx/PACKAGES.md
[Gentoo]: https://www.gentoo.org/
[binary package]: https://wiki.gentoo.org/wiki/Binary_package_guide
[package.provided]: https://wiki.gentoo.org/wiki//etc/portage/profile/package.provided
[Grafana]: https://grafana.com/
[CoreOS]: https://coreos.com/
[@wking]: https://github.com/wking
[@jbergstroem]: https://github.com/jbergstroem
[@azimut]: https://github.com/azimut
[@berney]: https://github.com/berney
[@soredake]: https://github.com/soredake
[@mischief]: https://github.com/mischief
[Argbash]: https://github.com/matejak/argbash
