#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="www-apps/grafana"

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    update_use 'sys-apps/yarn' '+~amd64'
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    mkdir -p "${_EMERGE_ROOT}"/opt/grafana
    ln -sr "${_EMERGE_ROOT}"/usr/share/grafana/{conf,public} "${_EMERGE_ROOT}"/opt/grafana/
}
