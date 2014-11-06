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
    sed -i /^app-shells\\/bash/d /etc/portage/profile/package.provided
    echo 'RUBY_TARGETS="ruby19 ruby21"' >> /etc/portage/make.conf
    echo 'dev-lang/ruby ~amd64' >> /etc/portage/package.keywords/ruby
    echo '=dev-ruby/racc-1.4.12 ~amd64' >> /etc/portage/package.keywords/ruby
    echo '=virtual/rubygems-7 ~amd64' >> /etc/portage/package.keywords/ruby
    echo '=dev-ruby/rdoc-4.1.2 ~amd64' >> /etc/portage/package.keywords/ruby
    echo '=dev-ruby/rubygems-2.2.2 ~amd64' >> /etc/portage/package.keywords/ruby
    echo '=dev-ruby/json-1.8.1 ~amd64' >> /etc/portage/package.keywords/ruby
    echo '=dev-ruby/rake-10.3.2 ~amd64' >> /etc/portage/package.keywords/ruby
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    :
}
