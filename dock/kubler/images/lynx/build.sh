#
# build config
#

_packages="www-client/lynx"

# keep lynx docs
export BOB_FEATURES="${BOB_FEATURES//nodoc/}"

configure_bob(){
    update_use 'sys-libs/ncurses' +minimal
    update_use 'www-client/lynx'  -nls
}

configure_rootfs_build()
{
    # add user
    useradd --shell /bin/false --user-group --home-dir /home/user --create-home user
    mkdir -p ${_EMERGE_ROOT}/home/user
    chown -R user:user ${_EMERGE_ROOT}/home/user
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    # ncurses
    copy_gcc_libs
}
