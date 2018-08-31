### kubler/mariadb:20180831

Built: Fri Aug 31 18:28:30 CEST 2018
Image Size: 255MB

#### Installed
Package | USE Flags
--------|----------
app-admin/perl-cleaner-2.25 | ``
app-arch/bzip2-1.0.6-r10 | `-static -static-libs`
app-arch/libarchive-3.3.1 | `acl bzip2 e2fsprogs iconv lzma threads xattr zlib -expat -libressl -lz4 -lzo -nettle -static-libs`
app-arch/pbzip2-1.1.12 | `-static -symlink`
app-arch/xz-utils-5.2.3 | `extra-filters nls threads -static-libs`
dev-db/mariadb-10.1.34 | `backup bindist perl server (-client-libs) -cracklib -debug -extraengine -galera -innodb-lz4 -innodb-lzo -innodb-snappy -jdbc -jemalloc -kerberos -latin1 -libressl (-mroonga) -numa -odbc -oqgraph -pam -profiling (-selinux) -sphinx -sst-mariabackup -sst-rsync -sst-xtrabackup -static -static-libs -systemd -systemtap -tcmalloc {-test} -tokudb -xml -yassl`
dev-db/mysql-connector-c-6.1.11-r1 | `ssl -libressl -static-libs`
dev-db/mysql-init-scripts-2.2-r3 | ``
dev-lang/perl-5.24.3-r1 | `-berkdb -debug -doc -gdbm -ithreads`
dev-libs/libaio-0.3.110 | `-static-libs {-test}`
dev-libs/libpcre-8.41-r1 | `bzip2 cxx readline recursion-limit (unicode) zlib -jit -libedit -pcre16 -pcre32 -static-libs`
dev-libs/libxml2-2.9.8 | `readline -debug -examples -icu -ipv6 -lzma -python -static-libs {-test}`
dev-perl/DBD-mysql-4.44.0 | `ssl {-test}`
dev-perl/DBI-1.637.0 | `-examples {-test}`
dev-perl/libintl-perl-1.280.0 | ``
dev-perl/Net-Daemon-0.480.0-r2 | ``
dev-perl/PlRPC-0.202.0-r3 | ``
dev-perl/TermReadKey-2.330.0 | ``
dev-perl/Text-Unidecode-1.300.0 | ``
dev-perl/Unicode-EastAsianWidth-1.330.0-r1 | ``
perl-core/File-Path-2.130.0 | ``
perl-core/File-Temp-0.230.400-r1 | ``
sys-apps/opentmpfiles-0.1.3 | `(-selinux)`
sys-apps/texinfo-6.3 | `nls -static`
sys-process/procps-3.3.15-r1 | `kill nls unicode -elogind -modern-top -ncurses (-selinux) -static-libs -systemd {-test}`
*manual install*: automysqlbackup-3.0_rc6 | https://sourceforge.net/projects/automysqlbackup/
#### Inherited
Package | USE Flags
--------|----------
**FROM kubler/bash** |
app-admin/eselect-1.4.12 | `-doc -emacs -vim-syntax`
app-portage/portage-utils-0.64 | `nls -static`
app-shells/bash-4.4_p12 | `net nls (readline) -afs -bashlogger -examples -mem-scramble -plugins`
dev-libs/iniparser-3.1-r1 | `-doc -examples -static-libs`
net-misc/curl-7.61.0 | `ssl threads -adns -brotli -http2 -idn -ipv6 -kerberos -ldap -metalink -rtmp -samba -ssh -static-libs {-test}`
sys-apps/acl-2.2.52-r1 | `nls -static-libs`
sys-apps/attr-2.4.47-r2 | `nls -static-libs`
sys-apps/coreutils-8.29-r1 | `acl nls split-usr (xattr) -caps -gmp -hostname -kill -multicall (-selinux) -static {-test} -vanilla`
sys-apps/file-5.33-r4 | `zlib -python -static-libs`
sys-apps/sed-4.5 | `acl nls -forced-sandbox (-selinux) -static`
sys-libs/ncurses-6.1-r2 | `cxx minimal threads unicode -ada -debug -doc -gpm (-profile) -static-libs {-test} -tinfo -trace`
sys-libs/readline-7.0_p3 | `-static-libs -utils`
**FROM kubler/openssl** |
app-misc/ca-certificates-20170717.3.36.1 | `-cacert -insecure`
app-misc/c_rehash-1.7-r1 | ``
dev-libs/openssl-1.0.2o-r3 | `asm sslv3 tls-heartbeat zlib -bindist -gmp -kerberos -rfc3779 -sctp -sslv2 -static-libs {-test} -vanilla`
sys-apps/debianutils-4.8.3 | `-static`
sys-libs/zlib-1.2.11-r2 | `-minizip -static-libs`
**FROM kubler/s6** |
app-admin/entr-4.1 | `{-test}`
dev-lang/execline-2.3.0.4 | `-static -static-libs`
dev-libs/skalibs-2.6.4.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.7.1.1 | `-static -static-libs`
**FROM kubler/glibc** |
sys-apps/gentoo-functions-0.12 | ``
sys-libs/glibc-2.26-r7 | `hardened -audit -caps -debug -doc -gd -headers-only (-multilib) -nscd (-profile) (-selinux) -suid -systemtap (-vanilla)`
sys-libs/timezone-data-2018e | `nls -leaps`
**FROM kubler/busybox** |
sys-apps/busybox-1.29.0 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
