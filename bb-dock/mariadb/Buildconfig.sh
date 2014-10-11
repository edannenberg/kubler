#
# build config
#
PACKAGES="dev-db/mariadb"

#
# this method runs in the bb builder container just before building the rootfs
# 
configure_rootfs_build()
{
    :
}

#
# this method runs in the bb builder container just before packing the rootfs
# 
finish_rootfs_build()
{
    copy_gcc_libs
    mkdir -p $EMERGE_ROOT/var/run/mysql $EMERGE_ROOT/var/run/mysqld
    chown mysql:mysql $EMERGE_ROOT/var/run/mysql $EMERGE_ROOT/var/run/mysqld
}
