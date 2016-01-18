#
# build config
#
PACKAGES="sys-apps/s6"
ENTR_VERSION="3.4"

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
    # s6 folders
    mkdir -p $EMERGE_ROOT/etc/service/.s6-svscan $EMERGE_ROOT/service
    # install entr
    wget "http://entrproject.org/code/entr-${ENTR_VERSION}.tar.gz"
    tar xzvf "entr-${ENTR_VERSION}.tar.gz"
    cd eradman* && ./configure && make && make install
    strip /usr/local/bin/entr
    cp /usr/local/bin/entr $EMERGE_ROOT/bin
    rm -rf /eradman*
    log_as_installed "manual install" "entr-${ENTR_VERSION}" "http://entrproject.org/"
}
