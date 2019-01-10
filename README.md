Kubler
======

### A container image meta builder

> [Wikipedia](https://en.wikipedia.org/wiki/Cooper_%28profession%29#.22Cooper.22_as_a_name) said:
In much the same way as the trade or vocation of smithing produced the common English surname Smith
and the German name Schmidt, the cooper trade is also the origin of German names like Kübler.
>
> There is still demand for high-quality ~~wooden barrels~~ containers, and it is thought that the
highest-quality ~~barrels~~ containers are those hand-made by professional ~~coopers~~ kublers.

## Why Should You Care?

Perhaps:

1. You love Docker but are annoyed by some of the restrictions of it's `build` command that keep
   getting into your way. Wouldn't it be nice if you could `build` your images with all `docker run`
   args, like `-v`, at your disposal?
2. You are a SysAdmin or DevOps engineer who seeks complete governance for the contents of their
   Docker images, with full control of the update cycle and the ability to track software version
   changes across the board from a centralized vcs repository.
3. You need to manage a **lot** of Docker base/service images in a sane way and want peace of mind
   with automated post-build tests.
4. You are a Gentoo user that wants to build slim Gentoo based images without having to wrestle
   with CrossDev.
5. You are looking for an interactive OS host agnostic Gentoo playground or a portable ebuild
   development environment.
6. You want to create custom root file systems, possibly for different cpu architectures, in a safe
   and repeatable manner.

## Cool. So What Exactly Is A Container Image Meta Builder?

While Kubler was designed primarily for building and managing container images it doesn't
particularly care about the way those images are built. At the core it's just a glorified directory
crawler, with a simple dependency mechanism, that fires a command on a selected image or namespace
dependency graph.

The actual build logic is abstracted away into pluggable engines that may orchestrate other tools,
like Docker, to create the final image, or whatever the selected namespace's configured engine
produces.

Kubler is extendable, users may provide their own commands and/or build engines in a maintainable
way. As both are just plain old Bash scripts this is usually a simple* and straight forward process
with almost no limitations.

`{ font-size: 2px; }` * Additional rates of blood, sweat and tears may apply when implementing a new engine

## Requirements

#### Kubler

* Bash version 4.2+, using 4.4+ is highly recommended due to bugs in previous versions.

Optional:

* GPG for download verification

#### Docker Build Engine

* Working Docker setup
* GIT
* jq to parse Docker json output

## Installation

#### On Gentoo

An ebuild can be found at https://github.com/edannenberg/kubler-overlay/

Add the overlay and install as usual:

    emerge -av kubler

#### Manual Installation

Kubler has been tested on Gentoo, CoreOS and macOS. It should run on all Linux distributions.

1. Clone the repo or download/extract the release archive to a location of your choice, i.e.

    $ cd ~/tools/
    $ curl -L https://github.com/edannenberg/kubler/archive/master.tar.gz | tar xz

2. Add `kubler.sh` to your path

If you are unsure add the following at the end of your `~/.bashrc` file, don't forget to adjust the
path for each line accordingly:

    export PATH="${PATH}:/path/to/kubler/bin"
    # optional but highly recommended, adds bash completion support for all kubler commands
    source /path/to/kubler/lib/kubler-completion.bash

Note: You will need to open a new shell for this to take effect, if this fails on a Linux SystemD
host re-logging might be required instead.

#### Uninstall

1. Remove any build artifacts and Docker images created by Kubler:

    $ kubler clean -N

2. Delete the two entries from `~/.bashrc` you possibly added during manual installation

3. Delete any namespace dirs and configured `KUBLER_DATA_DIR` (default is `~/.kubler/`) you had in
   use, this may require su permissions.

## Quick Start

#### The Basics

To get a quick overview/reminder of available commands/options run:

    $ kubler --help

To view details for specific command:

    $ kubler build -h

Almost all of Kubler's commands will need to be run from a `--working-dir`, if the option is
omitted the current working dir of the executing shell is used. It functions much like Git in that
regard, executing any Kubler command from a sub directory of a valid working dir will also work as
expected.

A `--working-dir` is considered valid if it has a `kubler.conf` file and either an `images/` dir or
one ore more namespace dirs, which are just a collection of images.

#### Setup A New Namespace

First switch to a directory where you would like to store your Kubler managed images or namespaces:

    $ cd ~/workspace

Then use the `new` command to take care of the boiler plate for you, choose `single` as namespace
type when asked:

    $ kubler new namespace mytest
    $ cd mytest

### Hello Image

To create a new image in the current working dir:

    $ kubler new image mytest/figlet

#TODO: finish docs

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
    $ ./kubler.sh build -C mynamespace

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

## Other Resources

* An excellent blog post, written by [@berney][], can be found at https://www.elttam.com.au/blog/kubler/

## Discord Community

For questions or chatting with other users you may join our Discord server at:

https://discord.gg/rH9R7bc

You just need a username, email verification with Discord is not required.

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
