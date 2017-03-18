### kubler/mariadb:20170318

Built: Sat Mar 18 07:32:43 CET 2017
Image Size: 236 MB

#### Installed
Package | USE Flags
--------|----------
app-admin/perl-cleaner-2.20 | ``
app-arch/bzip2-1.0.6-r7 | `-static -static-libs`
app-arch/pbzip2-1.1.12 | `-static -symlink`
dev-db/mariadb-10.0.29 | `bindist openssl perl server -debug -embedded -extraengine -jdbc -jemalloc -latin1 (-libressl) -odbc -oqgraph -pam -profiling (-selinux) -sphinx -static -static-libs -systemtap -tcmalloc {-test} -tokudb -xml -yassl`
dev-db/mysql-init-scripts-2.1-r1 | ``
dev-lang/perl-5.22.3_rc4 | `berkdb -debug -doc -gdbm -ithreads`
dev-libs/libaio-0.3.110 | `-static-libs {-test}`
dev-libs/libpcre-8.39 | `bzip2 cxx readline recursion-limit (unicode) zlib -jit -libedit -pcre16 -pcre32 -static-libs`
dev-perl/DBD-mysql-4.41.0 | `ssl -embedded {-test}`
dev-perl/DBI-1.636.0 | `-examples {-test}`
dev-perl/libintl-perl-1.240.0 | ``
dev-perl/Net-Daemon-0.480.0-r1 | ``
dev-perl/PlRPC-0.202.0-r2 | ``
dev-perl/TermReadKey-2.330.0 | ``
dev-perl/Text-Unidecode-1.270.0 | ``
dev-perl/Unicode-EastAsianWidth-1.330.0-r1 | ``
perl-core/File-Temp-0.230.400-r1 | ``
sys-apps/texinfo-6.1 | `nls -static`
sys-libs/db-5.3.28-r2 | `cxx -doc -examples -java -tcl {-test}`
sys-process/procps-3.3.12 | `kill nls unicode -modern-top -ncurses (-selinux) -static-libs -systemd {-test}`
*manual install*: automysqlbackup-3.0_rc6 | https://sourceforge.net/projects/automysqlbackup/
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
