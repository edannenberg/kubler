#!/usr/bin/env sh

[[ -z "$1" || -z "$2" ]] \
    && { echo -e "Usage: pure-user-add <user> <user_home> [any further args are passed to pure-pw useradd..]"; exit 0; }

user_name="$1"
home_dir="$2"

/usr/bin/pure-pw useradd "${user_name}" -f /etc/pure-ftpd/pureftpd.passwd -u ftp-data -g ftp-data -D "${home_dir}" -m "$@"
echo "Updating /etc/pure-ftpd/pureftpd.pdb"
/usr/bin/pure-pw mkdb /etc/pure-ftpd/pureftpd.pdb -f /etc/pure-ftpd/pureftpd.passwd
