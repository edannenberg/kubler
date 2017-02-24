#!/usr/bin/env bash

function main() {
    local portage_path
    portage_path="${1:-/var/sync/portage}"
    source /etc/profile
    # check for existing git repo, create one if it doesn't exist
    if [[ ! -d "${portage_path}" ]] || [[ ! -f "${portage_path}/.gitignore"  ]]; then
        echo "--> switch portage container to git"
        [[ -d "${portage_path}" ]] && \
            mkdir empty_dir && rsync -a --delete empty_dir/ "${portage_path}" && rmdir "${portage_path}" empty_dir
    fi
    emerge --sync
}

main "@"
