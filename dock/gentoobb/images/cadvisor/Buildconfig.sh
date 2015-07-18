#
# build config
#
PACKAGES=""
CADVISOR_VERSION=0.16.0

configure_bob()
{
    emerge -v go mercurial
    export DISTRIBUTION_DIR=/go/src/github.com/google/cadvisor
    mkdir -p ${DISTRIBUTION_DIR}
    export GOPATH=/go
    export PATH=$PATH:/go/bin
    git clone https://github.com/google/cadvisor.git ${DISTRIBUTION_DIR}
    cd ${DISTRIBUTION_DIR}
    git checkout tags/${CADVISOR_VERSION}
    # occasionally fetch might fail due to exceeded rate limits from github, lets retry up to 5 times before giving up
    echo "fetching deps.."
    for i in {1..5}; 
        do go get -d github.com/google/cadvisor && break || (echo "retry fetch.." && sleep 5); done
    for i in {1..5}; 
        do go get github.com/tools/godep && break || (echo "retry fetch.." && sleep 5); done
    echo "building cadvisor.."
    godep go build .
    echo "done."

    mkdir -p ${EMERGE_ROOT}/bin
    cp ${DISTRIBUTION_DIR}/cadvisor ${EMERGE_ROOT}/bin/
}

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    init_docs "gentoobb/cadvisor"
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    log_as_installed "manual install" "cadvisor-${CADVISOR_VERSION}" "https://github.com/google/cadvisor/"
}
