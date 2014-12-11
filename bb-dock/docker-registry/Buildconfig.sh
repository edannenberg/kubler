#
# build config
#
PACKAGES="dev-python/blinker dev-python/boto dev-python/backports-lzma dev-python/flask dev-python/flask-cors dev-python/gevent dev-python/pyyaml dev-python/redis-py dev-python/requests dev-python/rsa dev-python/simplejson dev-python/sqlalchemy"
#KEEP_HEADERS=true

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    # only use python 2.7
    echo 'PYTHON_TARGETS="python2_7"' >> /etc/portage/make.conf
    echo 'PYTHON_SINGLE_TARGET="python2_7"' >> /etc/portage/make.conf
    echo 'USE_PYTHON="2.7"' >> /etc/portage/make.conf
    echo '>=dev-lang/python-3.2.5-r6' >> /etc/portage/package.mask/python
    # docker registry dependencies
    echo 'USE="${USE} sqlite"' >> /etc/portage/make.conf
    echo "dev-python/backports ~amd64" > /etc/portage/package.keywords/docker-registry
    echo "dev-python/backports-lzma ~amd64" >> /etc/portage/package.keywords/docker-registry
    echo "dev-python/flask-cors ~amd64" >> /etc/portage/package.keywords/docker-registry
    # needed a build time, so we remove them from package.provided for reinstall
    sed -i /^dev-lang\\/python/d /etc/portage/profile/package.provided
    sed -i /^dev-python\\/setuptools/d /etc/portage/profile/package.provided
    sed -i /^net-misc\\/curl/d /etc/portage/profile/package.provided
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    # prepare docker-registry, final setup in Dockerfile
    wget http://github.com/docker/docker-registry/archive/0.9.0.tar.gz
    tar xzvf 0.9.0.tar.gz
    mv docker-registry-0.9.0 $EMERGE_ROOT/docker-registry
    cp --no-clobber $EMERGE_ROOT/docker-registry/config/config_sample.yml $EMERGE_ROOT/docker-registry/config/config.yml
    # Disable strict dependencies (see dotcloud/docker-registry#466)
    sed -i 's/\(install_requires=\)/#\1/' $EMERGE_ROOT/docker-registry/setup.py \
        $EMERGE_ROOT/docker-registry/depends/docker-registry-core/setup.py
    log_as_installed "pip install" "gunicorn" "http://gunicorn.org/"
    log_as_installed "manual install" "docker-registry-0.9.0" "http://github.com/docker/docker-registry/"
    # remove packages that were only needed at build time
    emerge -C dev-lang/python dev-lang/python-exec dev-python/setuptools
    # reflect uninstall in docs
    sed -i /^dev-lang\\/python/d "${DOC_PACKAGE_INSTALLED}"
    sed -i /^dev-python\\/setuptools/d "${DOC_PACKAGE_INSTALLED}"
}
