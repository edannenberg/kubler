> [Wikipedia](https://en.wikipedia.org/wiki/Cooper_%28profession%29#.22Cooper.22_as_a_name) said:
In much the same way as the trade or vocation of smithing produced the common English surname Smith
and the German name Schmidt, the cooper trade is also the origin of German names like Kübler.
>
> There is still demand for high-quality ~~wooden barrels~~ containers, and it is thought that the
highest-quality ~~barrels~~ containers are those hand-made by professional ~~coopers~~ kublers.

Kubler
======

A generic, extendable build orchestrator, in Bash. The default batteries focus on creating and maintaining 
Docker base images.

## Why Should You Care?

Perhaps:

1. You love Docker but are annoyed by some of the restrictions of it's `build` command that keep
   getting into your way. Wouldn't it be nice if you could `docker build` your images with all
   `docker run` args, like `-v`, at your disposal? Or if your `Dockerfile` was fully parameterizable?
2. You are a SysAdmin or DevOps engineer who seeks complete governance over the contents of their
   container images, with full control of the update cycle and the ability to track *all* software
   version changes from a centralized vcs repository.
3. You need to manage a **lot** of Docker base/service images in a sane way and want peace of mind
   with automated post-build tests.
4. You are a Gentoo user and want to build slim Docker images with a toolset you are familiar with. Not having
   to wrestle with CrossDev would also be a plus.
5. You are looking for an interactive OS host agnostic Gentoo playground or portable ebuild
   development environment.
6. You want to create custom root file systems, possibly for different cpu architectures
   and/or libc implementations (i.e. musl, uclibc, etc) in an isolated and repeatable manner.

## Requirements

#### Kubler

* Bash version 4.2+, using 4.4+ is highly recommended due to bugs in previous versions.

Optional:

* GPG for download verification

#### Docker Build Engine

* Working Docker setup
* Git
* jq to parse Docker json output

## Installation

#### On Gentoo

An ebuild can be found at https://github.com/edannenberg/kubler-overlay/

Add the overlay (see link for instructions) and install as usual:

    emerge -av kubler

#### Manual Installation

Kubler has been tested on Gentoo, CoreOS and macOS. It should run on all Linux distributions.

1. Clone the repo or download/extract the release archive to a location of your choice, i.e.

```
    $ cd ~/tools/
    $ curl -L https://github.com/edannenberg/kubler/archive/master.tar.gz | tar xz
```

2. Optional, add `kubler.sh` to your path

The recommended way is to add the following at the end of your `~/.bashrc` file, don't forget to adjust the
Kubler path for each line accordingly:

    export PATH="${PATH}:/path/to/kubler/bin"
    # optional but highly recommended, adds bash completion support for all kubler commands
    source /path/to/kubler/lib/kubler-completion.bash

Note: You will need to open a new shell for this to take effect, if this fails on a Linux SystemD
host re-logging might be required instead.

#### Initial Configuration

Kubler doesn't require any further configuration but you may want to review the main config file
located at `/etc/kubler.conf`. If the file doesn't exist the `kubler.conf` file in Kubler's root folder is
used as a fallback.

All of Kubler's runtime data, like user config overrides, downloads or custom scripts, are kept at a path defined
via `KUBLER_DATA_DIR`. This defaults to `~/.kubler/`, which is suitable if user accounts have Docker access on the host.
If you plan to use Docker/Kubler only with `sudo`, like on a server, you may want to use `/var/lib/kubler`, or some other location, as data dir instead.

Managing your `KUBLER_DATA_DIR` with a VCS tool like Git is supported, a proper `.gitignore` is added on initialization.

#### Uninstall

1. Remove any build artifacts and Docker images created by Kubler:

```
    $ kubler clean -N
```

2. Remove Kubler itself:

    * On Gentoo and ebuild install: `emerge -C kubler` then remove the kubler overlay
    * Manual install: reverse the steps you did during manual installation

3. Delete any namespace dirs and configured `KUBLER_DATA_DIR` (default is `~/.kubler/`) you had in
   use, this may require su permissions.

## Tour De Kubler

### The Basics

To get a quick overview of available commands/options:

    $ kubler --help

Or to view details for a specific command:

    $ kubler build -h

Per default almost all of Kubler's commands will need to be run from a `--working-dir`, if the option is
omitted the current working dir of the executing shell is used. It behaves much like Git in that
regard, executing any Kubler command from a sub directory of a valid working dir will also work as
expected.

A `--working-dir` is considered valid if it has a `kubler.conf` file and either an `images/` dir, or
one ore more namespace dirs, which are just a collection of images.

As Kubler currently only ships with a Docker build engine the rest of this tour will focus on building Docker images,
it's worth noting that the build process may be completely different, i.e. it may not involve Gentoo or Docker at all,
for other build engines.

If you are not familiar with Gentoo some of it's terms you will encounter may be confusing, a short 101 glossary:

| | |
|-|-|
| stage3          | A tar ball provided by Gentoo which on extraction provides an almost-complete root file system for a Gentoo installation |
| Portage         | Gentoo's default package manager, this is where all the magic happens |
| emerge          | Portage's main executable |
| ebuild          | text file which identifies a specific software package and how Portage should handle it |
| Portage Tree    | Categorized collection of ebuilds, Gentoo ships with ~20k ebuilds |
| Portage Overlay | Additional ebuild repository maintained by the community/yourself |

### Every Image needs A Home - Working Dirs And Namespaces

To accommodate different use cases there are three types of working dirs:

| | |
|-|-|
| multi  | The working dir is a collection of one or more namespace dirs |
| single | The working dir doubles as namespace dir, you can't create a new namespace in it, but you save a directory level |
| local  | Same as multi but `--working-dir` is equal to `KUBLER_DATA_DIR` |

First switch to a directory where you would like to store your Kubler managed images or namespaces:

    $ cd ~/projects

Then use the `new` command to take care of the boiler plate for you:

```
    $ kubler new namespace mytest
    $ cd mytest/
```

Although not strictly required it's recommended to install Kubler's example images by running:

    $ kubler update

### Hello Image

Let's start with a simple task and dockerize [Figlet][], a nifty tool that produces ascii fonts. First create a new
image stub by running:

    $ kubler new image mytest/figlet

When asked for the image parent, enter `kubler/bash` and `bt` when asked for tests:

```
»»» Extend an existing Kubler managed image? Fully qualified image id (i.e. kubler/busybox) or scratch
»[?]» Parent Image (scratch): kubler/bash
»»»
»»» Add test template(s)? Possible choices:
»»»   hc  - Add a stub for Docker's HEALTH-CHECK, recommended for images that run daemons
»»»   bt  - Add a stub for a custom build-test.sh script, a good choice if HEALTH-CHECK is not suitable
»»»   yes - Add stubs for both test types
»»»   no  - Fck it, we'll do it live!
»[?]» Tests (hc): bt
»»»
»[✔]» Successfully created new image at projects/mytest/images/figlet
```

A handy feature when working on a Kubler managed image is the `--interactive` build arg. As the name suggests it
allows us to poke around in a running build container and plan/debug the image build. Let's give it a try:

    $ kubler build mytest/figlet -i

This will also build any missing parent images/builders, so the first run may take quite a bit of time. Don't
worry, once your local binary package cache and build containers are seeded future runs will be much faster.
When everything is ready you are dropped into a new shell:

```
»[✔]»[kubler/bash]» done.
»»»»»[mytest/figlet]» using: docker / builder: kubler/bob-bash
kubler-bob-bash / #
```

To search Portage's package db you may use `eix`, or whatever your preferred method is:

```
kubler-bob-bash / # eix figlet
* app-misc/figlet
     Available versions:  2.2.5 ~2.2.5-r1
     Homepage:            http://www.figlet.org/
     Description:         program for making large letters out of ordinary text

* dev-php/PEAR-Text_Figlet
```

As with most package managers, software in Portage is grouped by categories. The category and package name combined
form a unique package atom, in our case we want to install `app-misc/figlet`.

Now manifest the new found knowledge by editing the image's build script located at `mytest/images/figlet/build.sh`. Add the package atom to the
`_packages` variable:

```
_packages="app-misc/figlet"
```

Hit save and switch back to the interactive build container. As the image folder is mounted at `/config` in the build container we
can do a test run of the build:

```
kubler-bob-bash / # kubler-build-root
```

Once this finishes exit the interactive builder by hitting `crtl+d` or typing `exit`. Then build the actual image:

    $ kubler build mytest/figlet -nF

The args are short hand for `--no-deps` and `--force-full-image-build`, if you pass only `-F` parent images
are also rebuild, which can be handy but it's just a waste of time in this case.

```
    »[✘]»[mytest/figlet]» fatal: build-test.sh for image mytest/figlet:20190228 failed with exit signal: 1
```

Ooops, looks like we forgot the image test. Let's fix that by editing the mentioned `build-test.sh` file:

```
    #!/usr/bin/env sh
    set -eo pipefail

    figlet -v | grep -A 2 'FIGlet Copyright' || exit 1
```

Rebuild the image again but this time only pass `-f` instead of `-F`, this will also force a rebuild but skips
the first build phase:

```
$ kubler build mytest/figlet -nf
»[✔]»[mytest/figlet]» done.
$ docker run -it --rm mytest/figlet figlet foooo
```

---

## TBC

---

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

    $ kubler update

If a new stage3 release was found simply rebuild the stack by running:

    $ kubler clean
    $ kubler build -C mynamespace

* Minor things might (read will) break, Oracle download urls, for example, may become outdated.

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

[LXC]: https://en.wikipedia.org/wiki/LXC
[gentoo-docker]: https://github.com/wking/dockerfile
[bob-core]: https://github.com/edannenberg/kubler/tree/master/engine/docker/bob-core
[Figlet]: http://www.figlet.org/
[s6]: https://skarnet.org/software/s6/
[OpenRC]: https://wiki.gentoo.org/wiki/OpenRC
[Docker]: https://www.docker.com/
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
