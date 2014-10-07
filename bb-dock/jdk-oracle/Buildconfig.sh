#
# build config
#
PACKAGES="dev-java/oracle-jdk-bin"

#
# this method runs in the bb builder container just before starting the build of the rootfs
# 
configure_rootfs_build()
{
    echo "dev-java/oracle-jdk-bin jce" > /etc/portage/package.use/java
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    emerge -C icedtea-bin
    emerge -C python
    echo "include ld.so.conf.d/*.conf" >> /$EMERGE_ROOT/etc/ld.so.conf
    echo "/usr/x86_64-pc-linux-gnu/lib" >> /$EMERGE_ROOT/etc/ld.so.conf
}
