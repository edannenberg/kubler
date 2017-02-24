#
# build config
#
_packages="sys-apps/busybox"

#
# this method runs in the bb builder container just before starting the build of the rootfs
# 
configure_rootfs_build()
{
    update_use 'sys-apps/busybox' '+make-symlinks +static'
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    # log dir, root home dir
    mkdir -p "${_EMERGE_ROOT}"/var/log "${_EMERGE_ROOT}"/root
    # busybox crond setup
    mkdir -p "${_EMERGE_ROOT}"/var/spool/cron/crontabs
    chmod 0600 "${_EMERGE_ROOT}"/var/spool/cron/crontabs
    # kick openrc init stuff
    rm -rf "${_EMERGE_ROOT}"/etc/init.d/
    # eselect now uses a hard coded readlink path :/
    ln -sr "${_EMERGE_ROOT}"/bin/readlink "${_EMERGE_ROOT}"/usr/bin/readlink

}
