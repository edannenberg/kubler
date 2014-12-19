### gentoobb/nginx-proxy-conf:20141204
Built: Fri Dec 19 22:57:40 CET 2014

Image Size: 17.28 MB
#### Installed
Package | USE Flags
--------|----------
dev-lang/execline-1.3.1.1 | `-static-libs`
dev-libs/skalibs-1.6.0.0 | `-doc -static-libs`
sys-apps/s6-1.1.3.2 | ``
*manual install*: entr-2.9 | http://entrproject.org/
*manual install*: docker-gen-0.3.2 | http://github.com/jwilder/docker-gen/
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/images/glibc** |
sys-libs/glibc-2.19-r1 | `-debug -gd (-hardened) (-multilib) -nscd -profile (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2014i-r1 | `nls -right`

#### Purged
- [x] Headers
- [x] Static Libs
