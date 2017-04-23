#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="sys-kernel/linux-headers sys-devel/make sys-devel/binutils sys-devel/gcc"
_keep_headers=true
_keep_static_libs=true
# include glibc headers and static files from glibc image
_headers_from=kubler/glibc
_static_libs_from=kubler/glibc

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    unprovide_package sys-kernel/linux-headers
    # ensure symbolic lib/ link won't get replaced with a dir from this image
    if [[ "${_LIB}" == "lib64" ]]; then
        mkdir -p "${_EMERGE_ROOT}"/lib64
        ln -sr "${_EMERGE_ROOT}"/lib64 "${_EMERGE_ROOT}"/lib
    fi
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    :
}
