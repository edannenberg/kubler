#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="net-libs/http-parser dev-libs/libuv dev-libs/icu net-libs/nodejs sys-apps/yarn"

configure_bob()
{
    update_use net-libs/nodejs +icu
    # build binary packages first to avoid pulling in python in the next phase
    emerge net-libs/http-parser dev-libs/libuv dev-libs/icu net-libs/nodejs
}

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    update_keywords 'sys-apps/yarn' '+~amd64'
    # install binary packages with no deps when building the root fs
    _emerge_opt="--nodeps"
    # add user/group for unprivileged container usage
    groupadd -g 700 nodejs
    useradd -u 7000 -g nodejs -d /home/nodejs nodejs
    mkdir -p "${_EMERGE_ROOT}"/home/nodejs
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    copy_gcc_libs
}
