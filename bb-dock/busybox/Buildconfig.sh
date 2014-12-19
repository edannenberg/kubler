#
# build config
#
PACKAGES="sys-apps/busybox"

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    echo "sys-apps/busybox make-symlinks static" >> /etc/portage/package.use/busybox
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    # fake portage install
    emerge -p sys-apps/portage | grep sys-apps/portage | grep -Eow "\[.*\] (.*) to" | awk '{print $(NF-1)}' >> /config/tmp/package.installed
    # log dir, root home dir
    mkdir -p $EMERGE_ROOT/var/log $EMERGE_ROOT/root
    # busybox crond setup
    mkdir -p $EMERGE_ROOT/var/spool/cron/crontabs
    chmod 0600 $EMERGE_ROOT/var/spool/cron/crontabs
}
