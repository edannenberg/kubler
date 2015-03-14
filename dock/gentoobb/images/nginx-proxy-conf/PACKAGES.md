### gentoobb/nginx-proxy-conf:20150312
Built: Sun Mar 15 00:05:02 CET 2015

Image Size: 17.74 MB
#### Installed
Package | USE Flags
--------|----------
dev-lang/execline-2.0.2.1 | `-static -static-libs`
dev-libs/skalibs-2.3.0.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.1.1.1 | `-static`
*manual install*: entr-2.9 | http://entrproject.org/
*manual install*: docker-gen-0.3.2 | http://github.com/jwilder/docker-gen/
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/glibc** |
sys-libs/glibc-2.19-r1 | `hardened -debug -gd (-multilib) -nscd -profile (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2014j | `nls -right`

#### Purged
- [x] Headers
- [x] Static Libs
