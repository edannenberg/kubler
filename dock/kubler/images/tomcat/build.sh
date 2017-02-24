#
# build config, sourced by build-root.sh inside build container
#

# list of gentoo package atoms to be installed at custom rootfs (${_EMERGE_ROOT}), optional
# if you are not sure about package names you may want to run:
# ./bin/bob_interactive kubler/$tmpl_image_name} and then emerge -s <search-string>
_packages="dev-libs/apr dev-java/tomcat-native www-servers/tomcat"

# define custom variables to your liking
#tomcat_version=1.0

#
# this hook can be used to configure the build container itself, install packages, run any command, etc
#
configure_bob()
{
    # build tomcat-native package on the host
    unprovide_package dev-java/java-config app-eselect/eselect-java
    emerge dev-java/oracle-jdk-bin
    emerge dev-java/ant-core dev-java/ant-junit dev-java/java-config dev-java/tomcat-native www-servers/tomcat
}


#
# this hook is called in the build container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    provide_package dev-java/java-config app-eselect/eselect-java
}

#
# this hook is called in the build container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    local tomcat_path catalina cata_conf tomcat_deps gentoo_classpath
    tomcat_path="${_EMERGE_ROOT}"/usr/share/tomcat-8
    catalina="${tomcat_path}"/bin/catalina.sh
    cata_conf="${tomcat_path}"/conf/catalina.properties

    mkdir -p "${_EMERGE_ROOT}"/etc/init.d

    # adapted from Gentoo's Tomcat init.d script
    tomcat_deps="$(java-config --query DEPEND --package tomcat-8)"
    tomcat_deps=${tomcat_deps%:}

    gentoo_classpath="$(java-config --with-dependencies --classpath "${tomcat_deps//:/,}")"
    gentoo_classpath=${gentoo_classpath%:}

    sed -i "s|CLASSPATH=\`java-config --classpath tomcat-8\`|CLASSPATH=`java-config --with-dependencies --classpath tomcat-8,tomcat-native`|g" "${catalina}"
    sed -i "s|\${gentoo\.classpath}|${gentoo_classpath//:/,}|g" "${cata_conf}"
}
