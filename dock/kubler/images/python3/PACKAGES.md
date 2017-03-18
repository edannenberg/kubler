### kubler/python3:20170318

Built: Sat Mar 18 08:37:15 CET 2017
Image Size: 128 MB

#### Installed
Package | USE Flags
--------|----------
app-arch/bzip2-1.0.6-r7 | `-static -static-libs`
app-arch/xz-utils-5.2.3 | `nls threads -static-libs`
app-eselect/eselect-python-20160516 | ``
app-misc/mime-types-9 | ``
dev-db/sqlite-3.16.2 | `readline -debug -doc -icu -secure-delete -static-libs -tcl {-test} -tools`
dev-lang/python-3.4.5 | `hardened readline sqlite ssl (threads) xml -build -examples -gdbm -ipv6 (-libressl) -ncurses -tk -wininst`
dev-lang/python-exec-2.4.4 | ` `
dev-libs/expat-2.2.0-r1 | `unicode -examples -static-libs`
dev-libs/libffi-3.2.1 | `pax`
dev-python/CacheControl-0.11.5 | `{-test}`
dev-python/certifi-2016.9.26 | ` `
dev-python/cffi-1.9.1 | `-doc {-test}`
dev-python/chardet-2.3.0 | ` `
dev-python/colorama-0.3.3 | `-examples`
dev-python/cryptography-1.7.1 | `(-libressl) {-test}`
dev-python/distlib-0.2.1 | ` `
dev-python/html5lib-0.9999999 | `{-test}`
dev-python/idna-2.0 | ` `
dev-python/lockfile-0.11.0-r1 | `-doc {-test}`
dev-python/ndg-httpsclient-0.4.0 | ` `
dev-python/packaging-16.6 | `{-test}`
dev-python/pip-7.1.2 | ` `
dev-python/ply-3.9 | `-examples`
dev-python/progress-1.2 | ` `
dev-python/py-1.4.30 | `-doc {-test}`
dev-python/pyasn1-0.1.8 | `-doc`
dev-python/pycparser-2.14 | `{-test}`
dev-python/pyopenssl-16.2.0 | `-doc -examples {-test}`
dev-python/pyparsing-2.1.8 | `-doc -examples`
dev-python/PySocks-1.5.6 | ` `
dev-python/requests-2.11.1 | `{-test}`
dev-python/retrying-1.3.3 | ` `
dev-python/setuptools-30.4.0 | `{-test}`
dev-python/six-1.10.0 | `-doc {-test}`
dev-python/urllib3-1.16 | `-doc {-test}`
#### Inherited
Package | USE Flags
--------|----------
**FROM kubler/bash** |
app-admin/eselect-1.4.5 | `-doc -emacs -vim-syntax`
app-portage/portage-utils-0.62 | `nls -static`
app-shells/bash-4.3_p48-r1 | `net nls (readline) -afs -bashlogger -examples -mem-scramble -plugins`
dev-libs/iniparser-3.1-r1 | `-doc -examples -static-libs`
net-misc/curl-7.53.0 | `ssl threads -adns -http2 -idn -ipv6 -kerberos -ldap -metalink -rtmp -samba -ssh -static-libs {-test}`
sys-apps/acl-2.2.52-r1 | `nls -static-libs`
sys-apps/attr-2.4.47-r2 | `nls -static-libs`
sys-apps/coreutils-8.25 | `acl nls (xattr) -caps -gmp -hostname -kill -multicall (-selinux) -static -vanilla`
sys-apps/file-5.29 | `zlib -python -static-libs`
sys-apps/sed-4.2.2 | `acl nls (-selinux) -static`
sys-libs/ncurses-6.0-r1 | `cxx minimal threads unicode -ada -debug -doc -gpm (-profile) -static-libs {-test} -tinfo -trace`
sys-libs/readline-6.3_p8-r3 | `-static-libs -utils`
**FROM kubler/openssl** |
app-misc/ca-certificates-20161102.3.27.2-r2 | `-cacert -insecure`
app-misc/c_rehash-1.7-r1 | ``
dev-libs/openssl-1.0.2k | `asm sslv3 tls-heartbeat zlib -bindist -gmp -kerberos -rfc3779 -sctp -sslv2 -static-libs {-test} -vanilla`
sys-apps/debianutils-4.7 | `-static`
sys-libs/zlib-1.2.11 | `-minizip -static-libs`
**FROM kubler/s6** |
dev-lang/execline-2.2.0.0 | `-static -static-libs`
dev-libs/skalibs-2.4.0.2 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.4.0.0 | `-static -static-libs`
*manual install*: entr-3.6 | http://entrproject.org/
**FROM kubler/glibc** |
sys-apps/gentoo-functions-0.10 | ``
sys-libs/glibc-2.23-r3 | `hardened rpc -audit -caps -debug -gd (-multilib) -nscd (-profile) (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2016h | `nls -leaps`
**FROM kubler/busybox** |
sys-apps/busybox-1.25.1 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
