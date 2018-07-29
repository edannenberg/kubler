#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="app-admin/su-exec app-shells/bash app-misc/elasticsearch"

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    update_keywords 'app-misc/elasticsearch' '+~amd64'
    # install bash again, needed at build time
    unprovide_package app-shells/bash
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    uninstall_package app-shells/bash virtual/jre-1.8.0-r1
}
