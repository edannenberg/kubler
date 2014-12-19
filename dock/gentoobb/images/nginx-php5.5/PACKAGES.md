### gentoobb/nginx-php5.5:20141204
Built: Fri Dec 19 22:55:48 CET 2014

Image Size: 80.11 MB
#### Installed
Package | USE Flags
--------|----------
app-admin/eselect-1.4.3 | `-doc -emacs -vim-syntax`
app-admin/eselect-php-0.7.1-r3 | `fpm -apache2`
app-admin/metalog-3-r1 | `unicode`
dev-lang/php-5.5.18 | `bcmath berkdb bzip2 calendar cli crypt ctype curl fileinfo filter fpm gd hash iconv json mhash mysql mysqli nls opcache pdo phar posix readline session simplexml soap sockets ssl threads tokenizer unicode xml xmlreader xmlrpc xmlwriter xpm zip zlib -apache2 -cdb -cgi -cjk -debug -embed -enchant -exif (-firebird) -flatfile (-frontbase) -ftp -gdbm -gmp -imap -inifile -intl -iodbc -ipv6 -kerberos -ldap -ldap-sasl -libedit -libmysqlclient -mssql -oci8-instant-client -odbc -pcntl -postgres -qdbm -recode (-selinux) -sharedmem -snmp -spell -sqlite (-sybase-ct) -systemd -sysvipc -tidy -truetype -vpx -wddx -xslt`
dev-libs/expat-2.1.0-r3 | `unicode -examples -static-libs`
dev-libs/gmp-5.1.3-r1 | `cxx -doc -pgo -static-libs`
dev-libs/libmcrypt-2.5.8-r2 | ``
dev-libs/libpthread-stubs-0.3-r1 | `-static-libs`
dev-libs/libtasn1-3.6 | `-doc -static-libs`
dev-libs/libxml2-2.9.2 | `readline -debug -examples -icu -ipv6 -lzma -python -static-libs {-test}`
dev-libs/nettle-2.7.1-r1 | `gmp -doc (-neon) -static-libs {-test}`
dev-libs/oniguruma-5.9.5 | `-combination-explosion-check -crnl-as-line-terminator -static-libs`
dev-php/pecl-apcu-4.0.1-r1 | `lock`
dev-php/pecl-memcache-3.0.8 | `session`
dev-php/pecl-redis-2.2.3 | `-igbinary`
dev-php/xdebug-2.2.3 | ` `
dev-php/xdebug-client-2.2.3 | `-libedit`
mail-mta/nullmailer-1.13-r4 | `ssl`
media-libs/libjpeg-turbo-1.3.1 | `-java -static-libs`
media-libs/libpng-1.6.15 | `-apng (-neon) -static-libs`
net-libs/gnutls-2.12.23-r6 | `bindist cxx nettle nls zlib -doc -examples -guile -lzo -pkcs11 -static-libs {-test}`
net-misc/curl-7.39.0 | `ssl threads -adns -idn -ipv6 -kerberos -ldap -metalink -rtmp -ssh -static-libs {-test}`
sys-apps/file-5.19 | `zlib -python -static-libs`
sys-apps/sed-4.2.1-r1 | `acl nls (-selinux) -static`
sys-apps/shadow-4.1.5.1-r1 | `acl cracklib nls -audit -pam (-selinux) -skey -xattr`
sys-apps/util-linux-2.24.1-r3 | `cramfs nls suid unicode -bash-completion -caps -cytune -fdformat -ncurses -pam -python (-selinux) -slang -static-libs {-test} -tty-helpers -udev`
sys-devel/gettext-0.18.3.2 | `acl cxx nls openmp -cvs -doc -emacs -git -java -ncurses -static-libs`
sys-libs/cracklib-2.9.1-r1 | `nls zlib -python -static-libs {-test}`
sys-libs/db-4.8.30-r2 | `cxx -doc -examples -java -tcl {-test}`
sys-libs/ncurses-5.9-r3 | `cxx unicode -ada -debug -doc -gpm -minimal -profile -static-libs -tinfo -trace`
sys-libs/readline-6.2_p5-r1 | `-static-libs`
x11-libs/libICE-1.0.8-r1 | `-doc -ipv6 -static-libs`
x11-libs/libSM-1.2.2-r1 | `uuid -doc -ipv6 -static-libs`
x11-libs/libX11-1.6.2 | `-doc -ipv6 -static-libs {-test}`
x11-libs/libXau-1.0.8 | `-static-libs`
x11-libs/libXdmcp-1.1.1-r1 | `-doc -static-libs`
x11-libs/libXext-1.3.2 | `-doc -static-libs`
x11-libs/libXpm-3.5.11 | `-static-libs`
x11-libs/libXt-1.1.4 | `-static-libs`
x11-libs/libxcb-1.10 | `-doc (-selinux) -static-libs -xkb`
x11-libs/xtrans-1.3.3 | `-doc`
x11-proto/inputproto-2.3 | ``
x11-proto/kbproto-1.0.6-r1 | ``
x11-proto/xextproto-7.3.0 | `-doc`
x11-proto/xf86bigfontproto-1.2.0-r1 | ``
x11-proto/xproto-7.0.25 | `-doc`
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/images/nginx** |
app-arch/bzip2-1.0.6-r6 | `-static -static-libs`
dev-libs/libpcre-8.35 | `bzip2 cxx jit recursion-limit (unicode) zlib -libedit -pcre16 -pcre32 -readline -static-libs`
www-servers/nginx-1.7.6 | `http http-cache pcre ssl -aio -debug -ipv6 -libatomic -luajit -pcre-jit -rtmp (-selinux) -vim-syntax`
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
