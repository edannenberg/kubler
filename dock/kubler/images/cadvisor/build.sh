#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages=""
_cadvisor_version="0.25.0"

configure_bob()
{
    emerge -v mercurial
    export DISTRIBUTION_DIR=/go/src/github.com/google/cadvisor
    mkdir -p "${DISTRIBUTION_DIR}"
    export GOPATH=/go
    export PATH="${PATH}:/go/bin"
    git clone https://github.com/google/cadvisor.git "${DISTRIBUTION_DIR}"
    cd "${DISTRIBUTION_DIR}"
    git checkout "tags/v${_cadvisor_version}"
    # occasionally fetch might fail due to exceeded rate limits from github, lets retry up to 5 times before giving up
    echo "fetching deps.."
    for i in {1..5}; do
        go get github.com/tools/godep && break || { echo "retry fetch.."; sleep 5; } done
    echo "building cadvisor.."

    local repo_path version revision branch build_user build_date go_version ldseparator ldflags

    repo_path="github.com/google/cadvisor"

    version=$( git describe --tags --dirty --abbrev=14 | sed -E 's/-([0-9]+)-g/.\1+/' )
    revision=$( git rev-parse --short HEAD 2> /dev/null || echo 'unknown' )
    branch=$( git rev-parse --abbrev-ref HEAD 2> /dev/null || echo 'unknown' )
    build_user="${USER}@${HOSTNAME}"
    build_date=$( date +%Y%m%d-%H:%M:%S )
    go_version=$( go version | sed -e 's/^[^0-9.]*\([0-9.]*\).*/\1/' )

    ldseparator="="

    ldflags="
      -extldflags '-static'
      -X ${repo_path}/version.Version${ldseparator}${version}
      -X ${repo_path}/version.Revision${ldseparator}${revision}
      -X ${repo_path}/version.Branch${ldseparator}${branch}
      -X ${repo_path}/version.BuildUser${ldseparator}${build_user}
      -X ${repo_path}/version.BuildDate${ldseparator}${build_date}
      -X ${repo_path}/version.GoVersion${ldseparator}${go_version}"

    godep go build -ldflags "${ldflags}" ${repo_path}
    echo "done."

    mkdir -p "${_EMERGE_ROOT}"/bin
    cp "${DISTRIBUTION_DIR}"/cadvisor "${_EMERGE_ROOT}"/bin/
}

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    # init docs as _packages is empty
    init_docs "kubler/cadvisor"
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    log_as_installed "manual install" "cadvisor-${_cadvisor_version}" "https://github.com/google/cadvisor/"
}
