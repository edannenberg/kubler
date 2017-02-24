#!/usr/bin/env bash

function main() {
    msg "--> remove build artifacts"
    msg "rootfs.tar files"
    find "${_script_dir}/${_NAMESPACE_PATH}" -name rootfs.tar -delete
    msg "generated Dockerfiles"
    find "${_script_dir}/${_NAMESPACE_PATH}" -name Dockerfile -delete
    msg "PACKAGES.md files"
    find "${_script_dir}/${_NAMESPACE_PATH}" -name PACKAGES.md -delete
}

main "$@"
