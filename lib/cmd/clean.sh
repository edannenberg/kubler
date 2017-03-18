#!/usr/bin/env bash
# Copyright (c) 2014-2017, Erik Dannenberg <erik.dannenberg@xtrade-gmbh.de>
# All rights reserved.

function main() {
    msg "--> remove build artifacts"
    msg "rootfs.tar files"
    find -L "${_NAMESPACE_DIR}" -name rootfs.tar -delete
    msg "generated Dockerfiles"
    find -L "${_NAMESPACE_DIR}" -name Dockerfile -delete
    msg "PACKAGES.md files"
    find -L "${_NAMESPACE_DIR}" -name PACKAGES.md -delete
}

main "$@"
