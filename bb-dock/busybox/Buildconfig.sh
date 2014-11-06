#
# build config
#
PACKAGES="sys-apps/busybox"
KEEP_HEADERS=true

#
# this method runs in the bb builder container just before starting the build of the rootfs
# 
configure_rootfs_build()
{
    # -static to enable dns lookups
    echo "sys-apps/busybox -static" > /etc/portage/package.use/busybox
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    # fake portage install
    emerge -p sys-apps/portage | grep sys-apps/portage | grep -Eow "\[.*\] (.*) to" | awk '{print $(NF-1)}' >> /config/tmp/package.installed
    # log dir
    mkdir -p $EMERGE_ROOT/var/log
    # install entr
    wget http://entrproject.org/code/entr-2.9.tar.gz
    tar xzvf entr-2.9.tar.gz
    cd eradman* && ./configure && make && make install
    cp /usr/local/bin/entr $EMERGE_ROOT/bin
    # busybox crond setup
    mkdir -p $EMERGE_ROOT/var/spool/cron/crontabs
    chmod 0600 $EMERGE_ROOT/var/spool/cron/crontabs
}
