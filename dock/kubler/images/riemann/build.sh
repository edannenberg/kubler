#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages=""

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    init_docs "kubler/riemann"
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    local riemann_version riemann_url riemann_file
    riemann_version="0.3.0"
    riemann_url="https://github.com/riemann/riemann/releases/download/${riemann_version}/riemann-${riemann_version}.tar.bz2"
    download_file "${riemann_url}"
    riemann_file="${__download_file}"
    download_file "${riemann_url}.md5"
    pushd /distfiles > /dev/null
    md5sum -c "${__download_file}" || die "error validating ${riemann_file}"
    popd
    tar xvjf "${riemann_file}"
    mv /riemann-"${riemann_version}" "${_EMERGE_ROOT}"/riemann
    sed -i 's/host "127.0.0.1"/host "0.0.0.0"/g' "${_EMERGE_ROOT}"/riemann/etc/riemann.config
    log_as_installed "manual install" "riemann-${riemann_version}" "https://github.com/riemann/riemann"
}
