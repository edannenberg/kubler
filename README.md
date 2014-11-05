gentoobb
========

Automated build environment that produces slim [Docker][] base images using gentoo and busybox. Heavily based on [wking's gentoo docker][gentoo-docker] repo.
Still work in progress.

## Why?

* Gentoo is great, shipping a full compiler stack with your containers not so much

## What's different?

* Images do not contain portage or compiler chain = much smaller image size
* [s6][] instead of openrc as supervisor (smaller footprint and proper docker SIGTERM handling)
* No syslog daemon in favor of centralized approaches
* Added a few convenience flags to build.sh, use -h to display further details

## How much do I save?

* Quite a bit, the nginx image for example clocks in at ~63MB, compared to >1GB for a full gentoo version or ~300MB for a similiar ubuntu version

## The catch?

* You can't install packages via portage in further docker builds based on those images, unless they are built via build.sh

## Quickstart

    $ git clone https://github.com/edannenberg/gentoo-bb.git
    $ cd gentoo-bb
    $ ./build.sh update
    $ ./build.sh

* If you don't have gpg available (you should!) you can use -s to skip verification of downloaded files
* Oracle downloads may or may not work, you can always download them manually to tmp/distfiles
* Check the folders in bb-dock/ for image specific documentation
* bin/ contains a few scripts to start/stop container chains

## How does it work?

* build.sh iterates over bb-dock/ 
* generates build order
* mounts each directory into a fresh bb-builder/bob container and executes build-root.sh inside bob
* each build produces a package.installed file that is used by depending images as package.provided
* resulting rootfs.tar is placed in mounted directory
* build.sh then starts a docker build that uses rootfs.tar to create the final image

## Adding images

 * All images must be located in bb-dock/, folder name = image name
 * Dockerfile.template and Buildconfig.sh are the only required files
 * build.sh will pick up your image on the next run

Some useful options for build.sh while working on an image:

Start an interactive build container, same as used to create the rootfs.tar:

    $ ./bin/bob-interactive.sh myimage

Force rebuild of myimage and all images it depends on:

    $ ./build.sh -f build myimage

Same as above, but also rebuild all rootfs.tar files:

    $ ./build.sh -F build myimage

Only rebuild myimage, ignore images it depends on:

    $ ./build.sh -nF build myimage

Parts from the original [gentoo docker][gentoo-docker] docs that still apply:

=========

Dockerfiles are sorted into directories with names matching the
suggested repository.  To avoid duplicating ephemeral data (namespace,
timestamp tag, …), they appear in the `Dockerfile.template` as markers
(`${NAMESPACE}`, `${TAG}`, …).  The `build.sh` script replaces the
markers with values while generating a `Dockerfile` from each
`Dockerfile.template` (using [envsubst][]), and then builds each tag
with:

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
[Gentoo]: http://www.gentoo.org/
[envsubst]: http://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html
[parameter-expansion]: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02
