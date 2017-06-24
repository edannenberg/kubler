#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="dev-libs/libsass"

configure_bob() {
    add_layman_overlay graaff
}

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    update_keywords '=dev-libs/libsass-3.4.3' '+~amd64'
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    log_as_installed "manual_install" "gulp-cli" "http://gulpjs.com/"
}
