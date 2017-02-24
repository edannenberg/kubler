#
# build config
#
_packages="dev-java/oracle-jdk-bin"

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    # download oracle jdk bin
    JDK_URL=http://download.oracle.com/otn-pub/java/jdk/8u121-b13/e9e7ea248e2c4826b92b3f075a80e441/jdk-8u121-linux-x64.tar.gz

    #JDK_TAR=$(emerge -pf oracle-jdk-bin 2>&1 >/dev/null | grep -m1 "jre-[0-9a-z]*-linux-x64\.tar\.gz")
    regex="(jdk-[0-9a-z]*-linux-x64\.tar\.gz)"
    [[ ${JDK_URL} =~ $regex ]] && JDK_TAR="${BASH_REMATCH[1]}"
    [ -n ${JDK_TAR} ] && [ ! -f /distfiles/${JDK_TAR} ] && download_from_oracle "${JDK_URL}"

    JCE_URL=http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip
    [ ! -f /distfiles/${JCE_URL} ] && download_from_oracle "${JCE_URL}"

    update_use 'dev-java/oracle-jdk-bin' '+headless-awt +jce -fontconfig'
    # skip python and iced-tea
    provide_package dev-lang/python dev-java/icedtea-bin
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    # gentoo's run-java-tool.bash wrapper expects which at /usr/bin
    ln -rs ${_EMERGE_ROOT}/bin/which ${_EMERGE_ROOT}/usr/bin/which
}
