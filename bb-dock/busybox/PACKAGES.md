### gentoobb/busybox:20141127
Built: Fri Nov 28 14:07:27 CET 2014
Image Size: 15.25 MB
#### Installed
Package | USE Flags
--------|----------
sys-apps/busybox-1.21.0 | `ipv6 make-symlinks pam -livecd -math -mdev -savedconfig (-selinux) -sep-usr -static -syslog -systemd`
sys-auth/pambase-20120417-r3 | `cracklib sha512 -consolekit -debug -gnome-keyring -minimal -mktemp -pam`
sys-libs/cracklib-2.9.1-r1 | `nls zlib -python -static-libs {-test}`
sys-libs/db-4.8.30-r1 | `cxx -doc -examples -java -tcl {-test}`
sys-libs/glibc-2.19-r1 | `-debug -gd (-hardened) (-multilib) -nscd -profile (-selinux) -suid -systemtap -vanilla`
sys-libs/pam-1.1.8-r2 | `berkdb cracklib nls -audit -debug -nis (-selinux) {-test} -vim-syntax`
sys-libs/timezone-data-2014i-r1 | `nls -right`
sys-libs/zlib-1.2.8-r1 | `-minizip -static-libs`
#### Inherited
Package | USE Flags
--------|----------
**FROM scratch** |
#### Purged
- [x] Headers
- [x] Static Libs
- [x] Glibc Iconv Encodings
