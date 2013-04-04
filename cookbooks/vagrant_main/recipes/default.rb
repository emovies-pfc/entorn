include_recipe "apt"

apt_repository "php54" do
  uri "http://ppa.launchpad.net/ondrej/php5/ubuntu"
  distribution "precise"
  components ["main"]
  keyserver "keyserver.ubuntu.com"
  key "E5267A6C"
  action :add
  notifies :run, "execute[apt-get update]", :immediately
  deb_src true
end

include_recipe "apache2"
include_recipe "mysql"
include_recipe "mysql::server"
include_recipe "apache2::mod_php5"
include_recipe "git"
include_recipe "memcached"

package "curl" do
    action :install
end

package "php5-mysql" do
	action :install
end

package "php5-intl" do
	action :install
end

package "php-apc" do
	action :install
end

package "php5-memcached" do
  action :install
end

package "vim" do
	action :install
end

package "php5-curl" do
	action :install
end

package "php5-xdebug" do
	action :install
end

execute "download-composer" do
    command "curl -s https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer"
    not_if {File.exists?("/usr/local/bin/composer")}
end

execute "update-composer" do
    command "composer self-update"
end

execute "disable-default-site" do
  command "sudo a2dissite default"
  notifies :reload, resources(:service => "apache2"), :delayed
end

web_app "e-movies" do
  server_name "e-movies.local"
  server_aliases ["www.e-movies.local"]
  docroot "/vagrant/emovies-web/approot"
  cookbook "apache2"
  notifies :reload, resources(:service => "apache2"), :delayed
end

template "#{node['vagrant_main']['php']['apache_conf_dir']}/php.ini" do
  source "php.ini.erb"
  cookbook "php"
  owner "root"
  group "root"
  mode "0644"
  notifies :reload, resources(:service => "apache2"), :delayed
end

execute "create-database" do
  command "mysql -u root -p#{node[:mysql][:server_root_password]} -e \"CREATE DATABASE IF NOT EXISTS emovie\""
end
