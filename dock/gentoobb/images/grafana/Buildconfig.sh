#
# build config
#
PACKAGES=""
GRAFANA_VERSION="2.6.0"

configure_bob()
{
    # nodejs currently requires openssl with ECDH :/
    emerge -C net-misc/openssh
    update_use 'dev-libs/openssl' '-bindist'
    unprovide_package 'dev-libs/openssl'
    emerge dev-libs/openssl

    # go 1.4.x will fail the build since grafana 2.6.0
    update_keywords 'dev-lang/go' '+~amd64'
    update_keywords 'dev-lang/go-bootstrap' '+~amd64'

    emerge -v dev-lang/go net-libs/nodejs
    export DISTRIBUTION_DIR=/go/src/github.com/grafana/grafana
    mkdir -p ${DISTRIBUTION_DIR}
    export GOPATH=/go
    export PATH=$PATH:/go/bin
    git clone https://github.com/grafana/grafana.git ${DISTRIBUTION_DIR}
    cd ${DISTRIBUTION_DIR}
    git checkout tags/v${GRAFANA_VERSION}
    echo "fetching deps.."
    # occasionally fetch might fail due to exceeded rate limits from github, lets retry up to 5 times before giving up
    for i in {1..5}; 
        do go get github.com/grafana/grafana && break || (echo "retry fetch.." && sleep 15); done
    go run build.go setup
    for i in {1..5}; 
        do godep restore && break || (echo "retry fetch.." && sleep 15); done
    echo "building grafana.."
    go run build.go build

    npm install
    npm install -g grunt-cli gyp
    #TODO: release fails due to not being able to execute phantomjs tests, figure out how to skip those for release target
    #grunt release
    grunt

    mkdir -p ${EMERGE_ROOT}/opt/grafana/{bin,conf,data}
    cp -rp "${DISTRIBUTION_DIR}/public_gen" "${EMERGE_ROOT}/opt/grafana/"
    cp "${DISTRIBUTION_DIR}/conf/defaults.ini" "${EMERGE_ROOT}/opt/grafana/conf/"
    cp "${DISTRIBUTION_DIR}/conf/sample.ini" "${EMERGE_ROOT}/opt/grafana/conf/custom.ini"
    cp ${DISTRIBUTION_DIR}/bin/* ${EMERGE_ROOT}/opt/grafana/bin
}

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    init_docs "gentoobb/grafana"
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    log_as_installed "manual install" "grafana-${GRAFANA_VERSION}" "https://github.com/grafana/grafana/"
}
