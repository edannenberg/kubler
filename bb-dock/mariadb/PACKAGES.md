### gentoobb/mariadb:20141127
Built: Fri Nov 28 14:22:28 CET 2014
Image Size: 190.5 MB
#### Installed
Package | USE Flags
--------|----------
app-admin/perl-cleaner-2.16 | ``
app-arch/bzip2-1.0.6-r6 | `-static -static-libs`
dev-db/mariadb-5.5.40-r1 | `bindist community pam perl ssl -cluster -debug -embedded -extraengine -jemalloc -latin1 -max-idx-128 -minimal -oqgraph -profiling (-selinux) -sphinx -static -static-libs -systemtap -tcmalloc {-test} -tokudb`
dev-db/mysql-init-scripts-2.0-r1 | ``
dev-lang/perl-5.18.2-r2 | `berkdb gdbm -debug -doc -ithreads`
dev-libs/libaio-0.3.110 | `-static-libs {-test}`
dev-perl/DBD-mysql-4.20.0-r1 | `-embedded`
dev-perl/DBI-1.628.0 | `{-test}`
dev-perl/Net-Daemon-0.480.0-r1 | ``
dev-perl/PlRPC-0.202.0-r2 | ``
dev-perl/TermReadKey-2.300.200-r1 | ``
perl-core/File-Temp-0.230.0 | ``
sys-apps/texinfo-4.13-r2 | `nls -static`
sys-libs/gdbm-1.11 | `berkdb nls -exporter -static-libs`
sys-process/procps-3.3.9 | `ncurses nls unicode -static-libs {-test}`
#### Inherited
Package | USE Flags
--------|----------
**FROM bash** |
app-admin/eselect-1.4.3 | `-doc -emacs -vim-syntax`
app-shells/bash-4.2_p53 | `net nls (readline) -afs -bashlogger -examples -mem-scramble -plugins -vanilla`
net-misc/curl-7.39.0 | `ipv6 ssl threads -adns -idn -kerberos -ldap -metalink -rtmp -ssh -static-libs {-test}`
sys-apps/file-5.19 | `zlib -python -static-libs`
sys-apps/sed-4.2.1-r1 | `acl nls (-selinux) -static`
sys-libs/ncurses-5.9-r3 | `cxx unicode -ada -debug -doc -gpm -minimal -profile -static-libs -tinfo -trace`
sys-libs/readline-6.2_p5-r1 | `-static-libs`
**FROM openssl** |
app-misc/ca-certificates-20130906-r1 | ``
dev-libs/openssl-1.0.1j | `bindist (sse2) tls-heartbeat zlib -gmp -kerberos -rfc3779 -static-libs {-test} -vanilla`
sys-apps/acl-2.2.52-r1 | `nls -static-libs`
sys-apps/attr-2.4.47-r1 | `nls -static-libs`
sys-apps/coreutils-8.21 | `acl nls -caps -gmp (-selinux) -static -vanilla -xattr`
sys-apps/debianutils-4.4 | `-static`
**FROM s6** |
dev-lang/execline-1.3.1.1 | `-static-libs`
dev-libs/skalibs-1.6.0.0 | `-doc -static-libs`
sys-apps/s6-1.1.3.2 | ``
*manual install*: entr-2.9 | http://entrproject.org/
**FROM busybox** |
sys-apps/busybox-1.21.0 | `ipv6 make-symlinks pam -livecd -math -mdev -savedconfig (-selinux) -sep-usr -static -syslog -systemd`
sys-auth/pambase-20120417-r3 | `cracklib sha512 -consolekit -debug -gnome-keyring -minimal -mktemp -pam`
sys-libs/cracklib-2.9.1-r1 | `nls zlib -python -static-libs {-test}`
sys-libs/db-4.8.30-r1 | `cxx -doc -examples -java -tcl {-test}`
sys-libs/glibc-2.19-r1 | `-debug -gd (-hardened) (-multilib) -nscd -profile (-selinux) -suid -systemtap -vanilla`
sys-libs/pam-1.1.8-r2 | `berkdb cracklib nls -audit -debug -nis (-selinux) {-test} -vim-syntax`
sys-libs/timezone-data-2014i-r1 | `nls -right`
sys-libs/zlib-1.2.8-r1 | `-minizip -static-libs`
#### Purged
- [x] Headers
- [x] Static Libs
