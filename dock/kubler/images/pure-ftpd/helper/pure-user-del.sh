#!/usr/bin/env sh

[[ -z "$1" ]] \
    && { echo "Usage: pure-user-del <user>"; exit 0; }

user_name="$1"

/usr/bin/pure-pw userdel "${user_name}" -f /etc/pureftpd/pureftpd.passwd -m
