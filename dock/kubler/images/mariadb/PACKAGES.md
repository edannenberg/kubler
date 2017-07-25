### kubler/mariadb:20170723

Built: Sun Jul 23 15:49:17 CEST 2017
Image Size: 266MB

#### Installed
Package | USE Flags
--------|----------
app-admin/perl-cleaner-2.25 | ``
app-arch/bzip2-1.0.6-r8 | `-static -static-libs`
app-arch/libarchive-3.3.1 | `acl bzip2 e2fsprogs iconv lzma threads xattr zlib -expat (-libressl) -lz4 -lzo -nettle -static-libs`
app-arch/pbzip2-1.1.12 | `-static -symlink`
app-arch/xz-utils-5.2.3 | `nls threads -static-libs`
dev-db/mariadb-10.1.24 | `backup bindist cracklib openssl perl server -debug -embedded -extraengine -galera -innodb-lz4 -innodb-lzo -innodb-snappy -jdbc -jemalloc -kerberos -latin1 (-libressl) (-mroonga) -odbc -oqgraph -pam -profiling (-selinux) -sphinx -sst-rsync -sst-xtrabackup -static -static-libs -systemd -systemtap -tcmalloc {-test} -tokudb -xml -yassl`
dev-db/mysql-init-scripts-2.1-r1 | ``
dev-lang/perl-5.24.1-r2 | `berkdb -debug -doc -gdbm -ithreads`
dev-libs/libaio-0.3.110 | `-static-libs {-test}`
dev-libs/libpcre-8.40-r1 | `bzip2 cxx readline recursion-limit (unicode) zlib -jit -libedit -pcre16 -pcre32 -static-libs`
dev-libs/libxml2-2.9.4-r1 | `readline -debug -examples -icu -ipv6 -lzma -python -static-libs {-test}`
dev-perl/DBD-mysql-4.41.0 | `ssl -embedded {-test}`
dev-perl/DBI-1.636.0 | `-examples {-test}`
dev-perl/libintl-perl-1.240.0-r2 | ``
dev-perl/Net-Daemon-0.480.0-r1 | ``
dev-perl/PlRPC-0.202.0-r2 | ``
dev-perl/TermReadKey-2.330.0 | ``
dev-perl/Text-Unidecode-1.270.0 | ``
dev-perl/Unicode-EastAsianWidth-1.330.0-r1 | ``
perl-core/File-Path-2.130.0 | ``
perl-core/File-Temp-0.230.400-r1 | ``
sys-apps/texinfo-6.3 | `nls -static`
sys-libs/cracklib-2.9.6-r1 | `nls zlib -python -static-libs`
sys-libs/db-5.3.28-r2 | `cxx -doc -examples -java -tcl {-test}`
sys-process/procps-3.3.12 | `kill nls unicode -modern-top -ncurses (-selinux) -static-libs -systemd {-test}`
*manual install*: automysqlbackup-3.0_rc6 | https://sourceforge.net/projects/automysqlbackup/
#### Inherited
Package | USE Flags
--------|----------
**FROM kubler/bash** |
app-admin/eselect-1.4.8 | `-doc -emacs -vim-syntax`
app-portage/portage-utils-0.62 | `nls -static`
app-shells/bash-4.3_p48-r1 | `net nls (readline) -afs -bashlogger -examples -mem-scramble -plugins`
dev-libs/iniparser-3.1-r1 | `-doc -examples -static-libs`
net-misc/curl-7.54.1 | `ssl threads -adns -http2 -idn -ipv6 -kerberos -ldap -metalink -rtmp -samba -ssh -static-libs {-test}`
sys-apps/acl-2.2.52-r1 | `nls -static-libs`
sys-apps/attr-2.4.47-r2 | `nls -static-libs`
sys-apps/coreutils-8.25 | `acl nls (xattr) -caps -gmp -hostname -kill -multicall (-selinux) -static -vanilla`
sys-apps/file-5.30 | `zlib -python -static-libs`
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
dev-lang/execline-2.3.0.1 | `-static -static-libs`
dev-libs/skalibs-2.5.1.1 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.5.1.0 | `-static -static-libs`
*manual install*: entr-3.6 | http://entrproject.org/
**FROM kubler/glibc** |
sys-apps/gentoo-functions-0.10 | ``
sys-libs/glibc-2.23-r4 | `hardened rpc -audit -caps -debug -gd (-multilib) -nscd (-profile) (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2017a | `nls -leaps`
**FROM kubler/busybox** |
sys-apps/busybox-1.25.1 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
