#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="dev-java/oracle-jdk-bin"

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    local jdk_url jce_url jdk_tar
    # download oracle jdk bin
    jdk_url=http://download.oracle.com/otn-pub/java/jdk/8u121-b13/e9e7ea248e2c4826b92b3f075a80e441/jdk-8u121-linux-x64.tar.gz

    #jdk_tar=$(emerge -pf oracle-jdk-bin 2>&1 >/dev/null | grep -m1 "jre-[0-9a-z]*-linux-x64\.tar\.gz")
    regex="(jdk-[0-9a-z]*-linux-x64\.tar\.gz)"
    [[ ${jdk_url} =~ $regex ]] && jdk_tar="${BASH_REMATCH[1]}"
    [[ -n ${jdk_tar} ]] && [[ ! -f /distfiles/"${jdk_tar}" ]] && download_from_oracle "${jdk_url}"

    jce_url=http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip
    [[ ! -f /distfiles/${jce_url} ]] && download_from_oracle "${jce_url}"

    update_use 'dev-java/oracle-jdk-bin' '+headless-awt +jce -fontconfig'
    # skip python and iced-tea
    provide_package dev-lang/python dev-java/icedtea-bin
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    # gentoo's run-java-tool.bash wrapper expects which at /usr/bin
    ln -rs "${_EMERGE_ROOT}"/bin/which "${_EMERGE_ROOT}"/usr/bin/which
}
