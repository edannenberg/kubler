#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="net-misc/curl" # just to trigger the root fs build, curl is already provided and ignored
_install_docker_gen=true
_keep_headers=true
# need curl headers for fluentd gem installs
_headers_from=kubler/bash

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    :
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    log_as_installed "gem install" "fluentd" "--no-ri --no-rdoc"
    log_as_installed "gem install" "fluent-plugin-elasticsearch" "--no-ri --no-rdoc"
}
