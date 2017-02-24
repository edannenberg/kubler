#
# build config, sourced by build-root.sh inside build container
#

# list of gentoo package atoms to be installed at custom rootfs (${_EMERGE_ROOT}), optional
# if you are not sure about package names you may want to run:
# kubler build -i kubler/plant-uml and then emerge -s <search-string>
_packages="media-gfx/graphviz"

# define custom variables to your liking
#plant-uml_version=1.0

#
# this hook can be used to configure the build container itself, install packages, run any command, etc
#
configure_bob()
{
    unprovide_package dev-java/javatoolkit
    update_use 'media-libs/gd' '+jpeg' '+png +fontconfig +truetype'
    update_use media-gfx/graphviz '-cairo'
    emerge -v java-virtuals/servlet-api:3.0 dev-java/maven-bin media-gfx/graphviz
    # build plantuml
    git clone https://github.com/plantuml/plantuml-server.git
    cd plantuml-server/
    mvn package
    mkdir -p "${_EMERGE_ROOT}"/var/lib/tomcat-8-local/webapps/
    cp target/plantuml.war "${_EMERGE_ROOT}"/var/lib/tomcat-8-local/webapps/
    chown tomcat:tomcat "${_EMERGE_ROOT}"/var/lib/tomcat-8-local/webapps/plantuml.war
}


#
# this hook is called in the build container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    :
}

#
# this hook is called in the build container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    find /usr/lib64/gcc -name libgcc_s.so.1 -exec cp {} "${_EMERGE_ROOT}"/usr/lib64/ \;
}
