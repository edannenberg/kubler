A build container for cross-compiling against [musl][], a modern [glibc][] alternative. Based on [cross-dev][].

Usage:

1. Define as default build-container in `build.conf` or override in any `Dockerfile.template`:

    #BUILD_FROM gentoobb/bob-musl
    FROM whatever
    ...

The `#BUILD_FROM` line is parsed by the build script and overrides the build container that is used in the `first build phase`. For details on the build process check the [how-does-it-work][] section.

2. In `Buildconfig.sh` set the following global ENV:

    EMERGE_BIN="emerge-x86_64-pc-linux-musl"

Any packages defined in `PACKAGES` are now installed using the cross-dev emerge wrapper with the musl profile.
Please keep in mind that not all Gentoo ebuilds will work with musl, check the official [musl-overlay][] for supported packages.

3. Create your base image as usual.

[musl]: http://www.musl-libc.org/
[musl-overlay]: https://github.com/gentoo-mirror/musl
[glibc]: https://www.gnu.org/software/libc/
[cross-dev]: https://packages.gentoo.org/packages/sys-devel/crossdev
[how-does-it-work]: https://github.com/edannenberg/gentoo-bb#how-does-it-work
