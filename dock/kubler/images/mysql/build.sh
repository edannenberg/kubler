#
# build config
#
_packages="app-arch/pbzip2 net-misc/curl dev-db/mysql"
AUTOSQLBACKUP_VERSION="3.0_rc6"

#
# this method runs in the bb builder container just before building the rootfs
#
configure_rootfs_build()
{
    # sadly perl is required for db init scripts
    #update_use 'dev-db/mysql' '-perl'
    # reinstall curl, need at build time
    unprovide_package net-misc/curl
}

#
# this method runs in the bb builder container just before packing the rootfs
#
finish_rootfs_build()
{
    copy_gcc_libs
    mkdir -p $_EMERGE_ROOT/var/run/mysql $_EMERGE_ROOT/var/run/mysqld
    chown mysql:mysql $_EMERGE_ROOT/var/run/mysql $_EMERGE_ROOT/var/run/mysqld
    # remove curl again
    uninstall_package net-misc/curl
    # install automysqlbackup
    AMB_FILE=automysqlbackup-v${AUTOSQLBACKUP_VERSION}.tar.gz
    mkdir /root/automysqlbackup
    cd /root/automysqlbackup
    wget https://sourceforge.net/projects/automysqlbackup/files/AutoMySQLBackup/AutoMySQLBackup%20VER%203.0/${AMB_FILE}
    tar xzvf ${AMB_FILE}
    mkdir ${_EMERGE_ROOT}/etc/automysqlbackup
    cp automysqlbackup ${_EMERGE_ROOT}/usr/bin/
    cp automysqlbackup.conf ${_EMERGE_ROOT}/etc/automysqlbackup/
    log_as_installed "manual install" "automysqlbackup-${AUTOSQLBACKUP_VERSION}" "https://sourceforge.net/projects/automysqlbackup/"
}
