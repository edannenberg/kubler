#
# build config
#
_packages="sys-kernel/linux-headers sys-devel/make sys-devel/binutils sys-devel/gcc"
_keep_headers=true
_keep_static_libs=true
# include glibc headers and static files from busybox image
_headers_from=kubler/glibc
_static_libs_from=kubler/glibc

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    unprovide_package sys-kernel/linux-headers
    # ensure symbolic lib/ link won't get replaced with a dir from this image
    mkdir -p "${_EMERGE_ROOT}/lib64"
    ln -sr "${_EMERGE_ROOT}"/lib64 "${_EMERGE_ROOT}"/lib
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    :
}
