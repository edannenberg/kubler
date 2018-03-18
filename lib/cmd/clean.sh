#!/usr/bin/env bash
# Copyright (c) 2014-2017, Erik Dannenberg <erik.dannenberg@xtrade-gmbh.de>
# All rights reserved.

function main() {
    local namespace_dirs
    namespace_dirs=( "${_NAMESPACE_DIR}" )
    [[ "${_NAMESPACE_TYPE}" != 'local' ]] && namespace_dirs+=( "${_KUBLER_NAMESPACE_DIR}" )
    msg "--> remove build artifacts"
    msg "rootfs.tar files"
    find -L "${namespace_dirs[@]}" -name rootfs.tar -delete
    msg "generated Dockerfiles"
    find -L "${namespace_dirs[@]}" -name Dockerfile -delete
    msg "PACKAGES.md files"
    find -L "${namespace_dirs[@]}" -name PACKAGES.md -delete
}

main "$@"
