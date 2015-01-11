### gentoobb/s6:20150108
Built: Sun Jan 11 22:56:54 CET 2015

Image Size: 9.8 MB
#### Installed
Package | USE Flags
--------|----------
dev-lang/execline-1.3.1.1 | `-static-libs`
dev-libs/skalibs-1.6.0.0 | `-doc -static-libs`
sys-apps/s6-1.1.3.2 | ``
*manual install*: entr-2.9 | http://entrproject.org/
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/glibc** |
sys-libs/glibc-2.19-r1 | `hardened -debug -gd (-multilib) -nscd -profile (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2014i-r1 | `nls -right`

#### Purged
- [x] Headers
- [x] Static Libs
