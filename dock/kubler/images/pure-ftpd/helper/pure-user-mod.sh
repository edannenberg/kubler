#!/usr/bin/env sh

[[ -z "$1" ]] \
    && { echo -e "Usage: pure-user-mod <user> [any further args are passed to pure-pw usermod..]"; exit 0; }

user_name="$1"

/usr/bin/pure-pw usermod "${user_name}" -f /etc/pure-ftpd/pureftpd.passwd -m "$@"
echo "Updating /etc/pure-ftpd/pureftpd.passwd"
/usr/bin/pure-pw mkdb /etc/pure-ftpd/pureftpd.pdb -f /etc/pure-ftpd/pureftpd.passwd
