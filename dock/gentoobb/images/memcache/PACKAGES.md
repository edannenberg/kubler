### gentoobb/memcache:20150312
Built: Sat Mar 14 23:51:54 CET 2015

Image Size: 77.63 MB
#### Installed
Package | USE Flags
--------|----------
app-admin/perl-cleaner-2.19 | ``
app-arch/bzip2-1.0.6-r6 | `-static -static-libs`
app-portage/portage-utils-0.53 | `nls -static`
dev-lang/perl-5.20.1-r4 | `berkdb -debug -doc -gdbm -ithreads`
dev-libs/libevent-2.0.22 | `ssl threads -debug -static-libs {-test}`
net-misc/memcached-1.4.17 | `-debug -sasl -slabs-reassign {-test}`
perl-core/Data-Dumper-2.154.0 | ``
perl-core/File-Temp-0.230.400-r1 | ``
sys-libs/db-4.8.30-r2 | `cxx -doc -examples -java -tcl {-test}`
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/bash** |
app-admin/eselect-1.4.4 | `-doc -emacs -vim-syntax`
app-shells/bash-4.2_p53 | `net nls (readline) -afs -bashlogger -examples -mem-scramble -plugins -vanilla`
net-misc/curl-7.39.0 | `ssl threads -adns -idn -ipv6 -kerberos -ldap -metalink -rtmp -ssh -static-libs {-test}`
sys-apps/file-5.22 | `zlib -python -static-libs`
sys-apps/sed-4.2.1-r1 | `acl nls (-selinux) -static`
sys-libs/ncurses-5.9-r3 | `cxx unicode -ada -debug -doc -gpm -minimal -profile -static-libs -tinfo -trace`
sys-libs/readline-6.2_p5-r1 | `-static-libs`
**FROM gentoobb/openssl** |
app-misc/ca-certificates-20130906-r1 | ``
dev-libs/openssl-1.0.1k | `bindist tls-heartbeat zlib -gmp -kerberos -rfc3779 -static-libs {-test} -vanilla`
sys-apps/acl-2.2.52-r1 | `nls -static-libs`
sys-apps/attr-2.4.47-r1 | `nls -static-libs`
sys-apps/coreutils-8.21 | `acl nls (xattr) -caps -gmp (-selinux) -static -vanilla`
sys-apps/debianutils-4.4 | `-static`
sys-libs/zlib-1.2.8-r1 | `-minizip -static-libs`
**FROM gentoobb/s6** |
dev-lang/execline-2.0.2.1 | `-static -static-libs`
dev-libs/skalibs-2.3.0.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.1.1.1 | `-static`
*manual install*: entr-2.9 | http://entrproject.org/
**FROM gentoobb/glibc** |
sys-libs/glibc-2.19-r1 | `hardened -debug -gd (-multilib) -nscd -profile (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2014j | `nls -right`
#### Purged
- [x] Headers
- [x] Static Libs
