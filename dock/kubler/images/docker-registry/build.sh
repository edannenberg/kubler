#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages=""
_distribution_version="2.6.0"

configure_bob()
{
    mkdir -p /go/src/github.com/docker/
    export DISTRIBUTION_DIR=/go/src/github.com/docker/distribution
    export GOPATH=${DISTRIBUTION_DIR}/Godeps/_workspace:/go
    git clone https://github.com/docker/distribution.git "${DISTRIBUTION_DIR}"
    cd "${DISTRIBUTION_DIR}"
    git checkout "tags/v${_distribution_version}"
    make PREFIX=/go clean binaries

    mkdir -p "${_EMERGE_ROOT}"/bin
    cp /go/bin/* "${_EMERGE_ROOT}"/bin
    mkdir -p "${_EMERGE_ROOT}"/go/src/github.com/docker
    cp -rfp "${DISTRIBUTION_DIR}" "${_EMERGE_ROOT}"/go/src/github.com/docker/
}

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    init_docs "kubler/docker-registry"
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    log_as_installed "manual install" "docker-registry-${_distribution_version}" "http://github.com/docker/distribution/"
}
