### gentoobb/redis:20141204
Built: Fri Dec 19 23:02:34 CET 2014

Image Size: 10.57 MB
#### Installed
Package | USE Flags
--------|----------
dev-db/redis-2.6.15-r1 | `jemalloc -tcmalloc {-test}`
dev-libs/jemalloc-3.6.0 | `-debug -static-libs -stats`
#### Inherited
Package | USE Flags
--------|----------
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
