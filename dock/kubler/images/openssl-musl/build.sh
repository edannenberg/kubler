#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="dev-libs/openssl"

configure_bob()
{
    # when using overlay1 docker storage the created hard link will trigger an error during openssh uninstall
    [[ -f /usr/"${_LIB}"/misc/ssh-keysign ]] && rm /usr/"${_LIB}"/misc/ssh-keysign
    # enable ECDH
    emerge -C net-misc/openssh
    update_use 'app-misc/ca-certificates' '-cacert' '-insecure_certs'
    update_use 'dev-libs/openssl' '-bindist'
    unprovide_package 'dev-libs/openssl'
    emerge dev-libs/openssl
}

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    :
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    :
}
