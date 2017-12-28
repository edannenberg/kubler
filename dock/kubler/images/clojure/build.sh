#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages=""
_clojure_version=1.9.0

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
    # clojure
    wget "https://repo1.maven.org/maven2/org/clojure/clojure/${_clojure_version}/clojure-${_clojure_version}.jar"
    mkdir -p "${_EMERGE_ROOT}"/opt/
    mv "/clojure-${_clojure_version}.jar" "${_EMERGE_ROOT}"/opt/clojure.jar
    log_as_installed "manual install" "clojure-${_clojure_version}" "http://clojure.org/"

    mkdir -p "${_EMERGE_ROOT}"/usr/local/bin
    # boot
    local boot_path lein_path
    boot_path="${_EMERGE_ROOT}"/usr/local/bin/boot
    curl -fsSLo "${boot_path}" https://github.com/boot-clj/boot-bin/releases/download/latest/boot.sh
    chmod 755 "${boot_path}"
    log_as_installed "manual install" "boot-latest" "https://github.com/boot-clj/boot"
    # leiningen
    lein_path="${_EMERGE_ROOT}"/usr/local/bin/lein
    curl -fsSLo "${lein_path}"  https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
    chmod 755 "${lein_path}"
    log_as_installed "manual install" "lein-latest" "https://leiningen.org/"
}
