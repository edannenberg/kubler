#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="app-shells/bash app-misc/elasticsearch"

#
# This hook is called just before starting the build of the root fs
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
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    uninstall_package app-shells/bash virtual/jre-1.8.0-r1
    install_suexec
}
