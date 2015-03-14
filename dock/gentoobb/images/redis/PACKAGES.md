### gentoobb/redis:20150312
Built: Sun Mar 15 00:10:56 CET 2015

Image Size: 11.55 MB
#### Installed
Package | USE Flags
--------|----------
dev-db/redis-2.8.17-r1 | `jemalloc -tcmalloc {-test}`
dev-lang/lua-5.1.5-r3 | `deprecated -emacs -readline -static`
dev-libs/jemalloc-3.6.0 | `-debug -static-libs -stats`
#### Inherited
Package | USE Flags
--------|----------
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
