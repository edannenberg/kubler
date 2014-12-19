### gentoobb/nginx:20141204
Built: Fri Dec 19 22:19:19 CET 2014

Image Size: 19.68 MB
#### Installed
Package | USE Flags
--------|----------
app-arch/bzip2-1.0.6-r6 | `-static -static-libs`
dev-libs/libpcre-8.35 | `bzip2 cxx jit recursion-limit (unicode) zlib -libedit -pcre16 -pcre32 -readline -static-libs`
www-servers/nginx-1.7.6 | `http http-cache pcre ssl -aio -debug -ipv6 -libatomic -luajit -pcre-jit -rtmp (-selinux) -vim-syntax`
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/images/openssl** |
app-misc/ca-certificates-20130906-r1 | ``
dev-libs/openssl-1.0.1j | `bindist (sse2) tls-heartbeat zlib -gmp -kerberos -rfc3779 -static-libs {-test} -vanilla`
sys-apps/acl-2.2.52-r1 | `nls -static-libs`
sys-apps/attr-2.4.47-r1 | `nls -static-libs`
sys-apps/coreutils-8.21 | `acl nls -caps -gmp (-selinux) -static -vanilla -xattr`
sys-apps/debianutils-4.4 | `-static`
sys-libs/zlib-1.2.8-r1 | `-minizip -static-libs`
**FROM gentoobb/images/s6** |
dev-lang/execline-1.3.1.1 | `-static-libs`
dev-libs/skalibs-1.6.0.0 | `-doc -static-libs`
sys-apps/s6-1.1.3.2 | ``
*manual install*: entr-2.9 | http://entrproject.org/
**FROM gentoobb/images/glibc** |
sys-libs/glibc-2.19-r1 | `-debug -gd (-hardened) (-multilib) -nscd -profile (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2014i-r1 | `nls -right`
#### Purged
- [x] Headers
- [x] Static Libs
