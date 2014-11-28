### gentoobb/nginx:20141127
Built: Fri Nov 28 14:17:34 CET 2014
Image Size: 26.29 MB
#### Installed
Package | USE Flags
--------|----------
app-arch/bzip2-1.0.6-r6 | `-static -static-libs`
dev-libs/libpcre-8.35 | `bzip2 cxx jit recursion-limit (unicode) zlib -libedit -pcre16 -pcre32 -readline -static-libs`
www-servers/nginx-1.7.6 | `http http-cache ipv6 pcre ssl -aio -debug -libatomic -luajit -pcre-jit -rtmp (-selinux) -vim-syntax`
#### Inherited
Package | USE Flags
--------|----------
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
