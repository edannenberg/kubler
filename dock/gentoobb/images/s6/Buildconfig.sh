#
# build config
#
PACKAGES="sys-apps/s6"

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    update_keywords 'sys-apps/s6' '+~amd64'
    update_keywords 'dev-lang/execline' '+~amd64'
    update_keywords 'dev-libs/skalibs' '+~amd64'
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    # s6 folders
    mkdir -p $EMERGE_ROOT/etc/service/.s6-svscan $EMERGE_ROOT/service
    # install entr
    wget http://entrproject.org/code/entr-2.9.tar.gz
    tar xzvf entr-2.9.tar.gz
    cd eradman* && ./configure && make && make install
    strip /usr/local/bin/entr
    cp /usr/local/bin/entr $EMERGE_ROOT/bin
    log_as_installed "manual install" "entr-2.9" "http://entrproject.org/"
}
