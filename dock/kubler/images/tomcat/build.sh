#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="dev-libs/apr dev-java/tomcat-native www-servers/tomcat"

configure_bob()
{
    # build tomcat-native package on the host
    unprovide_package dev-java/java-config app-eselect/eselect-java app-arch/zip
    emerge dev-java/oracle-jdk-bin
    emerge dev-java/ant-core dev-java/ant-junit dev-java/java-config dev-java/tomcat-native www-servers/tomcat
}


#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    provide_package dev-java/java-config app-eselect/eselect-java
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
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
