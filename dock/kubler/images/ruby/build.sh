#
# Kubler phase 1 config, pick installed packages and/or customize the build
#
_packages="dev-libs/gmp app-eselect/eselect-ruby dev-lang/ruby"

#
# This hook is called just before starting the build of the root fs
#
configure_rootfs_build()
{
    echo 'RUBY_TARGETS="ruby24"' >> /etc/portage/make.conf
    update_keywords 'dev-lang/ruby' '+~amd64'
    update_keywords '=dev-ruby/racc-1.4.14' '+~amd64'
    update_keywords '=dev-ruby/rdoc-5.1.0' '+~amd64'
    update_keywords '=dev-ruby/rubygems-2.6.8' '+~amd64'
    update_keywords '=dev-ruby/rake-12.0.0' '+~amd64'
    update_keywords '=dev-ruby/power_assert-0.4.1' '+~amd64'
    update_keywords '=dev-ruby/minitest-5.10.1' '+~amd64'
    update_keywords '=dev-ruby/test-unit-3.2.3' '+~amd64'
    update_keywords '=virtual/rubygems-12' '+~amd64'
    update_keywords '=dev-ruby/json-2.1.0' '+~amd64'
    update_keywords '=dev-ruby/net-telnet-0.1.1-r1' '+~amd64'
    update_keywords '=dev-ruby/did_you_mean-1.1.0' '+~amd64'
    update_keywords '=dev-ruby/xmlrpc-0.2.1' '+~amd64'
    update_keywords '=dev-ruby/kpeg-1.1.0' '+~amd64'
}

#
# This hook is called just before packaging the root fs tar ball, ideal for any post-install tasks, clean up, etc
#
finish_rootfs_build()
{
    :
}
