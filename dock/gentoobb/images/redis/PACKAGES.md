### gentoobb/redis:20150108
Built: Mon Jan 12 00:04:46 CET 2015

Image Size: 11.34 MB
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
dev-lang/execline-1.3.1.1 | `-static-libs`
dev-libs/skalibs-1.6.0.0 | `-doc -static-libs`
sys-apps/s6-1.1.3.2 | ``
*manual install*: entr-2.9 | http://entrproject.org/
**FROM gentoobb/glibc** |
sys-libs/glibc-2.19-r1 | `hardened -debug -gd (-multilib) -nscd -profile (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2014i-r1 | `nls -right`
#### Purged
- [x] Headers
- [x] Static Libs
