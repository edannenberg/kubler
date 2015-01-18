#
# build config
#
PACKAGES=""

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    :
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    log_as_installed "manual install" "kibana-3.1.2" "http://www.elasticsearch.org/overview/kibana/"
}
