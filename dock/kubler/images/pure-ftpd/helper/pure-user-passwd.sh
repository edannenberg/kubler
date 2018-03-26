#!/usr/bin/env sh

[[ -z "$1" ]] \
    && { echo "Usage: pure-user-passwd <user>"; exit 0; }

user_name="$1"

/usr/bin/pure-pw passwd "${user_name}" -f /etc/pure-ftpd/pureftpd.passwd -m
echo "Updating /etc/pure-ftpd/pureftpd.pdb"
/usr/bin/pure-pw mkdb /etc/pure-ftpd/pureftpd.pdb -f /etc/pure-ftpd/pureftpd.passwd

