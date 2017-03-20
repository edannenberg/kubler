#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="dev-libs/libxslt sys-libs/zlib"
_keep_headers=true

configure_bob() {
    :
}

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    unprovide_package "sys-libs/zlib"
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    log_as_installed "gem install" "riemann-client riemann-tools riemann-dash" "https://github.com/aphyr/riemann"
}
