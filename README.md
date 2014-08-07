Automated build environment that produces slim [Docker][] base images using gentoo and busybox. Heavily based on [wking's gentoo docker][gentoo-docker] repo.
It's pretty much in a prototype state right now, a simple web stack is all you get at the moment. Creating new base images should be pretty straight forward though.

Why?

* Gentoo is great, shipping a full compiler stack with your containers not so much

What's different?

* Images do not contain emerge or compiler chain = much smaller image size
* Uses [s6][] instead of openrc as supervisor (smaller footprint)
* Added a few convenience flags to build.sh, use -h to display further details

How much do i save?

* Quite a bit, the nginx-php image clocks in at ~108MB, compared to >1GB for a full gentoo version or ~350MB for a similiar ubuntu version

How does it work?

* build.sh iterates over bb-dock/ 
* mounts each directory into a fresh bb-builder/bob container and executes build-root.sh inside bob
* resulting rootfs.tar is placed in mounted directory
* build.sh then starts a docker build that uses rootfs.tar to create a new image from scratch

The catch?

* Obv. you can't add packages in further docker builds based on those images
* Running many different gentoo-bb images on the same host will diminish the size gains because images are not based on a common base image

Parts from the original gentoo-docker docs that still apply:

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
