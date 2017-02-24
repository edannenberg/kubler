#
# build config
#
_packages=""
CLOJURE_VERSION=1.9.0-alpha15

configure_bob() {
    wget https://repo1.maven.org/maven2/org/clojure/clojure/${CLOJURE_VERSION}/clojure-${CLOJURE_VERSION}.jar
    #wget https://repo1.maven.org/maven2/org/clojure/clojure/${CLOJURE_VERSION}/clojure-${CLOJURE_VERSION}.jar.md5
    #md5sum -c clojure-${CLOJURE_VERSION}.jar.md5 || die "error validating clojure-${CLOJURE_VERSION}.jar"
}

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    init_docs "kubler/clojure"
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    mkdir -p "${_EMERGE_ROOT}/opt/"
    mv "/clojure-${CLOJURE_VERSION}.jar" "${_EMERGE_ROOT}/opt/clojure.jar"
    log_as_installed "manual install" "clojure-${CLOJURE_VERSION}" "http://clojure.org/"
}
