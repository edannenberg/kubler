#!/usr/bin/env bash
# Copyright (c) 2014-2019, Erik Dannenberg <erik.dannenberg@xtrade-gmbh.de>
# All rights reserved.

PODMAN="${PODMAN:-podman}"
PODMAN_BUILD_OPTS="${PODMAN_BUILD_OPTS:---format=docker}"
PODMAN_COMMIT_OPTS="${PODMAN_BUILD_OPTS}"
DOCKER="${PODMAN}"
DOCKER_BUILD_OPTS="${PODMAN_BUILD_OPTS}"
DOCKER_COMMIT_OPTS="${PODMAN_COMMIT_OPTS}"

source "${_KUBLER_DIR}/engine/docker.sh"
