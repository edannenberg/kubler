#
# build config
#
PACKAGES="dev-libs/gmp app-eselect/eselect-ruby dev-lang/ruby"

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    echo 'RUBY_TARGETS="ruby22"' >> /etc/portage/make.conf
    # 2.2.1 segfaults
    mask_package '>=dev-lang/ruby-2.2.1'
    # 2.2.0 is still wired to app-admin/eselect instead of new app-eselect/eselect-ruby
    echo 'app-admin/eselect-ruby-20141227' >> /etc/portage/profile/package.provided
    update_keywords 'dev-lang/ruby' '+~amd64'
    update_keywords '=app-eselect/eselect-ruby-20141227' '+~amd64'
    update_keywords '=dev-ruby/racc-1.4.12' '+~amd64'
    update_keywords '=dev-ruby/rdoc-4.1.2' '+~amd64'
    update_keywords '=dev-ruby/rubygems-2.4.5' '+~amd64'
    update_keywords '=dev-ruby/rake-10.4.2' '+~amd64'
    update_keywords '=dev-ruby/power_assert-0.2.2' '+~amd64'
    update_keywords '=dev-ruby/minitest-5.5.1' '+~amd64'
    update_keywords '=dev-ruby/test-unit-3.0.9-r1' '+~amd64'
    update_keywords '=virtual/rubygems-10' '+~amd64'
    update_keywords '=dev-ruby/json-1.8.2-r1' '+~amd64'
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    :
}
