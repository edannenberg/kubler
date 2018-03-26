#
# Kubler phase 1 config, pick installed packages and/or customize the build
#

_packages="app-emulation/syslog-stdout net-ftp/pure-ftpd"

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    update_use 'net-ftp/pure-ftpd' '+vchroot'
    # add user/group for virtual accounts
    groupadd -g 2100 ftp-data
    useradd -u 2100 -g ftp-data -d /dev/null -r -s /usr/sbin/nologin ftp-data

    # add sql auth
    #update_use 'net-ftp/pure-ftpd' '+mysql'
    #update_use 'dev-db/mariadb' '-server' '-perl'
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    # s6 setup
    mkdir -p "${_EMERGE_ROOT}"/etc/service/syslog-stdout
    echo -e '#!/bin/sh\nexec /usr/bin/syslog-stdout' > "${_EMERGE_ROOT}"/etc/service/syslog-stdout/run
    chmod +x "${_EMERGE_ROOT}"/etc/service/syslog-stdout/run
    ln -sr "${_EMERGE_ROOT}"/etc/s6_finish_default "${_EMERGE_ROOT}"/etc/service/syslog-stdout/finish
}
