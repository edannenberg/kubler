#
# build config
#
_packages="dev-libs/gmp app-eselect/eselect-ruby dev-lang/ruby"

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    echo 'RUBY_TARGETS="ruby24"' >> /etc/portage/make.conf
    update_keywords 'dev-lang/ruby' '+~amd64'
    update_keywords '=app-eselect/eselect-ruby-20161226' '+~amd64'
    update_keywords '=dev-ruby/racc-1.4.14' '+~amd64'
    update_keywords '=dev-ruby/rdoc-5.0.0-r2' '+~amd64'
    update_keywords '=dev-ruby/rubygems-2.6.8' '+~amd64'
    update_keywords '=dev-ruby/rake-12.0.0' '+~amd64'
    update_keywords '=dev-ruby/power_assert-0.4.1' '+~amd64'
    update_keywords '=dev-ruby/minitest-5.10.1' '+~amd64'
    update_keywords '=dev-ruby/test-unit-3.2.3' '+~amd64'
    update_keywords '=virtual/rubygems-12' '+~amd64'
    update_keywords '=dev-ruby/json-2.0.2' '+~amd64'
    update_keywords '=dev-ruby/net-telnet-0.1.1-r1' '+~amd64'
    update_keywords '=dev-ruby/did_you_mean-1.1.0' '+~amd64'
    update_keywords '=dev-ruby/xmlrpc-0.2.1' '+~amd64'
    update_keywords '=dev-ruby/kpeg-1.1.0' '+~amd64'
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    :
}
