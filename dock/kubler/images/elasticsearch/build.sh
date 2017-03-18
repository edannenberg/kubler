#
# build config
#
_packages="app-shells/bash app-misc/elasticsearch"

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    update_keywords 'app-misc/elasticsearch' '+~amd64'
    # elasticsearch ebuild still is wired to jre7 but we already use jre8
    echo 'dev-java/oracle-jre-bin-1.7.0.76' >> /etc/portage/profile/package.provided
    # install bash again, needed at build time
    unprovide_package app-shells/bash
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    uninstall_package app-shells/bash virtual/jre-1.7.0
    install_suexec
}
