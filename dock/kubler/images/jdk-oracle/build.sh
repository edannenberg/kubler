#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="dev-java/oracle-jdk-bin"

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    local java_url
    java_url='http://download.oracle.com/otn-pub/java'
    download_from_oracle "${java_url}"/jdk/8u172-b11/a58eab1ec242421181065cdc37240b08/jdk-8u172-linux-x64.tar.gz
    download_from_oracle "${java_url}"/jce/8/jce_policy-8.zip

    update_use 'dev-java/oracle-jdk-bin' +headless-awt +jce +fontconfig
    # skip python and iced-tea
    provide_package dev-lang/python dev-java/icedtea-bin

    # add user/group for unprivileged container usage
    groupadd -g 808 java
    useradd -u 8080 -g java -d /home/java java
    mkdir -p "${_EMERGE_ROOT}"/home/java
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    # required by fontconfig
    copy_gcc_libs
    # gentoo's run-java-tool.bash wrapper expects which at /usr/bin
    ln -rs "${_EMERGE_ROOT}"/bin/which "${_EMERGE_ROOT}"/usr/bin/which
}
