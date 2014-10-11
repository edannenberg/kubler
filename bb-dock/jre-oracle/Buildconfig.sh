#
# build config
#
PACKAGES="dev-java/oracle-jre-bin"

#
# this method runs in the bb builder container just before starting the build of the rootfs
# 
configure_rootfs_build()
{
    echo "=virtual/jre-1.7.0 ~amd64" >> /etc/portage/package.keywords/java
    # download oracle jre bin
    JRE_URL=http://download.oracle.com/otn-pub/java/jdk/7u65-b17/jre-7u65-linux-x64.tar.gz
    #JRE_TAR=$(emerge -pf oracle-jre-bin 2>&1 >/dev/null | grep -m1 "jre-[0-9a-z]*-linux-x64\.tar\.gz")
    regex="(jre-[0-9a-z]*-linux-x64\.tar\.gz)"
    if [[ ${JRE_URL} =~ $regex ]]; then
        JRE_TAR="${BASH_REMATCH[1]}"
    fi
    if [ -n ${JRE_TAR} ] && [ ! -f /distfiles/${JRE_TAR} ]; then
        wget --no-cookies --no-check-certificate \
            --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
            -P /distfiles \
            "${JRE_URL}"
    fi
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    emerge -C python
    echo "include ld.so.conf.d/*.conf" >> /$EMERGE_ROOT/etc/ld.so.conf
    echo "/usr/x86_64-pc-linux-gnu/lib" >> /$EMERGE_ROOT/etc/ld.so.conf
}
