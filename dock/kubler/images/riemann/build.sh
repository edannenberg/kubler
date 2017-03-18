#
# build config
#
_packages=""
RIEMANN_VERSION="0.2.12"

configure_bob() {
    wget https://github.com/riemann/riemann/releases/download/${RIEMANN_VERSION}/riemann-${RIEMANN_VERSION}.tar.bz2
    wget https://github.com/riemann/riemann/releases/download/${RIEMANN_VERSION}/riemann-${RIEMANN_VERSION}.tar.bz2.md5
    md5sum -c riemann-${RIEMANN_VERSION}.tar.bz2.md5 || die 'error validating riemann-${RIEMANN_VERSION}.tar.bz2'
    tar xvfj riemann-${RIEMANN_VERSION}.tar.bz2
}

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    init_docs "kubler/riemann"
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    mv /riemann-${RIEMANN_VERSION} ${_EMERGE_ROOT}/riemann
    sed -i 's/host "127.0.0.1"/host "0.0.0.0"/g' ${_EMERGE_ROOT}/riemann/etc/riemann.config
    log_as_installed "manual install" "riemann-${RIEMANN_VERSION}" "https://github.com/riemann/riemann"
}
