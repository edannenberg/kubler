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
    echo 'PYTHON_TARGETS="python3_3"' >> /etc/portage/make.conf
    echo 'PYTHON_SINGLE_TARGET="python3_3"' >> /etc/portage/make.conf
    echo 'USE_PYTHON="3.3"' >> /etc/portage/make.conf
    echo 'USE="${USE} sqlite"' >> /etc/portage/make.conf
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    :
}
