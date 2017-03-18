#
# build config
#
_packages="dev-libs/libxslt sys-libs/zlib"
_keep_headers=true

configure_bob() {
    :
}

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    unprovide_package "sys-libs/zlib"
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    log_as_installed "gem install" "riemann-client riemann-tools riemann-dash" "https://github.com/aphyr/riemann"
}
