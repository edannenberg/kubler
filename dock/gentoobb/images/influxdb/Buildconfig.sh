#
# build config
#
PACKAGES=""
INFLUXDB_VERSION="0.9.6.1"

configure_bob()
{
    emerge -v go mercurial
    export DISTRIBUTION_DIR=/go/src/github.com/influxdb/influxdb
    mkdir -p ${DISTRIBUTION_DIR}
    export GOPATH=/go
    git clone https://github.com/influxdb/influxdb.git ${DISTRIBUTION_DIR}
    cd ${DISTRIBUTION_DIR}
    git checkout tags/v${INFLUXDB_VERSION}
    cd ../
    echo "fetching deps.."
    # occasionally go get will fail on first run, lets retry up to 5 times before giving up
    for i in {1..5}; 
        do go get ./... && break || (echo "retry fetch.." && sleep 5); done
    echo "building influxdb.."
    go build ./...
    go install ./...
    echo "done."

    mkdir -p ${EMERGE_ROOT}/{bin,etc,var/opt/influxdb}
    cp "${DISTRIBUTION_DIR}/etc/config.sample.toml" "${EMERGE_ROOT}/etc/influxdb.conf"
    cp /go/bin/* ${EMERGE_ROOT}/bin
}

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    init_docs "gentoobb/influxdb"
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    log_as_installed "manual install" "influxdb-${INFLUXDB_VERSION}" "https://github.com/influxdb/influxdb/"
}
