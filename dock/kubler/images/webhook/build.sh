#
# build config
#
_packages="dev-vcs/git"
WEBHOOK_VERSION="2.6.0"

configure_bob()
{
    export GOPATH=/go
    export DISTRIBUTION_DIR="${GOPATH}/src/github.com/adnanh/webhook"
    mkdir -p ${DISTRIBUTION_DIR}
    git clone https://github.com/adnanh/webhook.git ${DISTRIBUTION_DIR}
    cd ${DISTRIBUTION_DIR}
    git checkout tags/${WEBHOOK_VERSION}
    echo "building webhook.."
    # occasionally github clone rate limits fail the build, lets retry up to 5 times before giving up
    for i in {1..5};
        do go get -d && break || { echo "retrying build in 5s.."; sleep 5} done
    go build -o "${_EMERGE_ROOT}/usr/bin/webhook"
    echo "done."
}

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    update_use "dev-vcs/git" "-python" "-webdav"
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    log_as_installed "manual install" "webhook-${WEBHOOK_VERSION}" "https://github.com/adnanh/webhook/"
}
