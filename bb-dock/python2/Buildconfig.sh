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
    echo 'PYTHON_TARGETS="python2_7"' >> /etc/portage/make.conf
    echo 'PYTHON_SINGLE_TARGET="python2_7"' >> /etc/portage/make.conf
    echo 'USE_PYTHON="2.7"' >> /etc/portage/make.conf
    echo '>=dev-lang/python-3.2.5-r6' >> /etc/portage/package.mask/python
    echo 'USE="${USE} sqlite"' >> /etc/portage/make.conf
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    :
}
