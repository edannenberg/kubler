### gentoobb/log-collector:20150709
Built: Sat Jul 18 20:39:55 CEST 2015

Image Size: 181.2 MB
#### Installed
Package | USE Flags
--------|----------
*gem install*: fluentd | --no-ri --no-rdoc
*gem install*: fluent-plugin-elasticsearch | --no-ri --no-rdoc
*manual install*: docker-gen-0.4.0 | http://github.com/jwilder/docker-gen/
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/ruby-gcc** |
app-eselect/eselect-ruby-20141227 | ``
dev-lang/ruby-2.2.2-r1 | `berkdb rdoc readline ssl -debug -doc -examples -gdbm -ipv6 -jemalloc -ncurses -rubytests -socks5 -xemacs`
dev-libs/libffi-3.0.13-r1 | `pax`
dev-libs/libyaml-0.1.6 | `-doc -examples -static-libs {-test}`
dev-ruby/json-1.8.3 | `-doc {-test}`
dev-ruby/minitest-5.5.1 | `-doc {-test}`
dev-ruby/power_assert-0.2.2 | `-doc {-test}`
dev-ruby/rake-10.4.2 | `-doc {-test}`
dev-ruby/rdoc-4.1.2 | `-doc {-test}`
dev-ruby/rubygems-2.4.6 | `-server {-test}`
dev-ruby/test-unit-3.0.9-r1 | `-doc {-test}`
sys-libs/db-4.8.30-r2 | `cxx -doc -examples -java -tcl {-test}`
**FROM gentoobb/gcc** |
dev-libs/gmp-5.1.3-r1 | `cxx -doc -pgo -static-libs`
dev-libs/mpc-1.0.2-r1 | `-static-libs`
dev-libs/mpfr-3.1.2_p10 | `-static-libs`
sys-devel/binutils-2.24-r3 | `cxx nls zlib (-multislot) -multitarget -static-libs {-test} -vanilla`
sys-devel/binutils-config-4-r2 | ``
sys-devel/gcc-4.8.4 | `cxx hardened nls nptl openmp (-altivec) (-awt) -debug -doc (-fixed-point) -fortran -gcj -go -graphite (-libssp) -mudflap (-multilib) (-multislot) -nopie -nossp -objc -objc`
sys-devel/gcc-config-1.7.3 | ``
sys-devel/make-4.1-r1 | `nls -guile -static`
sys-kernel/linux-headers-3.18 | ``
**FROM gentoobb/bash** |
app-admin/eselect-1.4.4 | `-doc -emacs -vim-syntax`
app-portage/portage-utils-0.56 | `nls -static`
app-shells/bash-4.3_p33-r2 | `net nls (readline) -afs -bashlogger -examples -mem-scramble -plugins -vanilla`
dev-libs/iniparser-3.1-r1 | `-doc -examples -static-libs`
net-misc/curl-7.43.0 | `ssl threads -adns (-http2) -idn -ipv6 -kerberos -ldap -metalink -rtmp -samba -ssh -static-libs {-test}`
sys-apps/file-5.22 | `zlib -python -static-libs`
sys-apps/sed-4.2.1-r1 | `acl nls (-selinux) -static`
sys-libs/ncurses-5.9-r3 | `cxx unicode -ada -debug -doc -gpm -minimal -profile -static-libs -tinfo -trace`
sys-libs/readline-6.3_p8-r2 | `-static-libs -utils`
**FROM gentoobb/openssl** |
app-misc/ca-certificates-20140927.3.17.2 | `cacert`
dev-libs/openssl-1.0.1p | `bindist tls-heartbeat zlib -gmp -kerberos -rfc3779 -static-libs {-test} -vanilla`
sys-apps/acl-2.2.52-r1 | `nls -static-libs`
sys-apps/attr-2.4.47-r1 | `nls -static-libs`
sys-apps/coreutils-8.23 | `acl nls (xattr) -caps -gmp -multicall (-selinux) -static -vanilla`
sys-apps/debianutils-4.4 | `-static`
sys-libs/zlib-1.2.8-r1 | `-minizip -static-libs`
**FROM gentoobb/s6** |
dev-lang/execline-2.1.1.0 | `-static -static-libs`
dev-libs/skalibs-2.3.2.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.1.3.0 | `-static`
*manual install*: entr-3.2 | http://entrproject.org/
**FROM gentoobb/glibc** |
sys-apps/gentoo-functions-0.8 | ``
sys-libs/glibc-2.20-r2 | `hardened -debug -gd (-multilib) -nscd -profile (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2015b | `nls -right`
**FROM gentoobb/busybox** |
sys-apps/busybox-1.23.1-r1 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [ ] Headers
- [x] Static Libs

#### Included
- [x] Headers from gentoobb/bash
