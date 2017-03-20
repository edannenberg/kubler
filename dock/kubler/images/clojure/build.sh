#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages=""
_clojure_version=1.9.0-alpha15

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    init_docs "kubler/clojure"
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    wget "https://repo1.maven.org/maven2/org/clojure/clojure/${_clojure_version}/clojure-${_clojure_version}.jar"
    mkdir -p "${_EMERGE_ROOT}"/opt/
    mv "/clojure-${_clojure_version}.jar" "${_EMERGE_ROOT}"/opt/clojure.jar
    log_as_installed "manual install" "clojure-${_clojure_version}" "http://clojure.org/"
}
