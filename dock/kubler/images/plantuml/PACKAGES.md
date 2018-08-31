### kubler/plantuml:20180831

Built: Fri Aug 31 18:49:33 CEST 2018
Image Size: 218MB

#### Installed
Package | USE Flags
--------|----------
dev-libs/glib-2.52.3 | `mime xattr -dbus -debug (-fam) (-selinux) -static-libs -systemtap {-test} -utils`
dev-libs/libffi-3.2.1 | `-debug -pax`
dev-libs/libltdl-2.4.6 | `-static-libs`
dev-libs/libpcre-8.41-r1 | `bzip2 cxx readline recursion-limit (unicode) zlib -jit -libedit -pcre16 -pcre32 -static-libs`
dev-libs/libxml2-2.9.8 | `readline -debug -examples -icu -ipv6 -lzma -python -static-libs {-test}`
media-gfx/graphviz-2.40.1-r1 | `nls -`
media-libs/gd-2.2.5 | `fontconfig jpeg png truetype zlib -static-libs -tiff -webp -xpm`
media-libs/libjpeg-turbo-1.5.3-r2 | `-java -static-libs`
media-libs/libpng-1.6.34 | `-apng (-neon) -static-libs`
x11-misc/shared-mime-info-1.9 | `{-test}`
*manual install*: plantuml-server-v1.2018.10 | https://github.com/plantuml/plantuml-server
#### Inherited
Package | USE Flags
--------|----------
**FROM kubler/tomcat** |
dev-java/ant-core-1.9.2 | `-doc -source`
dev-java/ant-eclipse-ecj-4.5.1 | `-doc -source`
dev-java/eclipse-ecj-4.5.1 | `ant -doc -source`
dev-java/tomcat-native-1.2.16 | `-static-libs {-test}`
dev-java/tomcat-servlet-api-9.0.7 | `-source`
dev-libs/apr-1.5.2 | `urandom -doc -older-kernels-compatibility (-selinux) -static-libs`
www-servers/tomcat-9.0.7 | `-doc -extra-webapps -source {-test}`
**FROM kubler/jre-oracle** |
app-arch/bzip2-1.0.6-r10 | `-static -static-libs`
app-eselect/eselect-fontconfig-1.1 | ``
app-eselect/eselect-java-0.4.0 | ``
dev-java/java-config-2.2.0-r4 | `{-test}`
dev-java/oracle-jre-bin-1.8.0.181 | `fontconfig headless-awt jce -alsa -commercial -cups -javafx -nsplugin (-selinux)`
dev-libs/expat-2.2.5 | `unicode -examples -static-libs`
media-fonts/liberation-fonts-2.00.1-r3 | `-`
media-libs/fontconfig-2.13.0-r4 | `-doc -static-libs`
media-libs/freetype-2.9.1-r3 | `adobe-cff bindist bzip2 cleartype`
sys-apps/baselayout-java-0.1.0 | ``
sys-apps/util-linux-2.32-r4 | `cramfs nls readline suid unicode -build -caps -fdformat -kill -ncurses -pam -python (-selinux) -slang -static-libs -systemd {-test} -tty-helpers -udev`
**FROM kubler/bash** |
app-admin/eselect-1.4.12 | `-doc -emacs -vim-syntax`
app-portage/portage-utils-0.64 | `nls -static`
app-shells/bash-4.4_p12 | `net nls (readline) -afs -bashlogger -examples -mem-scramble -plugins`
dev-libs/iniparser-3.1-r1 | `-doc -examples -static-libs`
net-misc/curl-7.61.0 | `ssl threads -adns -brotli -http2 -idn -ipv6 -kerberos -ldap -metalink -rtmp -samba -ssh -static-libs {-test}`
sys-apps/acl-2.2.52-r1 | `nls -static-libs`
sys-apps/attr-2.4.47-r2 | `nls -static-libs`
sys-apps/coreutils-8.29-r1 | `acl nls split-usr (xattr) -caps -gmp -hostname -kill -multicall (-selinux) -static {-test} -vanilla`
sys-apps/file-5.33-r4 | `zlib -python -static-libs`
sys-apps/sed-4.5 | `acl nls -forced-sandbox (-selinux) -static`
sys-libs/ncurses-6.1-r2 | `cxx minimal threads unicode -ada -debug -doc -gpm (-profile) -static-libs {-test} -tinfo -trace`
sys-libs/readline-7.0_p3 | `-static-libs -utils`
**FROM kubler/openssl** |
app-misc/ca-certificates-20170717.3.36.1 | `-cacert -insecure`
app-misc/c_rehash-1.7-r1 | ``
dev-libs/openssl-1.0.2o-r3 | `asm sslv3 tls-heartbeat zlib -bindist -gmp -kerberos -rfc3779 -sctp -sslv2 -static-libs {-test} -vanilla`
sys-apps/debianutils-4.8.3 | `-static`
sys-libs/zlib-1.2.11-r2 | `-minizip -static-libs`
**FROM kubler/s6** |
app-admin/entr-4.1 | `{-test}`
dev-lang/execline-2.3.0.4 | `-static -static-libs`
dev-libs/skalibs-2.6.4.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.7.1.1 | `-static -static-libs`
**FROM kubler/glibc** |
sys-apps/gentoo-functions-0.12 | ``
sys-libs/glibc-2.26-r7 | `hardened -audit -caps -debug -doc -gd -headers-only (-multilib) -nscd (-profile) (-selinux) -suid -systemtap (-vanilla)`
sys-libs/timezone-data-2018e | `nls -leaps`
**FROM kubler/busybox** |
sys-apps/busybox-1.29.0 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
