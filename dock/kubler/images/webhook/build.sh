#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="dev-vcs/git"
_webhook_version="2.6.5"

configure_bob()
{
    export GOPATH=/go
    export DISTRIBUTION_DIR="${GOPATH}/src/github.com/adnanh/webhook"
    mkdir -p "${DISTRIBUTION_DIR}"
    git clone https://github.com/adnanh/webhook.git "${DISTRIBUTION_DIR}"
    cd "${DISTRIBUTION_DIR}"
    git checkout "tags/${_webhook_version}"
    echo "building webhook.."
    # occasionally github clone rate limits fail the build, lets retry up to 5 times before giving up
    local i
    for i in {1..5};
        do go get -d && break || { echo "retrying build in 5s.."; sleep 5; } done
    go build -o "${_EMERGE_ROOT}"/usr/bin/webhook
    echo "done."
}

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    update_use 'dev-vcs/git' '-python' '-webdav'
    update_use 'app-crypt/gnupg' '-smartcard'
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    log_as_installed "manual install" "webhook-${_webhook_version}" "https://github.com/adnanh/webhook/"
}
