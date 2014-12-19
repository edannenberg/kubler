#
# build config
#
PACKAGES="net-misc/curl dev-db/mariadb"

#
# this method runs in the bb builder container just before building the rootfs
#
configure_rootfs_build()
{
    # reinstall curl, need at build time
    sed -i /^net-misc\\/curl/d /etc/portage/profile/package.provided
}

#
# this method runs in the bb builder container just before packing the rootfs
#
finish_rootfs_build()
{
    copy_gcc_libs
    mkdir -p $EMERGE_ROOT/var/run/mysql $EMERGE_ROOT/var/run/mysqld
    chown mysql:mysql $EMERGE_ROOT/var/run/mysql $EMERGE_ROOT/var/run/mysqld
    # remove curl again
    emerge -C net-misc/curl
    # reflect uninstall in docs
    sed -i /^net-misc\\/curl/d "${DOC_PACKAGE_INSTALLED}"
}
