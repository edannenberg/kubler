#!/usr/bin/env bash

function main() {
    local portage_path
    portage_path="${1:-/var/sync/portage}"
    # shellcheck disable=SC1091
    source /etc/profile
    # check for existing git repo, create one if it doesn't exist
    if [[ -d "${portage_path}" ]] && [[ ! -d "${portage_path}"/.git ]]; then
        echo "--> switch portage container to git"
        # rm the portage dir quickly and let emerge --sync sort it out
        mkdir empty_dir && rsync -a --delete empty_dir/ "${portage_path}" && rmdir "${portage_path}" empty_dir
    fi
    emerge --sync
}

main "$@"
