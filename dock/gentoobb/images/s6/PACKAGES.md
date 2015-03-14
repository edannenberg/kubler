### gentoobb/s6:20150312
Built: Sat Mar 14 23:35:05 CET 2015

Image Size: 10.01 MB
#### Installed
Package | USE Flags
--------|----------
dev-lang/execline-2.0.2.1 | `-static -static-libs`
dev-libs/skalibs-2.3.0.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.1.1.1 | `-static`
*manual install*: entr-2.9 | http://entrproject.org/
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/glibc** |
sys-libs/glibc-2.19-r1 | `hardened -debug -gd (-multilib) -nscd -profile (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2014j | `nls -right`

#### Purged
- [x] Headers
- [x] Static Libs
