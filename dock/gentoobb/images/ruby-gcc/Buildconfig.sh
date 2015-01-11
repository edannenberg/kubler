#
# build config
#
PACKAGES="dev-lang/ruby"
KEEP_HEADERS=true

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    echo 'RUBY_TARGETS="ruby22"' >> /etc/portage/make.conf
    echo 'dev-lang/ruby ~amd64' >> /etc/portage/package.keywords/ruby
    echo '=app-admin/eselect-ruby-20141227 ~amd64' >> /etc/portage/package.keywords/ruby
    echo '=dev-ruby/racc-1.4.12 ~amd64' >> /etc/portage/package.keywords/ruby
    echo '=virtual/rubygems-8 ~amd64' >> /etc/portage/package.keywords/ruby
    echo '=dev-ruby/rdoc-4.1.2 ~amd64' >> /etc/portage/package.keywords/ruby
    echo '=dev-ruby/rubygems-2.4.5 ~amd64' >> /etc/portage/package.keywords/ruby
    echo '=dev-ruby/json-1.8.2 ~amd64' >> /etc/portage/package.keywords/ruby
    echo '=dev-ruby/rake-10.4.2 ~amd64' >> /etc/portage/package.keywords/ruby
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    :
}
