#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="media-gfx/graphviz"
_plantuml_version='v1.2018.11'

configure_bob()
{
    unprovide_package dev-java/javatoolkit dev-java/tomcat-servlet-api media-libs/freetype media-libs/fontconfig
    update_use 'media-libs/gd' +jpeg +png +fontconfig +truetype
    update_use 'media-gfx/graphviz' -cairo
    emerge -v java-virtuals/servlet-api:3.0 dev-java/maven-bin media-gfx/graphviz
    # build plantuml
    git clone https://github.com/plantuml/plantuml-server.git
    cd plantuml-server/
    git checkout "${_plantuml_version}"
    mvn package
    mkdir -p "${_EMERGE_ROOT}"/var/lib/"${TOMCAT_SLOT}"-local/webapps/
    cp target/plantuml.war "${_EMERGE_ROOT}"/var/lib/"${TOMCAT_SLOT}"-local/webapps/
    chown tomcat:tomcat "${_EMERGE_ROOT}"/var/lib/"${TOMCAT_SLOT}"-local/webapps/plantuml.war
}

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    :
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    emerge -C dev-java/javatoolkit dev-java/tomcat-servlet-api media-libs/freetype media-libs/fontconfig
    find /usr/"${_LIB}"/gcc -name libgcc_s.so.1 -exec cp {} "${_EMERGE_ROOT}"/usr/"${_LIB}"/ \;
    log_as_installed "manual install" plantuml-server-"${_plantuml_version}" https://github.com/plantuml/plantuml-server
}
