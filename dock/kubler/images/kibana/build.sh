#
# build config
#
_packages="www-apps/kibana-bin"
# skip all dependencies of kibana
EMERGE_OPT="--nodeps"

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    update_keywords 'www-apps/kibana-bin' '+~amd64'
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    copy_gcc_libs
}
