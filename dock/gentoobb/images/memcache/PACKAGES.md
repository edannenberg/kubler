### gentoobb/memcache:20161020
Built: Sun Oct 23 23:06:22 CEST 2016

Image Size: 78.37 MB
#### Installed
Package | USE Flags
--------|----------
app-admin/perl-cleaner-2.20 | ``
app-arch/bzip2-1.0.6-r7 | `-static -static-libs`
dev-lang/perl-5.22.2 | `berkdb -debug -doc -gdbm -ithreads`
dev-libs/libevent-2.0.22 | `ssl threads -debug -static-libs {-test}`
net-misc/memcached-1.4.31 | `-debug -sasl (-selinux) -slabs-reassign {-test}`
perl-core/File-Temp-0.230.400-r1 | ``
sys-libs/db-4.8.30-r2 | `cxx -doc -examples -java -tcl {-test}`
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/bash** |
app-admin/eselect-1.4.5 | `-doc -emacs -vim-syntax`
app-portage/portage-utils-0.62 | `nls -static`
app-shells/bash-4.3_p48 | `net nls (readline) -afs -bashlogger -examples -mem-scramble -plugins -vanilla`
dev-libs/iniparser-3.1-r1 | `-doc -examples -static-libs`
net-misc/curl-7.50.3 | `ssl threads -adns -http2 -idn -ipv6 -kerberos -ldap -metalink -rtmp -samba -ssh -static-libs {-test}`
sys-apps/acl-2.2.52-r1 | `nls -static-libs`
sys-apps/attr-2.4.47-r2 | `nls -static-libs`
sys-apps/file-5.25 | `zlib -python -static-libs`
sys-apps/sed-4.2.1-r1 | `acl nls (-selinux) -static`
sys-libs/ncurses-5.9-r5 | `cxx unicode -ada -debug -doc -gpm -minimal (-profile) -static-libs -tinfo -trace`
sys-libs/ncurses-5.9-r99 | `cxx unicode -ada -gpm -static-libs -tinfo`
sys-libs/readline-6.3_p8-r2 | `-static-libs -utils`
**FROM gentoobb/openssl** |
app-misc/ca-certificates-20151214.3.21 | `cacert`
app-misc/c_rehash-1.7-r1 | ``
dev-libs/openssl-1.0.2j | `asm sslv3 tls-heartbeat zlib -bindist -gmp -kerberos -rfc3779 -sctp -sslv2 -static-libs {-test} -vanilla`
sys-apps/debianutils-4.7 | `-static`
sys-libs/zlib-1.2.8-r1 | `-minizip -static-libs`
**FROM gentoobb/s6** |
dev-lang/execline-2.1.5.0 | `-static -static-libs`
dev-libs/skalibs-2.3.10.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.3.0.0 | `-static -static-libs`
*manual install*: entr-3.4 | http://entrproject.org/
**FROM gentoobb/glibc** |
sys-apps/gentoo-functions-0.10 | ``
sys-libs/glibc-2.22-r4 | `hardened -debug -gd (-multilib) -nscd (-profile) (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2016e | `nls -leaps`
**FROM gentoobb/busybox** |
sys-apps/busybox-1.24.2 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
