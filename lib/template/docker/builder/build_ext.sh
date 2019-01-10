#
# Kubler build container config, pick installed packages and/or customize the build
#

#
# This hook can be used to configure the build container itself, install packages, run any command, etc
#
configure_builder() {
    # Useful helpers

    # Update a Gentoo package use flag..
    #update_use 'dev-libs/some-lib' '+feature' '-some_other_feature'

    # ..or a Gentoo package keyword
    #update_keywords 'dev-lang/some-package' '+~amd64'

    # Download file at url to /distfiles if it doesn't exist yet, file name is derived from last url fragment
    #download_file "$url"
    #echo "${__download_file}"
    # Same as above but set a custom file name
    #download_file "$url" my_file_v1.tar.gz
    # Same as above but pass arbitrary additional args to curl
    #download_file "$url" my_file_v1.tar.gz '-v' '--cookie' 'foo'
    :
}
