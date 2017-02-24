#
# build config, sourced by build-root.sh inside build container
#

# list of gentoo package atoms to be installed at custom rootfs (${EMERGE_ROOT}), optional
# if you are not sure about package names you may want to run:
# ./bin/bob_interactive ${_tmpl_namespace}/$tmpl_image_name} and then emerge -s <search-string>
_packages=""
# if PACKAGES is not empty a minimal base layout is created at ${EMERGE_ROOT}, empty directories for the most part.
# skipping the base layout my cause errors with some packages, enable at your own risk
#BOB_SKIP_BASELAYOUT=true

# define custom variables to your liking
#_${_tmpl_image_name}_version=1.0

#
# this hook can be used to configure the build container itself, install packages, run any command, etc
#
configure_bob()
{
    # packages installed in this hook don't end up in the final image but are available for depending image builds
    #emerge dev-lang/go app-misc/foo
    :
}


#
# this hook is called in the build container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    # update a gentoo package use flag..
    #update_use 'dev-libs/some-lib' '+feature -some_other_feature'

    # ..or a gentoo package keyword
    #update_keywords 'dev-lang/some-package' '+~amd64'

    # only needed when PACKAGES is empty, initializes PACKAGES.md
    #init_docs "${_tmpl_namespace}/${_tmpl_image_name}"
    :
}

#
# this hook is called in the build container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    # useful helpers

    # install su-exec in ${EMERGE_ROOT}
    #install_suexec
    # copy c++ libs, may be needed if you see errors regarding missing libstdc++
    #copy_gcc_libs

    # example for a manual build if PACKAGES method does not suffice, a typical use case is a go project:

    #export GOPATH=/go
    #export PATH=$PATH:/go/bin
    #export DISTRIBUTION_DIR="${GOPATH}/src/github.com/${_tmpl_namespace}/${_tmpl_image_name}"
    #mkdir -p ${DISTRIBUTION_DIR}

    #git clone https://github.com/${_tmpl_namespace}/${_tmpl_image_name}.git ${DISTRIBUTION_DIR}
    #cd ${DISTRIBUTION_DIR}
    #git checkout tags/v${_${_tmpl_image_name}_version}
    #echo "building ${_tmpl_image_name} ${_${_tmpl_image_name}_version}.."
    #go run build.go build
    #mkdir -p ${EMERGE_ROOT}/usr/local/{bin,share}

    # everything under ${EMERGE_ROOT} will end up in the final image
    #cp -rp "${DISTRIBUTION_DIR}/bin/*" "${EMERGE_ROOT}/usr/local/bin"

    # after installing packages manually you might want to add an entry to PACKAGES.md
    #log_as_installed "manual install" "${_tmpl_image_name}-${_${_tmpl_image_name}_version}" "https://${_tmpl_image_name}.org/"
    :
}
