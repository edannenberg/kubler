Automated build environment that produces slim [Docker][] base images using gentoo and busybox. Heavily based on [wking's gentoo docker][gentoo-docker] repo.
This is still work in progress, creating new base images should be pretty straight forward though.

Why?

* Gentoo is great, shipping a full compiler stack with your containers not so much

What's different?

* Images do not contain portage or compiler chain = much smaller image size
* [s6][] instead of openrc as supervisor (smaller footprint and proper docker SIGTERM handling)
* No syslog daemon in favor of centralized approaches
* Added a few convenience flags to build.sh, use -h to display further details

How much do i save?

* Quite a bit, the nginx image for example clocks in at ~63MB, compared to >1GB for a full gentoo version or ~300MB for a similiar ubuntu version

How does it work?

* build.sh iterates over bb-dock/ 
* generates build order, and collects dependency lists in package.provided file
* mounts each directory into a fresh bb-builder/bob container and executes build-root.sh inside bob
* resulting rootfs.tar is placed in mounted directory
* build.sh then starts a docker build that uses rootfs.tar to create a new image

The catch?

* Obv. you can't add packages via portage in further docker builds based on those images, unless they are built via build.sh

Quickstart:

    $ git clone https://github.com/edannenberg/gentoo-bb.git
    $ cd gentoo-bb
    $ ./build.sh

* If you don't have gpg available (you should!) you can use -s to skip verification of downloaded files 


    $ ./build.sh -s

 
* Check the folders in bb-dock/ for image specific documentation
* bin/ contains some scripts to start/stop a few container chains

Creating new images:

 * All images must be located in bb-dock, folder name = image name
 * Dockerfile.template and Buildconfig.sh are the only required files
 * Buildconfig.sh is used to configure the compiling stage, defining PACKAGES is the only requirement
 * build.sh will pick up your image on the next run

Some usefull options while working on an image:

    $ ./bob-interactive.sh # start an interactive build container, same as run by build.sh to produce the rootfs.tar

    $ ./build.sh -f build myimage # force rebuild of myimage and all dependencies

    $ ./build.sh -F build myimage # same as above, but also rebuild all rootfs.tar files

    $ ./build.sh -n build myimage # ignore dependencies, only build given image. combine with the above

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
