### gentoobb/docker-registry:20141204
Built: Fri Dec 19 22:09:54 CET 2014

Image Size: 127.9 MB
#### Installed
Package | USE Flags
--------|----------
app-arch/xz-utils-5.0.5-r1 | `nls threads -static-libs`
dev-libs/libev-4.15-r1 | `-static-libs`
dev-python/backports-1.0 | ` `
dev-python/backports-lzma-0.0.3 | ` `
dev-python/blinker-1.3 | `-doc {-test}`
dev-python/boto-2.27.0 | ` `
dev-python/chardet-2.2.1 | ` `
dev-python/flask-0.10.1-r1 | `-examples {-test}`
dev-python/flask-cors-1.9.0 | `-doc {-test}`
dev-python/gevent-1.0 | `-doc -examples`
dev-python/greenlet-0.4.2 | `-doc`
dev-python/itsdangerous-0.24 | ` `
dev-python/jinja-2.7.3 | `-doc -examples`
dev-python/markupsafe-0.23 | ` `
dev-python/pyasn1-0.1.7 | `-doc`
dev-python/pyyaml-3.11 | `-examples -libyaml`
dev-python/redis-py-2.10.3 | `{-test}`
dev-python/requests-2.3.0 | ` `
dev-python/rsa-3.1.1 | `{-test}`
dev-python/simplejson-3.6.4 | ` `
dev-python/six-1.6.1 | `-doc {-test}`
dev-python/sqlalchemy-0.9.2 | `sqlite -doc -examples {-test}`
dev-python/werkzeug-0.9.4 | ` `
net-dns/c-ares-1.10.0-r1 | `-static-libs`
*pip install*: gunicorn | http://gunicorn.org/
*manual install*: docker-registry-0.9.0 | http://github.com/docker/docker-registry/
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/images/python2** |
app-admin/eselect-python-20111108 | ``
app-admin/python-updater-0.11 | ``
app-arch/bzip2-1.0.6-r6 | `-static -static-libs`
app-misc/mime-types-9 | ``
dev-db/sqlite-3.8.6 | `readline -debug -doc -icu -secure-delete -static-libs -tcl {-test}`
dev-lang/python-2.7.7 | `readline sqlite ssl threads (wide-unicode) xml -berkdb -build -doc -examples -gdbm -hardened -ipv6 -ncurses -tk -wininst`
dev-lang/python-exec-2.0.1-r1 | ` `
dev-libs/expat-2.1.0-r3 | `unicode -examples -static-libs`
dev-libs/libffi-3.0.13-r1 | `-debug -pax`
dev-python/pip-1.5.6 | ` `
dev-python/setuptools-7.0 | `{-test}`
**FROM gentoobb/images/bash** |
app-admin/eselect-1.4.3 | `-doc -emacs -vim-syntax`
app-shells/bash-4.2_p53 | `net nls (readline) -afs -bashlogger -examples -mem-scramble -plugins -vanilla`
net-misc/curl-7.39.0 | `ssl threads -adns -idn -ipv6 -kerberos -ldap -metalink -rtmp -ssh -static-libs {-test}`
sys-apps/file-5.19 | `zlib -python -static-libs`
sys-apps/sed-4.2.1-r1 | `acl nls (-selinux) -static`
sys-libs/ncurses-5.9-r3 | `cxx unicode -ada -debug -doc -gpm -minimal -profile -static-libs -tinfo -trace`
sys-libs/readline-6.2_p5-r1 | `-static-libs`
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
