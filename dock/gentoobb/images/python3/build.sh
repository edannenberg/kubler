#
# build config
#
PACKAGES="dev-lang/python dev-python/pip"
#KEEP_HEADERS=true

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    echo 'PYTHON_TARGETS="python3_4"' >> /etc/portage/make.conf
    echo 'PYTHON_SINGLE_TARGET="python3_4"' >> /etc/portage/make.conf
    echo 'USE_PYTHON="3.4"' >> /etc/portage/make.conf
    update_use '+sqlite'
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    :
}
