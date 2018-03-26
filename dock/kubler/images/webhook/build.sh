#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="dev-vcs/git dev-vcs/webhook"
_webhook_version="2.6.8"

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    update_use 'dev-vcs/git' '-python' '-webdav'
    update_use 'app-crypt/gnupg' '-smartcard'
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    :
}
