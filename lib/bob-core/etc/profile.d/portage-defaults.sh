#!/usr/bin/env bash

# make.conf doesn't support POSIX parameter expansion, ENV does ;p
# on the downside this needs to be sourced before building anything

if [[ -z "${USE_BUILDER_FLAGS}" ]]; then
    export CFLAGS="${DEF_CFLAGS:--mtune=generic -O2 -pipe}"
    export CXXFLAGS="${DEF_CXXFLAGS:-${CFLAGS}}"

    export CHOST="${DEF_CHOST:-x86_64-pc-linux-gnu}"
else
    # when using crossdev this configures the "host" compiler
    export CFLAGS="${DEF_BUILDER_CFLAGS:--mtune=generic -O2 -pipe}"
    export CXXFLAGS="${DEF_BUILDER_CXXFLAGS:-${CFLAGS}}"

    export CHOST="${DEF_BUILDER_CHOST:-x86_64-pc-linux-gnu}"
fi

export MAKEOPTS="${BOB_MAKEOPTS:--j9}"

export FEATURES="${BOB_FEATURES:-parallel-fetch nodoc noinfo noman}"
export EMERGE_DEFAULT_OPTS="${BOB_EMERGE_DEFAULT_OPTS:--b -k}"

export GENTOO_MIRRORS="${BOB_GENTOO_MIRRORS:-ftp://ftp.wh2.tu-dresden.de/pub/mirrors/gentoo ftp://ftp-stud.fht-esslingen.de/pub/Mirrors/gentoo/}"

export DISTDIR="/distfiles"
