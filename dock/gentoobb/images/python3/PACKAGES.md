### gentoobb/python3:20150108
Built: Sun Jan 11 23:54:45 CET 2015

Image Size: 109.2 MB
#### Installed
Package | USE Flags
--------|----------
app-admin/eselect-python-20111108 | ``
app-admin/python-updater-0.11 | ``
app-arch/bzip2-1.0.6-r6 | `-static -static-libs`
app-arch/xz-utils-5.0.8 | `nls threads -static-libs`
app-misc/mime-types-9 | ``
dev-db/sqlite-3.8.6 | `readline -debug -doc -icu -secure-delete -static-libs -tcl {-test}`
dev-lang/python-3.4.1 | `hardened readline sqlite ssl threads xml -build -examples -gdbm -ipv6 -ncurses -tk -wininst`
dev-lang/python-exec-2.0.1-r1 | ` `
dev-libs/expat-2.1.0-r3 | `unicode -examples -static-libs`
dev-libs/libffi-3.0.13-r1 | `pax`
dev-python/pip-1.5.6 | ` `
dev-python/setuptools-7.0 | `{-test}`
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/bash** |
app-admin/eselect-1.4.3 | `-doc -emacs -vim-syntax`
app-shells/bash-4.2_p53 | `net nls (readline) -afs -bashlogger -examples -mem-scramble -plugins -vanilla`
net-misc/curl-7.39.0 | `ssl threads -adns -idn -ipv6 -kerberos -ldap -metalink -rtmp -ssh -static-libs {-test}`
sys-apps/file-5.21 | `zlib -python -static-libs`
sys-apps/sed-4.2.1-r1 | `acl nls (-selinux) -static`
sys-libs/ncurses-5.9-r3 | `cxx unicode -ada -debug -doc -gpm -minimal -profile -static-libs -tinfo -trace`
sys-libs/readline-6.2_p5-r1 | `-static-libs`
**FROM gentoobb/openssl** |
app-misc/ca-certificates-20130906-r1 | ``
dev-libs/openssl-1.0.1k | `bindist (sse2) tls-heartbeat zlib -gmp -kerberos -rfc3779 -static-libs {-test} -vanilla`
sys-apps/acl-2.2.52-r1 | `nls -static-libs`
sys-apps/attr-2.4.47-r1 | `nls -static-libs`
sys-apps/coreutils-8.21 | `acl nls (xattr) -caps -gmp (-selinux) -static -vanilla`
sys-apps/debianutils-4.4 | `-static`
sys-libs/zlib-1.2.8-r1 | `-minizip -static-libs`
**FROM gentoobb/s6** |
dev-lang/execline-1.3.1.1 | `-static-libs`
dev-libs/skalibs-1.6.0.0 | `-doc -static-libs`
sys-apps/s6-1.1.3.2 | ``
*manual install*: entr-2.9 | http://entrproject.org/
**FROM gentoobb/glibc** |
sys-libs/glibc-2.19-r1 | `hardened -debug -gd (-multilib) -nscd -profile (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2014i-r1 | `nls -right`
#### Purged
- [x] Headers
- [x] Static Libs
