#!/usr/bin/env sh

[[ -z "$1" || -z "$2" ]] \
    && { echo -e "Usage: pure-user-add <user> <user_home> [any further args are passed to pure-pw useradd..]"; exit 0; }

user_name="$1"
home_dir="$2"

/usr/bin/pure-pw useradd "${user_name}" -f /etc/pureftpd/pureftpd.passwd -u ftp-data -D "${home_dir}" -m "$@"
