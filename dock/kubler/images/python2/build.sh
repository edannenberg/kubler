#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="dev-lang/python dev-python/pip"
#_keep_headers=true

configure_bob()
{
    # switch to python2_7
    eselect python set 2
    emerge dev-python/pip
}

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    echo 'PYTHON_TARGETS="python2_7"' >> /etc/portage/make.conf
    echo 'PYTHON_SINGLE_TARGET="python2_7"' >> /etc/portage/make.conf
    echo 'USE_PYTHON="2.7"' >> /etc/portage/make.conf
    mask_package '>=dev-lang/python-3.2.5-r6'
    update_use '+sqlite'

    # add user/group for unprivileged container usage
    groupadd -g 404 python
    useradd -u 4004 -g python -d /home/python python
    mkdir -p "${_EMERGE_ROOT}"/home/python
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    :
}
