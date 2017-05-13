#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="www-client/lynx"

# keep lynx docs
export BOB_FEATURES="${BOB_FEATURES//nodoc/}"

configure_bob(){
    update_use 'sys-libs/ncurses' +minimal
    update_use 'www-client/lynx'  -nls
}

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    # add user
    useradd --shell /bin/false --user-group --home-dir /home/user --create-home user
    mkdir -p "${_EMERGE_ROOT}"/home/user
    chown -R user:user "${_EMERGE_ROOT}"/home/user
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    # ncurses
    copy_gcc_libs
}
