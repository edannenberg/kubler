gentoo-bb
=========

Automated build environment that produces slim [Docker][] base images using [Gentoo][] and [BusyBox][]. Heavily based on [wking's gentoo docker][gentoo-docker] repo.
Images are pushed to [docker.io][gentoo-bb-docker]. Due to the 2 phase build used by gentoo-bb automated docker.io builds are not possible for now.

## Why?

* Docker containers should only contain the bare minimum to run
* Gentoo shines when it comes to control and optimization, shipping a full compiler stack with your containers clashes with the previous point though

## What's different?

* Images do not contain [Portage][] or compiler chain = much smaller image size
* [s6][] instead of openrc as default supervisor (small footprint (<1mb) and proper docker SIGTERM handling)
* No syslog daemon in favor of centralized approaches
* Automated image documentation ([example][nginx-packages])

## How much do I save?

* Quite a bit, the nginx image, for example, clocks in at ~26MB, compared to >1GB for a full gentoo version or ~300MB for a similiar ubuntu version

## The catch?

* You can't install packages via [Portage][] in further docker builds based on those images, unless they are built via `build.sh`

## Quick Start

    $ git clone https://github.com/edannenberg/gentoo-bb.git
    $ cd gentoo-bb
    $ ./build.sh

* If you don't have gpg available you can use `-s` to skip verification of downloaded files
* Check the folders in `bb-dock/` for image specific documentation
* `bin/` contains a few scripts to start/stop container chains

## How does it work?

* `build.sh` iterates over `bb-dock/`
* generates build order
* mounts each directory into a fresh `bb-builder/bob` container and executes `build-root.sh` inside bob
* `Buildconfig.sh` from the mounted directory is sourced by `build-root.sh`
* `package.installed` file is generated which is used by depending images as `package.provided`
* packages defined in `Buildconfig.sh` are installed at a custom empty root directory inside bob
* resulting `rootfs.tar` is placed in mounted directory
* `build.sh` then starts a docker build that uses `rootfs.tar` to create the final image

## Adding images

 * All images must be located in `bb-dock/`, folder name = image name
 * `Dockerfile.template` and `Buildconfig.sh` are the only required files
 * `build.sh` will pick up your image on the next run

Some useful options for `build.sh` while working on an image:

Start an interactive build container, same as used to create the rootfs.tar:

    $ ./bin/bob-interactive.sh myimage

Force rebuild of myimage and all images it depends on:

    $ ./build.sh -f build myimage

Same as above, but also rebuild all rootfs.tar files:

    $ ./build.sh -F build myimage

Only rebuild myimage, ignore images it depends on:

    $ ./build.sh -nF build myimage

## Updating to a newer gentoo stage3 release

First check for a new release by running:

    $ ./build.sh update

If a new release was found simply rebuild the stack by running:

    $ ./build.sh -F

* Things might break, Oracle downloads, for example, may not work. You can always download them manually to `tmp/distfiles`.

Parts from the original [gentoo docker][gentoo-docker] docs that still apply:

=========

Dockerfiles are sorted into directories with names matching the
suggested repository.  To avoid duplicating ephemeral data (namespace,
timestamp tag, …), they appear in the `Dockerfile.template` as markers
(`${NAMESPACE}`, `${TAG}`, …).  The `build.sh` script replaces the
markers with values while generating a `Dockerfile` from each
`Dockerfile.template` (using sed), and then builds each tag with:

    $ docker build -t $NAMESPACE/$REPO:$TAG $REPO

for example:

    $ docker build -t wking/gentoo-en-us:20131205 gentoo-en-us

Run:

    $ ./build.sh

to seed from the Gentoo mirrors and build all images.  There are a
number of variables in the `build.sh` script that configure the build
(`AUTHOR`, `NAMESPACE`, …).  We use [POSIX parameter
expansion][parameter-expansion] to make it easy to override variables
as you see fit.

    $ NAMESPACE=jdoe DATE=20131210 ./build.sh

[gentoo-docker]: https://github.com/wking/dockerfile
[s6]: http://skarnet.org/software/s6/
[Docker]: http://www.docker.io/
[Dockerfiles]: http://www.docker.io/learn/dockerfile/
[gentoo-bb-docker]: https://hub.docker.com/u/gentoobb/
[nginx-packages]: https://github.com/edannenberg/gentoo-bb/blob/master/bb-dock/nginx/PACKAGES.md
[Gentoo]: http://www.gentoo.org/
[BusyBox]: http://www.busybox.net/
[Portage]: http://www.gentoo.org//doc/en/handbook/handbook-x86.xml?part=3
[parameter-expansion]: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02
