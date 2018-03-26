#!/usr/bin/env sh

[[ -z "$1" ]] \
    && { echo "Usage: pure-user-show <user>"; exit 0; }

user_name="$1"

/usr/bin/pure-pw show "${user_name}" -f /etc/pure-ftpd/pureftpd.passwd
