#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages=""
_influxdb_version="1.3.4"

configure_bob()
{
    emerge -v dev-vcs/mercurial
    export DISTRIBUTION_DIR=/go/src/github.com/influxdata/influxdb
    mkdir -p "${DISTRIBUTION_DIR}"
    export GOPATH=/go
    git clone https://github.com/influxdb/influxdb.git "${DISTRIBUTION_DIR}"
    cd "${DISTRIBUTION_DIR}"
    git checkout "tags/v${_influxdb_version}"
    echo "building influxdb.."
    # occasionally github clone rate limits fail the build, lets retry up to 5 times before giving up
    local i
    for i in {1..5}; 
        do ./build.py && break || { echo "retrying build in 5s.."; sleep 5; }; done
    echo "done."

    mkdir -p "${_EMERGE_ROOT}"/{bin,etc,var/opt/influxdb}
    cp "${DISTRIBUTION_DIR}"/etc/config.sample.toml "${_EMERGE_ROOT}"/etc/influxdb.conf
    cp "${DISTRIBUTION_DIR}"/build/* "${_EMERGE_ROOT}"/bin
}

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    init_docs "kubler/influxdb"
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    log_as_installed "manual install" "influxdb-${_influxdb_version}" "https://github.com/influxdb/influxdb/"
}
