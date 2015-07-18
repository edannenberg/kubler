#
# build config
#
PACKAGES="dev-lang/python dev-python/pip"
#KEEP_HEADERS=true

configure_bob()
{
    # since 20150709 setuptools on build container fails the build for pip package, looks like a bug
    # in the meantime let's reinstall setuptools for python3_4 on the build container to fix the issue
    emerge -C dev-python/setuptools
    echo 'PYTHON_TARGETS="python3_4"' >> /etc/portage/make.conf
    echo 'PYTHON_SINGLE_TARGET="python3_4"' >> /etc/portage/make.conf
    echo 'USE_PYTHON="3.4"' >> /etc/portage/make.conf
    update_use '+sqlite'
    emerge dev-python/setuptools
}

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
    :
}
