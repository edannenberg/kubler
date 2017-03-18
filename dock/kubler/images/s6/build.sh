#
# build config
#
_packages="sys-apps/s6"
ENTR_VERSION="3.6"

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    update_keywords 'dev-lang/execline' '+~amd64'
    update_keywords 'dev-libs/skalibs' '+~amd64'
    update_keywords 'sys-apps/s6' '+~amd64'
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    # s6 folders
    mkdir -p $_EMERGE_ROOT/etc/service/.s6-svscan $_EMERGE_ROOT/service
    # install entr
    wget "http://entrproject.org/code/entr-${ENTR_VERSION}.tar.gz"
    tar xzvf "entr-${ENTR_VERSION}.tar.gz"
    cd eradman* && ./configure && make && make install
    strip /usr/local/bin/entr
    cp /usr/local/bin/entr $_EMERGE_ROOT/bin
    rm -rf /eradman*
    log_as_installed "manual install" "entr-${ENTR_VERSION}" "http://entrproject.org/"
}
