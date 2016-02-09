# make.conf doesn't support POSIX parameter expansion, ENV does ;p
# on the downside this needs to be sourced before building anything

if [[ -z "${USE_BUILDER_FLAGS}" ]]; then
    export CFLAGS="${BOB_CFLAGS:--mtune=generic -O2 -pipe}"
    export CXXFLAGS="${BOB_CXXFLAGS:-${CFLAGS}}"

    export CHOST="${BOB_CHOST:-x86_64-pc-linux-gnu}"
else
    export CFLAGS="${BOB_BUILDER_CFLAGS:--mtune=generic -O2 -pipe}"
    export CXXFLAGS="${BOB_BUILDER_CXXFLAGS:-${CFLAGS}}"

    export CHOST="${BOB_BUILDER_CHOST:-x86_64-pc-linux-gnu}"
fi

export MAKEOPTS="${BOB_MAKEOPTS:--j9}"

export FEATURES="${BOB_FEATURES:-parallel-fetch nodoc noinfo noman}"
export EMERGE_DEFAULT_OPTS="${BOB_EMERGE_DEFAULT_OPTS:--b -k}"

export GENTOO_MIRRORS="${BOB_GENTOO_MIRRORS:-ftp://ftp.wh2.tu-dresden.de/pub/mirrors/gentoo ftp://ftp-stud.fht-esslingen.de/pub/Mirrors/gentoo/}"

export DISTDIR="/distfiles"
export PKGDIR="/packages/${CHOST}"
