#
# build config
#
_packages=""
GRAFANA_VERSION="4.1.2"

configure_bob()
{
    emerge -v net-libs/nodejs
    export DISTRIBUTION_DIR=/go/src/github.com/grafana/grafana
    mkdir -p ${DISTRIBUTION_DIR}
    export GOPATH=/go
    export PATH=$PATH:/go/bin
    git clone https://github.com/grafana/grafana.git ${DISTRIBUTION_DIR}
    cd ${DISTRIBUTION_DIR}
    git checkout tags/v${GRAFANA_VERSION}
    echo "building grafana.."
    go run build.go build

    npm install
    npm install -g grunt-cli gyp
    #TODO: release fails due to not being able to execute phantomjs tests, figure out how to skip those for release target
    #grunt release
    grunt --force

    mkdir -p ${_EMERGE_ROOT}/opt/grafana/{bin,conf,data}
    cp -rp "${DISTRIBUTION_DIR}/public_gen" "${_EMERGE_ROOT}/opt/grafana/"
    cp "${DISTRIBUTION_DIR}/conf/defaults.ini" "${_EMERGE_ROOT}/opt/grafana/conf/"
    cp "${DISTRIBUTION_DIR}/conf/sample.ini" "${_EMERGE_ROOT}/opt/grafana/conf/custom.ini"
    cp ${DISTRIBUTION_DIR}/bin/* ${_EMERGE_ROOT}/opt/grafana/bin
}

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    init_docs "kubler/grafana"
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    log_as_installed "manual install" "grafana-${GRAFANA_VERSION}" "https://github.com/grafana/grafana/"
}
