#
# build config
#
_packages="sys-libs/musl"
_timezone="${BOB_TIMEZONE:-UTC}"
BOB_SKIP_LIB_CLEANUP=true

configure_bob() {
    # set timezone
    echo $_timezone > /etc/timezone
    # install timezones
    emerge -q1 sys-libs/timezone-data
}

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    # as we broke the normal builder chain, recreate the docs for the busybox image
    init_docs 'kubler/busybox'
    update_use 'sys-apps/busybox' '+static' '+make-symlinks'
    generate_doc_package_installed 'sys-apps/busybox'
    # fake portage install
    provide_package sys-apps/portage
    # set localtime
    mkdir -p "${_EMERGE_ROOT}"/etc
    cp /etc/timezone "${_EMERGE_ROOT}"/etc/
    cp /usr/share/zoneinfo/"${_timezone}" "${_EMERGE_ROOT}"/etc/localtime
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    :
}
