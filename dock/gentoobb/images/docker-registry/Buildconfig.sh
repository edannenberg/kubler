#
# build config
#
PACKAGES=""
REGISTRY_VERSION=2.0.0

configure_bob()
{
    emerge -v go
    mkdir -p /go/src/github.com/docker/
    export DISTRIBUTION_DIR=/go/src/github.com/docker/distribution
    export GOPATH=${DISTRIBUTION_DIR}/Godeps/_workspace:/go
    git clone https://github.com/docker/distribution.git ${DISTRIBUTION_DIR}
    cd ${DISTRIBUTION_DIR}
    git checkout tags/v${REGISTRY_VERSION}
    make PREFIX=/go clean binaries

    mkdir -p ${EMERGE_ROOT}/bin
    cp /go/bin/* ${EMERGE_ROOT}/bin
    mkdir -p ${EMERGE_ROOT}/go/src/github.com/docker
    cp -rfp ${DISTRIBUTION_DIR} ${EMERGE_ROOT}/go/src/github.com/docker/
}

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    init_docs "gentoobb/docker-registry"
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    log_as_installed "manual install" "docker-registry-${REGISTRY_VERSION}" "http://github.com/docker/distribution/"
}
